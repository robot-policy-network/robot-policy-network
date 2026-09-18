// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title UnitreeG1Fleet
 * @notice Mint contract for the Unitree G1 Fleet.
 *         Each tokenId maps to a real Unitree G1 unit (4,444 total).
 *
 * Pricing (paid in the chain's NATIVE coin — on Arc this is USDC):
 *  - FIXED flat price per token: 5 USDC.
 *  - Arc native USDC uses 18 decimals for `msg.value` (the ERC-20 view uses 6),
 *    so the price constant below is expressed in 1e18 units.
 *  - `standardPrice()` returns the current price.
 *
 *  - Sealed box on mint; owner flips reveal + baseURI at T+24h.
 *  - No token/6551/DN404/synthesis here. That is Phase 2.
 */
contract UnitreeG1Fleet is ERC721, ERC2981, Ownable, ReentrancyGuard, EIP712 {
    using ECDSA for bytes32;

    // ─── Supply ────────────────────────────────────────────────────────────
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant MAX_PER_TX = 5;

    // ─── Pricing ────────────────────────────────────────────────────────────
    /// @notice Flat price per token, in native units (1e18 = 1 USDC on Arc).
    uint256 public constant TOKEN_PRICE = 5e18;

    // ─── Whitelist (Merkle) free mint ────────────────────────────────────────
    /// @notice Root of the Merkle tree of whitelisted addresses (300 addrs).
    bytes32 public merkleRoot;
    /// @notice Whether the free whitelist mint phase is open.
    bool public whitelistMintOpen;
    /// @notice Total tokens reserved for the whitelist free-mint phase.
    uint256 public constant WL_SUPPLY = 1000;
    /// @notice Max free tokens each whitelisted wallet may claim.
    uint256 public constant WL_MAX_PER_WALLET = 1;
    /// @notice Tokens minted so far in the whitelist phase.
    uint256 public wlMinted;
    /// @notice Free tokens already claimed by each whitelisted wallet.
    mapping(address => uint256) public wlClaimed;

    // ─── Proof-of-Intelligence Mint (PoI) ───────────────────────────────────
    /// @notice Backend signer that co-signs a Voucher after an operator passes
    ///         the AI evaluation. Only vouchers signed by this key are accepted.
    address public poiSigner;
    /// @notice Whether the Proof-of-Intelligence mint phase is open.
    bool public poiMintOpen;
    /// @notice Consumed voucher nonces (per-voucher, single-use). Prevents replay.
    mapping(uint256 => bool) public poiNonceUsed;
    /// @notice The AI evaluation score (0..100) recorded on-chain for each tokenId.
    ///         A fifth "operator intelligence" dimension, independent of visual DNA.
    mapping(uint256 => uint256) public intelligenceScore;
    /// @notice EIP-712 typehash for the mint voucher.
    /// @dev `free` gates the zero-payment race path: when the backend signs a
    ///      voucher with free=true (won a 10-minute race window), the mint costs
    ///      nothing on-chain. Paid vouchers keep free=false and pay as before.
    bytes32 private constant _POI_VOUCHER_TYPEHASH =
        keccak256("PoIVoucher(address to,uint256 quantity,uint256 score,bool free,uint256 nonce,uint256 deadline)");

    // ─── State ─────────────────────────────────────────────────────────────
    uint256 public totalMinted;
    bool public mintOpen;
    bool public revealed;
    string private _unrevealedURI; // sealed-box metadata (same for all)
    string private _baseTokenURI;  // set on reveal

    mapping(address => uint256) public mintedBy;

    // ─── Buyback / Burn-to-refund (Module 1 + 2) ─────────────────────────────
    /// @notice ETH actually paid to mint each tokenId (0 for free/WL/owner mints).
    ///         Burn refund is computed from this so free mints refund 0.
    mapping(uint256 => uint256) public mintPricePaid;
    /// @notice Refund basis points of the reverse-curve value returned on burn (7500 = 75%).
    uint256 public burnRefundBps = 7500;
    /// @notice Of the withheld remainder, share (bps of the FULL price) routed to the dividend pool.
    uint256 public burnToDividendBps = 500; // 5% to holders; remaining 20% to treasury
    /// @notice ETH reserved to pay burn refunds. Funded from mints + owner topUp.
    uint256 public buybackPool;
    /// @notice Basis points of each PAID mint routed into the buyback pool.
    uint256 public buybackFundingBps = 2000; // 20% of paid mints (80% to treasury)
    /// @notice Running total of tokens burned for a refund.
    uint256 public totalBurned;

    // ─── Dividend pool (Module 3) ────────────────────────────────────────────
    /// @notice Minimum tokens a wallet must hold to claim dividends.
    uint256 public dividendThreshold = 3;
    /// @notice Cumulative ETH-per-eligible-token, scaled by 1e18.
    uint256 public accDividendPerToken;
    /// @notice Undistributable dust carried to the next distribution.
    uint256 public dividendRemainder;
    /// @notice Snapshot of accDividendPerToken at each holder's last claim.
    mapping(address => uint256) public dividendDebtPerToken;
    /// @notice ETH currently held by the dividend pool (for accounting/withdraw guards).
    uint256 public dividendPool;

    // ─── Metadata freeze (Module 5) ──────────────────────────────────────────
    bool public metadataFrozen;

    // ─── Events ────────────────────────────────────────────────────────────
    event BurnedForRefund(address indexed holder, uint256 indexed tokenId, uint256 refund, uint256 toDividend, uint256 toTreasury);
    event BuybackFunded(address indexed from, uint256 amount, uint256 newPool);
    event DividendDistributed(uint256 amount, uint256 accPerToken);
    event DividendClaimed(address indexed holder, uint256 amount);
    event BuybackParamsChanged(uint256 refundBps, uint256 toDividendBps, uint256 fundingBps);
    event DividendThresholdChanged(uint256 threshold);
    event MetadataFrozen();
    event Minted(address indexed to, uint256 quantity, uint256 amountPaid, uint256 newTotal);
    event WhitelistMinted(address indexed to, uint256 quantity, uint256 newTotal);
    event MintStateChanged(bool open);
    event WhitelistMintStateChanged(bool open);
    event MerkleRootChanged(bytes32 root);
    event Revealed(string baseURI);
    event PoISignerChanged(address indexed signer);
    event PoIMintStateChanged(bool open);
    event ProofOfIntelligenceMinted(address indexed to, uint256 quantity, uint256 score, uint256 nonce, uint256 newTotal);

    constructor(
        string memory unrevealedURI_,
        address poiSigner_
    )
        ERC721("StonkRobotics", "G1")
        Ownable(msg.sender)
        // NOTE: this domain name is NOT the collection name and must stay in sync
        // with `web/server/_poi.js` signVoucher(). It is never shown to users — the
        // backend is the only signer — and changing it would invalidate every
        // signature the already-deployed backend produces.
        EIP712("UnitreeG1Fleet", "1")
    {
        _unrevealedURI = unrevealedURI_;
        poiSigner = poiSigner_;
        emit PoISignerChanged(poiSigner_);
        // EIP-2981: 7% default royalty to the deployer (owner) — owner-adjustable.
        _setDefaultRoyalty(msg.sender, 700);
    }

    // ─── Mint ──────────────────────────────────────────────────────────────

    /// @notice Standard mint. Pay `TOKEN_PRICE` per token.
    function mint(uint256 quantity) external payable {
        uint256 cost = quantity * TOKEN_PRICE;
        require(msg.value == cost, "wrong payment");
        _mintChecks(quantity);
        _doMint(msg.sender, quantity, cost);
    }

    // ─── Pricing ────────────────────────────────────────────────────────────

    /// @notice Per-token price. Flat, in native units (1e18 = 1 USDC on Arc).
    function standardPrice() public pure returns (uint256) {
        return TOKEN_PRICE;
    }

    /// @notice FREE whitelist mint. Caller must be in the Merkle tree. Each
    ///         whitelisted wallet may claim up to `WL_MAX_PER_WALLET` for free.
    ///         Capped by `WL_SUPPLY` and `MAX_SUPPLY`.
    /// @param quantity Number of tokens to claim (usually 1).
    /// @param proof    Merkle proof for `msg.sender`.
    function whitelistMint(uint256 quantity, bytes32[] calldata proof) external {
        require(whitelistMintOpen, "wl closed");
        require(quantity > 0, "bad quantity");
        require(wlClaimed[msg.sender] + quantity <= WL_MAX_PER_WALLET, "wl wallet cap");
        require(wlMinted + quantity <= WL_SUPPLY, "wl sold out");
        require(totalMinted + quantity <= MAX_SUPPLY, "sold out");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "not whitelisted");

        wlClaimed[msg.sender] += quantity;
        wlMinted += quantity;
        uint256 startId = totalMinted;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, startId + i + 1); // tokenIds start at 1
        }
        totalMinted += quantity;
        emit WhitelistMinted(msg.sender, quantity, totalMinted);
    }

    /// @notice Owner/team mint — FREE, bypasses the per-wallet cap, but is still
    ///         hard-capped by MAX_SUPPLY. Used for the team reserve, treasury and
    ///         giveaways. Mint in batches if `quantity` is large.
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(to != address(0), "zero addr");
        require(quantity > 0, "bad quantity");
        require(totalMinted + quantity <= MAX_SUPPLY, "exceeds supply");
        uint256 startId = totalMinted;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, startId + i + 1); // tokenIds start at 1
        }
        totalMinted += quantity;
        emit Minted(to, quantity, 0, totalMinted);
    }

    /// @notice Giveaway helper: mint ONE free token to each address in the list.
    ///         FREE, no whitelist, no per-wallet cap — capped only by MAX_SUPPLY.
    ///         Each `_safeMint` costs roughly 80k gas, so a whole list will not
    ///         fit in one block; call this in chunks (~100–200 addresses).
    ///         A revert in any single recipient (e.g. a contract without
    ///         onERC721Received) reverts the whole chunk — which is exactly why
    ///         small chunks are safer than one giant call.
    function ownerMintBatch(address[] calldata recipients) external onlyOwner {
        uint256 n = recipients.length;
        require(n > 0, "empty list");
        require(totalMinted + n <= MAX_SUPPLY, "exceeds supply");
        for (uint256 i = 0; i < n; i++) {
            require(recipients[i] != address(0), "zero addr");
            _safeMint(recipients[i], totalMinted + i + 1); // tokenIds start at 1
        }
        totalMinted += n;
        emit Minted(address(0), n, 0, totalMinted);
    }

    /// @notice Proof-of-Intelligence mint. The operator first passes an off-chain
    ///         AI evaluation (see /api/solve); the backend signer issues an
    ///         EIP-712 Voucher binding {to, quantity, score, free, nonce,
    ///         deadline}. This function verifies that signature, enforces
    ///         single-use nonce + deadline, then mints and records the AI score
    ///         on-chain per tokenId. Payment still applies unless `free`.
    ///
    ///         "Only those who can command a robot deserve to own one."
    /// @param quantity  Tokens to mint (must equal the voucher).
    /// @param score     AI evaluation score 0..100 (must equal the voucher).
    /// @param free      Whether this is a FREE (race-winner) voucher. When true,
    ///                  msg.value must be 0 and nothing is charged on-chain.
    /// @param nonce     Single-use voucher nonce.
    /// @param deadline  Unix time after which the voucher is invalid.
    /// @param sig       poiSigner's EIP-712 signature over the voucher.
    function mintWithProof(
        uint256 quantity,
        uint256 score,
        bool free,
        uint256 nonce,
        uint256 deadline,
        bytes calldata sig
    ) external payable {
        require(poiMintOpen, "poi closed");
        require(poiSigner != address(0), "no signer");
        require(block.timestamp <= deadline, "voucher expired");
        require(!poiNonceUsed[nonce], "voucher used");
        require(score <= 100, "bad score");

        // Free (race-winner) vouchers cost nothing; paid vouchers charge the
        // flat token price as usual.
        uint256 cost = free ? 0 : quantity * TOKEN_PRICE;
        require(msg.value == cost, "wrong payment");

        bytes32 structHash = keccak256(
            abi.encode(
                _POI_VOUCHER_TYPEHASH,
                msg.sender,
                quantity,
                score,
                free,
                nonce,
                deadline
            )
        );
        address recovered = _hashTypedDataV4(structHash).recover(sig);
        require(recovered == poiSigner, "bad voucher");

        // PoI has its own gate (poiMintOpen) — it does NOT require the regular
        // public-sale `mintOpen`. Enforce the remaining supply/tx/wallet caps.
        require(quantity > 0 && quantity <= MAX_PER_TX, "bad quantity");
        require(totalMinted + quantity <= MAX_SUPPLY, "sold out");
        require(mintedBy[msg.sender] + quantity <= MAX_PER_WALLET, "wallet cap");

        poiNonceUsed[nonce] = true;
        uint256 startId = totalMinted;
        _doMint(msg.sender, quantity, cost);
        // Record the AI score on-chain for the freshly minted ids.
        for (uint256 i = 0; i < quantity; i++) {
            intelligenceScore[startId + i + 1] = score;
        }
        emit ProofOfIntelligenceMinted(msg.sender, quantity, score, nonce, totalMinted);
    }

    function _mintChecks(uint256 quantity) internal view {
        require(mintOpen, "mint closed");
        require(quantity > 0 && quantity <= MAX_PER_TX, "bad quantity");
        require(totalMinted + quantity <= MAX_SUPPLY, "sold out");
        require(mintedBy[msg.sender] + quantity <= MAX_PER_WALLET, "wallet cap");
    }

    function _doMint(address to, uint256 quantity, uint256 amountPaid) internal {
        mintedBy[to] += quantity;
        uint256 startId = totalMinted;
        uint256 perToken = quantity > 0 ? amountPaid / quantity : 0;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 id = startId + i + 1; // tokenIds start at 1
            mintPricePaid[id] = perToken; // remember what was paid, for burn refunds
            _safeMint(to, id);
        }
        totalMinted += quantity;

        // Route a share of the paid amount into the buyback pool so burns are funded.
        if (amountPaid > 0 && buybackFundingBps > 0) {
            uint256 toPool = (amountPaid * buybackFundingBps) / 10000;
            if (toPool > 0) {
                buybackPool += toPool;
                emit BuybackFunded(to, toPool, buybackPool);
            }
        }
        emit Minted(to, quantity, amountPaid, totalMinted);
    }

    // ─── Burn-to-refund exit pool (Module 1 + 2) ─────────────────────────────

    /// @notice Burn one of your tokens back to the contract in exchange for an
    ///         ETH refund based on what was ORIGINALLY paid for that token.
    ///         Free / whitelist / owner mints paid 0, so they refund 0.
    ///         The withheld remainder is split: a share to the dividend pool for
    ///         remaining holders, the rest stays as treasury. TokenIds are never
    ///         reused and totalMinted never decreases — the 4,444 cap is preserved.
    function burnToRefund(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "not owner");

        uint256 paid = mintPricePaid[tokenId];
        uint256 refund = (paid * burnRefundBps) / 10000;
        uint256 toDividend = (paid * burnToDividendBps) / 10000;
        // Guard against rounding pushing refund+dividend above what was paid.
        if (refund + toDividend > paid) {
            toDividend = paid - refund;
        }
        require(refund <= buybackPool, "pool underfunded");

        // Effects
        mintPricePaid[tokenId] = 0;
        totalBurned += 1;
        if (refund > 0) buybackPool -= refund;
        if (toDividend > 0) _distributeDividend(toDividend);
        uint256 toTreasury = paid - refund - toDividend;

        _burn(tokenId);

        // Interactions
        if (refund > 0) {
            (bool ok, ) = payable(msg.sender).call{value: refund}("");
            require(ok, "refund failed");
        }
        emit BurnedForRefund(msg.sender, tokenId, refund, toDividend, toTreasury);
    }

    /// @notice Preview the refund a token would return if burned right now.
    function refundPreview(uint256 tokenId) external view returns (uint256) {
        return (mintPricePaid[tokenId] * burnRefundBps) / 10000;
    }

    /// @notice Owner tops up the buyback pool so burns stay funded.
    function fundBuyback() external payable onlyOwner {
        require(msg.value > 0, "no value");
        buybackPool += msg.value;
        emit BuybackFunded(msg.sender, msg.value, buybackPool);
    }

    // ─── Dividend pool (Module 3) ────────────────────────────────────────────

    /// @notice Number of tokens the eligible base holds (holders of >= threshold).
    ///         Simplified pro-rata: dividends accrue per circulating token; only
    ///         wallets holding >= dividendThreshold may claim their accrual.
    function _circulating() internal view returns (uint256) {
        return totalMinted - totalBurned;
    }

    /// @notice Push ETH into the dividend pool and update the per-token accumulator.
    function _distributeDividend(uint256 amount) internal {
        uint256 supply = _circulating();
        if (supply == 0) {
            dividendRemainder += amount;
            dividendPool += amount;
            return;
        }
        uint256 total = amount + dividendRemainder;
        uint256 perToken = (total * 1e18) / supply;
        accDividendPerToken += perToken;
        dividendRemainder = total - ((perToken * supply) / 1e18);
        dividendPool += amount;
        emit DividendDistributed(amount, accDividendPerToken);
    }

    /// @notice Owner injects ETH straight into the dividend pool (e.g. royalties, IPO day).
    function fundDividend() external payable onlyOwner {
        require(msg.value > 0, "no value");
        _distributeDividend(msg.value);
    }

    /// @notice Dividends currently claimable by `holder` (0 if below threshold).
    function claimable(address holder) public view returns (uint256) {
        uint256 bal = balanceOf(holder);
        if (bal < dividendThreshold) return 0;
        uint256 owedPerToken = accDividendPerToken - dividendDebtPerToken[holder];
        return (owedPerToken * bal) / 1e18;
    }

    /// @notice Claim accrued dividends. Must hold >= dividendThreshold tokens.
    function claimRewards() external nonReentrant {
        uint256 bal = balanceOf(msg.sender);
        require(bal >= dividendThreshold, "below threshold");
        uint256 owedPerToken = accDividendPerToken - dividendDebtPerToken[msg.sender];
        uint256 amount = (owedPerToken * bal) / 1e18;
        dividendDebtPerToken[msg.sender] = accDividendPerToken;
        require(amount > 0, "nothing to claim");
        require(amount <= dividendPool, "pool short");
        dividendPool -= amount;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "claim failed");
        emit DividendClaimed(msg.sender, amount);
    }

    // ─── Metadata ──────────────────────────────────────────────────────────

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        if (!revealed) return _unrevealedURI;
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId), ".json"));
    }

    // ─── Owner controls ────────────────────────────────────────────────────

    function setMintOpen(bool open) external onlyOwner {
        mintOpen = open;
        emit MintStateChanged(open);
    }

    /// @notice Set/replace the whitelist Merkle root.
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit MerkleRootChanged(root);
    }

    /// @notice Open/close the free whitelist mint phase.
    function setWhitelistMintOpen(bool open) external onlyOwner {
        whitelistMintOpen = open;
        emit WhitelistMintStateChanged(open);
    }

    /// @notice Set/replace the Proof-of-Intelligence backend signer.
    function setPoISigner(address signer) external onlyOwner {
        poiSigner = signer;
        emit PoISignerChanged(signer);
    }

    /// @notice Open/close the Proof-of-Intelligence mint phase.
    function setPoIMintOpen(bool open) external onlyOwner {
        poiMintOpen = open;
        emit PoIMintStateChanged(open);
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        _unrevealedURI = uri;
    }

    /// @notice Flip reveal on and set the base URI (T+24h).
    function reveal(string calldata baseURI) external onlyOwner {
        require(!metadataFrozen, "metadata frozen");
        _baseTokenURI = baseURI;
        revealed = true;
        emit Revealed(baseURI);
    }

    /// @notice Permanently lock metadata. After this, baseURI can never change.
    ///         One-way trust signal for KOL due-diligence (Module 5).
    function freezeMetadata() external onlyOwner {
        require(revealed, "reveal first");
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    /// @notice Tune buyback/burn economics (all in basis points).
    function setBuybackParams(uint256 refundBps, uint256 toDividendBps, uint256 fundingBps) external onlyOwner {
        require(refundBps + toDividendBps <= 10000, "over 100%");
        require(fundingBps <= 10000, "bad funding");
        burnRefundBps = refundBps;
        burnToDividendBps = toDividendBps;
        buybackFundingBps = fundingBps;
        emit BuybackParamsChanged(refundBps, toDividendBps, fundingBps);
    }

    /// @notice Set the minimum tokens a wallet must hold to claim dividends.
    function setDividendThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "bad threshold");
        dividendThreshold = threshold;
        emit DividendThresholdChanged(threshold);
    }

    /// @notice Set EIP-2981 default royalty (Module 4). feeNumerator in bps (e.g. 700 = 7%).
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Withdraw ONLY free treasury funds. The buyback and dividend pools
    ///         are protected so owner can never drain funds owed to holders.
    function withdraw(address payable to) external onlyOwner {
        require(to != address(0), "zero addr");
        uint256 reserved = buybackPool + dividendPool;
        uint256 bal = address(this).balance;
        require(bal > reserved, "no free funds");
        uint256 free = bal - reserved;
        (bool ok, ) = to.call{value: free}("");
        require(ok, "withdraw failed");
    }

    // ─── EIP-165 ─────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ─── Utils ─────────────────────────────────────────────────────────────

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
