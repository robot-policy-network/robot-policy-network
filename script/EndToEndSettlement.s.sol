// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {EvaluationEscrow} from "../contracts/EvaluationEscrow.sol";
import {DemoUSDC} from "../contracts/DemoUSDC.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title EndToEndSettlement
 * @notice Executes a complete, real settlement: deploy → fund a job →
 *         evaluator attestation → verifyResult → payer release → release, then
 *         asserts the provider's USDC balance rose and the job ended RELEASED.
 *
 *         This is the executable form of the grant's M1/M2 claim. Run it on
 *         anvil as a CI proof, or against a real Arc testnet deployment to
 *         produce public transaction hashes.
 *
 * ENV
 *   EVALUATOR_PK   required — signs the EvaluationAttestation (evidence)
 *   PAYER_PK       required — funds the job and signs the release (authority);
 *                  MUST differ from EVALUATOR_PK (spec §1)
 *   USDC_ADDRESS   optional — otherwise a DemoUSDC demo asset is deployed
 *   AMOUNT_USDC    optional — default 500000 (0.5 USDC, 6 decimals)
 *
 * USAGE
 *   anvil &
 *   EVALUATOR_PK=0x… PAYER_PK=0x… forge script script/EndToEndSettlement.s.sol \
 *     --rpc-url http://127.0.0.1:8545 --broadcast
 *
 * Use throwaway keys funded only with testnet gas. Never a treasury key.
 */
contract EndToEndSettlement is Script {
    bytes32 internal constant _ATTESTATION_TYPEHASH = keccak256(
        "EvaluationAttestation(uint256 jobId," "bytes32 taskHash," "bytes32 planHash," "bytes32 resultHash,"
        "uint256 score," "uint8 status," "uint256 deadline)"
    );
    bytes32 internal constant _RELEASE_TYPEHASH =
        keccak256("ReleaseAuthorization(uint256 jobId,address provider,uint256 amount,bytes32 resultHash)");

    uint8 internal constant _STATUS_PASSED = 1;
    uint256 internal constant _SCORE = 87;
    string internal constant _REASON_PASSED = "passed";
    uint256 internal constant _AMOUNT_DEFAULT = 500_000; // 0.5 USDC

    function run() external {
        uint256 evaluatorPk = vm.envUint("EVALUATOR_PK");
        uint256 payerPk = vm.envUint("PAYER_PK");
        uint256 amount = vm.envOr("AMOUNT_USDC", _AMOUNT_DEFAULT);
        address evaluator = vm.addr(evaluatorPk);

        require(evaluator != vm.addr(payerPk), "E2E: evaluator and payer must differ (spec 1)");

        address usdc = _resolveUsdc(payerPk);

        vm.startBroadcast(payerPk);
        EvaluationEscrow escrow = new EvaluationEscrow(usdc, evaluator);
        vm.stopBroadcast();

        console2.log("=== End-to-end settlement proof ===");
        console2.log("chain id:", block.chainid);
        console2.log("evaluator:", evaluator);
        console2.log("payer:", vm.addr(payerPk));
        console2.log("usdc:", usdc);
        console2.log("escrow:", address(escrow));
        console2.log("SPEC_VERSION:", escrow.SPEC_VERSION());
        console2.log("amount:", amount);

        _fund(escrow, usdc, evaluator, payerPk, amount);
        _verifyAndRelease(escrow, usdc, evaluator, payerPk, amount);
    }

    // ─── steps (small frames on purpose: the EVM stack is 16 slots) ─────────

    /// @dev Step 1: payer approves and escrows into a new job.
    function _fund(EvaluationEscrow escrow, address usdc, address evaluator, uint256 payerPk, uint256 amount) internal {
        vm.startBroadcast(payerPk);
        (bool ok,) = usdc.call(abi.encodeWithSignature("approve(address,uint256)", address(escrow), amount));
        require(ok, "E2E: approve failed");
        uint256 jobId = escrow.createJob(evaluator, amount, _taskHash(), 60, uint64(_deadline()));
        vm.stopBroadcast();
        console2.log("jobId:", jobId);
    }

    /// @dev Steps 2-4: evaluator attests, payer authorizes, USDC moves.
    function _verifyAndRelease(
        EvaluationEscrow escrow,
        address usdc,
        address evaluator,
        uint256 payerPk,
        uint256 amount
    ) internal {
        uint256 jobId = escrow.nextJobId() - 1;
        uint256 sigDeadline = _deadline();

        // evidence: the evaluator signs; this alone cannot move funds
        escrow.verifyResult(
            jobId,
            _taskHash(),
            _planHash(),
            _resultHash(),
            _SCORE,
            _STATUS_PASSED,
            sigDeadline,
            _attestation(escrow, jobId, sigDeadline)
        );
        require(escrow.getJob(jobId).state == 2, "E2E: not RESULT_VERIFIED");

        uint256 before = _balanceOf(usdc, evaluator);

        // authority: the payer signs; verification alone was not enough
        escrow.release(jobId, evaluator, amount, _resultHash(), _release(escrow, jobId, evaluator, amount));

        require(escrow.getJob(jobId).state == 3, "E2E: not RELEASED");
        uint256 paid = _balanceOf(usdc, evaluator) - before;
        require(paid == amount, "E2E: provider not paid exactly");
        console2.log("provider USDC received:", paid);
        console2.log("PASS: funded, verified and released end to end.");
    }

    // ─── deterministic artifacts (recomputed, never stored, to save stack) ──

    function _taskHash() internal pure returns (bytes32) {
        return keccak256("task: end-to-end settlement proof");
    }

    function _planHash() internal pure returns (bytes32) {
        return keccak256("plan: navigate t01, cut t01, transport bin");
    }

    function _resultHash() internal pure returns (bytes32) {
        return keccak256(abi.encode(_planHash(), _SCORE, _REASON_PASSED, _taskHash()));
    }

    function _deadline() internal view returns (uint256) {
        return block.timestamp + 7 days;
    }

    // ─── EIP-712 signing (domain must match the contract: EvaluationEscrow/1) ─

    function _domainSeparator(address verifying) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("EvaluationEscrow"),
                keccak256("1"),
                block.chainid,
                verifying
            )
        );
    }

    function _attestation(EvaluationEscrow escrow, uint256 jobId, uint256 sigDeadline)
        internal
        view
        returns (bytes memory)
    {
        uint256 evaluatorPk = vm.envUint("EVALUATOR_PK");
        bytes32 structHash = keccak256(
            abi.encode(
                _ATTESTATION_TYPEHASH,
                jobId,
                _taskHash(),
                _planHash(),
                _resultHash(),
                _SCORE,
                _STATUS_PASSED,
                sigDeadline
            )
        );
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(evaluatorPk, MessageHashUtils.toTypedDataHash(_domainSeparator(address(escrow)), structHash));
        return abi.encodePacked(r, s, v);
    }

    function _release(EvaluationEscrow escrow, uint256 jobId, address provider, uint256 amount)
        internal
        view
        returns (bytes memory)
    {
        uint256 payerPk = vm.envUint("PAYER_PK");
        bytes32 structHash = keccak256(abi.encode(_RELEASE_TYPEHASH, jobId, provider, amount, _resultHash()));
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(payerPk, MessageHashUtils.toTypedDataHash(_domainSeparator(address(escrow)), structHash));
        return abi.encodePacked(r, s, v);
    }

    function _balanceOf(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        require(ok, "E2E: balanceOf failed");
        return abi.decode(data, (uint256));
    }

    // ─── asset ──────────────────────────────────────────────────────────────

    /// @dev Demo asset only when USDC_ADDRESS is unset, so the flow is
    ///      self-contained on a fresh chain.
    function _resolveUsdc(uint256 payerPk) internal returns (address) {
        address fromEnv = vm.envOr("USDC_ADDRESS", address(0));
        if (fromEnv != address(0)) return fromEnv;
        vm.startBroadcast(payerPk);
        address mock = address(new DemoUSDC());
        DemoUSDC(mock).mint(vm.addr(payerPk), 10_000_000); // 10 USDC
        vm.stopBroadcast();
        return mock;
    }
}
