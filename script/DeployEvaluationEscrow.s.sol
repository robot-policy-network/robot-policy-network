// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {EvaluationEscrow} from "../contracts/EvaluationEscrow.sol";

/**
 * @title DeployEvaluationEscrow
 * @notice Deploys `EvaluationEscrow` with exactly the constructor arguments the
 *         frozen v1 spec expects, after refusing obviously unsafe inputs.
 *
 * The script is deliberately conservative: it never invents an address, never
 * defaults an evaluator, and refuses to deploy if the evaluator key equals the
 * deployer key. See docs/settlement-spec.md §1 — the evaluator signs evidence,
 * the owner controls configuration, and the payer authorizes release. These are
 * three different keys and the deployment should not blur them.
 *
 * ── ENV ──────────────────────────────────────────────────────────────────────
 *   DEPLOYER_PRIVATE_KEY   required (forge's standard key var). Becomes `owner()`.
 *   EVALUATOR_ADDRESS      required. Becomes the default evaluator for new jobs.
 *   USDC_ADDRESS           optional. Defaults to Arc native USDC's ERC-20
 *                          interface ONLY on chain id 5042; required elsewhere.
 *   ALLOW_SAME_OWNER_AND_EVALUATOR
 *                          optional escape hatch ("1") for local dry runs.
 *   ALLOW_USDC_WITHOUT_CODE
 *                          optional escape hatch ("1") for local anvil smoke
 *                          tests, where no token exists at the given address.
 *
 * ── USAGE ────────────────────────────────────────────────────────────────────
 *   # dry run against Arc mainnet RPC (simulates, does not broadcast)
 *   EVALUATOR_ADDRESS=0x... forge script script/DeployEvaluationEscrow.s.sol --rpc-url arc
 *
 *   # broadcast
 *   EVALUATOR_ADDRESS=0x... forge script script/DeployEvaluationEscrow.s.sol \
 *       --rpc-url arc --broadcast
 *
 *   # local smoke test (anvil), which is how CI should exercise this script
 *   anvil &
 *   EVALUATOR_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
 *   USDC_ADDRESS=0x3600000000000000000000000000000000000000 \
 *   ALLOW_SAME_OWNER_AND_EVALUATOR=0 \
 *   forge script script/DeployEvaluationEscrow.s.sol \
 *       --rpc-url http://127.0.0.1:8545 --broadcast \
 *       --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 *
 * ── WHAT THIS SCRIPT DOES NOT DO ─────────────────────────────────────────────
 *   It does not deploy to mainnet by itself, does not hold secrets, and does not
 *   verify source on the explorer. It writes the deployment manifest to stdout
 *   for a human to commit; automation of mainnet deployment is intentionally out
 *   of scope (see README security notes).
 * ----------------------------------------------------------------------------
 */
contract DeployEvaluationEscrow is Script {
    /// @dev Arc native USDC exposed through the ERC-20 interface (6 decimals).
    ///      Source: deployments/arc-mainnet.json, verified by read-only RPC.
    address internal constant ARC_MAINNET_USDC_ERC20 = 0x3600000000000000000000000000000000000000;
    uint256 internal constant ARC_MAINNET_CHAIN_ID = 5042;

    function run() external returns (EvaluationEscrow escrow) {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address evaluator = vm.envAddress("EVALUATOR_ADDRESS");

        require(evaluator != address(0), "Deploy: zero evaluator");
        require(evaluator.code.length == 0, "Deploy: evaluator must be an EOA hot key");

        bool allowSame = vm.envOr("ALLOW_SAME_OWNER_AND_EVALUATOR", uint256(0)) == 1;
        require(allowSame || evaluator != deployer, "Deploy: evaluator must differ from owner");

        address usdc = _resolveUsdc();

        console2.log("=== EvaluationEscrow deployment ===");
        console2.log("chain id          :", block.chainid);
        console2.log("deployer / owner  :", deployer);
        console2.log("evaluator (hot)   :", evaluator);
        console2.log("usdc (ERC-20, 6dp):", usdc);
        console2.log("EIP-712 domain    : EvaluationEscrow / 1");

        if (block.chainid != ARC_MAINNET_CHAIN_ID) {
            console2.log("WARNING: not Arc mainnet (5042). Confirm this is the intended network.");
        }

        vm.startBroadcast(deployerKey);
        escrow = new EvaluationEscrow(usdc, evaluator);
        vm.stopBroadcast();

        console2.log("");
        console2.log("deployed at       :", address(escrow));
        console2.log("SPEC_VERSION      :", escrow.SPEC_VERSION());
        console2.log("owner()           :", escrow.owner());
        console2.log("evaluator()       :", escrow.evaluator());
        console2.log("usdc()            :", address(escrow.usdc()));
        console2.log("nextJobId()       :", escrow.nextJobId());
        console2.log("");
        console2.log("Record this address in deployments/<network>.json and set the");
        console2.log("off-chain signer EIP-712 domain to name=EvaluationEscrow version=1");
        console2.log("with verifyingContract = the address above. Both halves of the");
        console2.log("protocol MUST use the same domain or every signature will fail.");
    }

    /// @dev Never guesses an address. On Arc mainnet the verified native-USDC
    ///      ERC-20 interface is used as a default; every other chain must be
    ///      supplied explicitly so the caller cannot accidentally settle in the
    ///      wrong asset. The code-existence check is skipped only when
    ///      ALLOW_USDC_WITHOUT_CODE=1, which exists for local anvil smoke tests
    ///      where no token has been deployed yet.
    function _resolveUsdc() internal view returns (address) {
        bool allowNoCode = vm.envOr("ALLOW_USDC_WITHOUT_CODE", uint256(0)) == 1;
        address fromEnv = vm.envOr("USDC_ADDRESS", address(0));
        if (fromEnv != address(0)) {
            if (!allowNoCode) {
                require(fromEnv.code.length > 0, "Deploy: USDC_ADDRESS has no code");
            }
            return fromEnv;
        }
        require(block.chainid == ARC_MAINNET_CHAIN_ID, "Deploy: set USDC_ADDRESS for this chain");
        return ARC_MAINNET_USDC_ERC20;
    }
}
