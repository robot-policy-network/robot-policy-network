// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EvaluationEscrow} from "../contracts/EvaluationEscrow.sol";

/// @dev 6-decimal USDC stand-in. The escrow only ever calls balanceOf /
///      transferFrom / transfer, so this is a faithful test double for the
///      Arc ERC-20 interface at 0x3600...0000.
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Malicious ERC-20: re-enters the escrow on transfer in an attempt to
///      double-spend a job. The escrow's nonReentrant guard must reject it.
contract ReentrantUSDC is ERC20 {
    EvaluationEscrow public escrow;
    uint256 public jobId;
    address public provider;
    uint256 public amount;
    bytes public sig;
    bool public armed;
    bool public revertOnReentry;

    constructor() ERC20("Reentrant", "RE") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount_) external {
        _mint(to, amount_);
    }

    function setRevertOnReentry(bool v) external {
        revertOnReentry = v;
    }

    function arm(uint256 jobId_, address provider_, uint256 amount_, bytes calldata sig_) external {
        jobId = jobId_;
        provider = provider_;
        amount = amount_;
        sig = sig_;
        armed = true;
    }

    function setEscrow(EvaluationEscrow escrow_) external {
        escrow = escrow_;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (armed) {
            armed = false;
            try escrow.release(jobId, provider, amount, bytes32(0), sig) {
                revert("REENTRY_SUCCEEDED");
            } catch {
                if (revertOnReentry) revert("REENTRY_BLOCKED");
            }
        }
        return super.transfer(to, value);
    }
}

contract EvaluationEscrowTest is Test {
    // ─── Actors ─────────────────────────────────────────────────────────────
    uint256 internal payerKey = 0xA11CE;
    uint256 internal evaluatorKey = 0xE7A1;
    uint256 internal providerKey = 0xB0B;
    uint256 internal strangerKey = 0xDEAD;

    address internal payer;
    address internal evaluator;
    address internal provider;
    address internal stranger;

    MockUSDC internal usdc;
    EvaluationEscrow internal escrow;

    // ─── Fixtures ───────────────────────────────────────────────────────────
    uint256 internal constant AMOUNT = 25e6; // 25.00 USDC
    uint16 internal constant PASS_SCORE = 70;
    uint64 internal deadline;

    bytes32 internal constant TASK_HASH = keccak256("task:grasp-stem-001");
    bytes32 internal constant PLAN_HASH = keccak256("plan:{\"ops\":[]}");
    bytes32 internal constant RESULT_HASH = keccak256("result:{...}");

    bytes32 internal constant ATTESTATION_TYPEHASH = keccak256(
        "EvaluationAttestation(uint256 jobId,bytes32 taskHash,bytes32 planHash,"
        "bytes32 resultHash,uint256 score,uint8 status,uint256 deadline)"
    );
    bytes32 internal constant RELEASE_TYPEHASH =
        keccak256("ReleaseAuthorization(uint256 jobId,address provider,uint256 amount,bytes32 resultHash)");

    event JobCreated(
        uint256 indexed jobId,
        address indexed payer,
        address indexed provider,
        address evaluator,
        uint256 amount,
        bytes32 taskHash,
        uint16 passScore,
        uint64 deadline
    );
    event ResultVerified(uint256 indexed jobId, bytes32 planHash, bytes32 resultHash, uint256 score, uint8 status);
    event JobReleased(uint256 indexed jobId, address indexed provider, uint256 amount, bytes32 resultHash);
    event JobRefunded(uint256 indexed jobId, address indexed payer, uint256 amount);
    event JobCancelled(uint256 indexed jobId, address indexed payer, uint256 amount);
    event EvaluatorChanged(address indexed previous, address indexed current);

    function setUp() public {
        payer = vm.addr(payerKey);
        evaluator = vm.addr(evaluatorKey);
        provider = vm.addr(providerKey);
        stranger = vm.addr(strangerKey);

        vm.warp(1_700_000_000);
        deadline = uint64(block.timestamp + 7 days);

        usdc = new MockUSDC();
        escrow = new EvaluationEscrow(address(usdc), evaluator);

        usdc.mint(payer, 1_000e6);
        vm.prank(payer);
        usdc.approve(address(escrow), type(uint256).max);
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    function _domainSeparator() internal view returns (bytes32) {
        // Reconstructed independently of the contract, so a change to the
        // contract's domain is caught here rather than silently agreed with.
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("EvaluationEscrow"),
                keccak256("1"),
                block.chainid,
                address(escrow)
            )
        );
    }

    function _sign(uint256 key, bytes32 structHash) internal view returns (bytes memory) {
        bytes32 digest = MessageHashUtils.toTypedDataHash(_domainSeparator(), structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }

    function _attestationSig(
        uint256 jobId,
        bytes32 taskHash,
        bytes32 planHash,
        bytes32 resultHash,
        uint256 score,
        uint8 status,
        uint256 sigDeadline
    ) internal view returns (bytes memory) {
        return _sign(
            evaluatorKey,
            keccak256(
                abi.encode(ATTESTATION_TYPEHASH, jobId, taskHash, planHash, resultHash, score, status, sigDeadline)
            )
        );
    }

    function _releaseSig(uint256 jobId, address provider_, uint256 amount, bytes32 resultHash)
        internal
        view
        returns (bytes memory)
    {
        return _sign(payerKey, keccak256(abi.encode(RELEASE_TYPEHASH, jobId, provider_, amount, resultHash)));
    }

    function _createJob() internal returns (uint256 jobId) {
        vm.prank(payer);
        jobId = escrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);
    }

    function _verifyPassing(uint256 jobId) internal {
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    // ═══ createJob ═══════════════════════════════════════════════════════════

    function test_CreateJob_FundsAndRecords() public {
        uint256 jobId = _createJob();

        assertEq(jobId, 1, "first job id");
        assertEq(usdc.balanceOf(address(escrow)), AMOUNT, "escrow holds the funds");
        assertEq(usdc.balanceOf(payer), 1_000e6 - AMOUNT, "payer debited");

        EvaluationEscrow.Job memory job = escrow.getJob(jobId);
        assertEq(job.payer, payer);
        assertEq(job.provider, provider);
        assertEq(job.evaluator, evaluator, "evaluator captured at creation");
        assertEq(job.passScore, PASS_SCORE);
        assertEq(job.state, 1, "FUNDED");
        assertEq(job.deadline, deadline);
        assertEq(job.amount, AMOUNT);
        assertEq(job.taskHash, TASK_HASH);
        assertEq(job.planHash, bytes32(0), "plan not committed at creation");
        assertEq(job.resultHash, bytes32(0));
        assertEq(job.score, 0);
    }

    function test_CreateJob_EmitsEvent() public {
        vm.expectEmit(true, true, true, true, address(escrow));
        emit JobCreated(1, payer, provider, evaluator, AMOUNT, TASK_HASH, PASS_SCORE, deadline);
        _createJob();
    }

    function test_CreateJob_IdsAreSequential() public {
        uint256 a = _createJob();
        uint256 b = _createJob();
        assertEq(a, 1);
        assertEq(b, 2);
        assertEq(escrow.nextJobId(), 3);
    }

    function test_CreateJob_RevertsOnZeroProvider() public {
        vm.prank(payer);
        vm.expectRevert("ZeroProvider");
        escrow.createJob(address(0), AMOUNT, TASK_HASH, PASS_SCORE, deadline);
    }

    function test_CreateJob_RevertsOnZeroAmount() public {
        vm.prank(payer);
        vm.expectRevert("ZeroAmount");
        escrow.createJob(provider, 0, TASK_HASH, PASS_SCORE, deadline);
    }

    function test_CreateJob_RevertsOnZeroTaskHash() public {
        vm.prank(payer);
        vm.expectRevert("ZeroTaskHash");
        escrow.createJob(provider, AMOUNT, bytes32(0), PASS_SCORE, deadline);
    }

    function test_CreateJob_RevertsOnPastDeadline() public {
        vm.prank(payer);
        vm.expectRevert("DeadlineInPast");
        escrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, uint64(block.timestamp));
    }

    function test_CreateJob_RevertsOnPassScoreAbove100() public {
        vm.prank(payer);
        vm.expectRevert("BadPassScore");
        escrow.createJob(provider, AMOUNT, TASK_HASH, 101, deadline);
    }

    function test_CreateJob_AcceptsBoundaryPassScores() public {
        vm.startPrank(payer);
        uint256 zero = escrow.createJob(provider, AMOUNT, TASK_HASH, 0, deadline);
        uint256 hundred = escrow.createJob(provider, AMOUNT, TASK_HASH, 100, deadline);
        vm.stopPrank();
        assertEq(escrow.getJob(zero).passScore, 0);
        assertEq(escrow.getJob(hundred).passScore, 100);
    }

    function test_CreateJob_RevertsWhenPaused() public {
        escrow.pause();
        vm.prank(payer);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        escrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);
    }

    function test_CreateJob_RequiresAllowance() public {
        usdc.mint(stranger, AMOUNT);
        vm.prank(stranger);
        vm.expectRevert();
        escrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);
    }

    // ═══ verifyResult ════════════════════════════════════════════════════════

    function test_VerifyResult_RecordsAndMovesState() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);

        vm.expectEmit(true, false, false, true, address(escrow));
        emit ResultVerified(jobId, PLAN_HASH, RESULT_HASH, 87, 1);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);

        EvaluationEscrow.Job memory job = escrow.getJob(jobId);
        assertEq(job.state, 2, "RESULT_VERIFIED");
        assertEq(job.planHash, PLAN_HASH, "plan recorded here, not at creation");
        assertEq(job.resultHash, RESULT_HASH);
        assertEq(job.score, 87);
    }

    function test_VerifyResult_IsPermissionless() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 90, 1, deadline);

        vm.prank(stranger);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 90, 1, deadline, sig);
        assertEq(escrow.getJob(jobId).state, 2);
    }

    function test_VerifyResult_AcceptsFailedStatus() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline);

        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline, sig);
        assertEq(escrow.getJob(jobId).score, 42);
        assertEq(escrow.getJob(jobId).state, 2, "a failed result is still a verified result");
    }

    function test_VerifyResult_RevertsOnUnknownJob() public {
        bytes memory sig = _attestationSig(999, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("UnknownJob");
        escrow.verifyResult(999, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsWhenAlreadyVerified() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("WrongState");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnExpiredAttestation() public {
        uint256 jobId = _createJob();
        uint256 sigDeadline = block.timestamp - 1;
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, sigDeadline);
        vm.expectRevert("AttestationExpired");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, sigDeadline, sig);
    }

    /// @dev An attestation whose `sigDeadline` outlives the job is still refused
    ///      once the job deadline passes: the job deadline is the outer bound.
    function test_VerifyResult_RevertsAfterJobDeadline() public {
        uint256 jobId = _createJob();
        uint256 sigDeadline = uint256(deadline) + 1 hours;
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, sigDeadline);
        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("JobExpired");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, sigDeadline, sig);
    }

    /// @dev When both deadlines have passed, the attestation's own expiry is the
    ///      one reported — it is the tighter of the two bounds.
    function test_VerifyResult_RevertsWithAttestationExpiredWhenBothLapsed() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("AttestationExpired");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    /// @dev Boundary: the attestation is still usable at exactly `sigDeadline`
    ///      and exactly `job.deadline`; both checks are `>`, not `>=`.
    function test_VerifyResult_AcceptsAtExactDeadlines() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.warp(deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
        assertEq(escrow.getJob(jobId).state, 2);
    }

    function test_VerifyResult_RevertsOnTaskMismatch() public {
        uint256 jobId = _createJob();
        bytes32 otherTask = keccak256("other-task");
        bytes memory sig = _attestationSig(jobId, otherTask, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("TaskMismatch");
        escrow.verifyResult(jobId, otherTask, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnZeroPlanHash() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, bytes32(0), RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("ZeroPlanHash");
        escrow.verifyResult(jobId, TASK_HASH, bytes32(0), RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnZeroResultHash() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, bytes32(0), 87, 1, deadline);
        vm.expectRevert("ZeroResultHash");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, bytes32(0), 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnScoreAbove100() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 101, 1, deadline);
        vm.expectRevert("BadScore");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 101, 1, deadline, sig);
    }

    function test_VerifyResult_AcceptsBoundaryScores() public {
        uint256 a = _createJob();
        bytes memory sigA = _attestationSig(a, TASK_HASH, PLAN_HASH, RESULT_HASH, 0, 2, deadline);
        escrow.verifyResult(a, TASK_HASH, PLAN_HASH, RESULT_HASH, 0, 2, deadline, sigA);

        uint256 b = _createJob();
        bytes memory sigB = _attestationSig(b, TASK_HASH, PLAN_HASH, RESULT_HASH, 100, 1, deadline);
        escrow.verifyResult(b, TASK_HASH, PLAN_HASH, RESULT_HASH, 100, 1, deadline, sigB);

        assertEq(escrow.getJob(a).score, 0);
        assertEq(escrow.getJob(b).score, 100);
    }

    function test_VerifyResult_RevertsOnZeroStatus() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 0, deadline);
        vm.expectRevert("BadStatus");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 0, deadline, sig);
    }

    function test_VerifyResult_RevertsOnUnknownStatus() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 3, deadline);
        vm.expectRevert("BadStatus");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 3, deadline, sig);
    }

    function test_VerifyResult_RevertsOnNonEvaluatorSignature() public {
        uint256 jobId = _createJob();
        bytes32 structHash =
            keccak256(abi.encode(ATTESTATION_TYPEHASH, jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline));
        bytes memory sig = _sign(strangerKey, structHash);
        vm.expectRevert("BadAttestation");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnTamperedScore() public {
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        // Same signature, different score: the signed struct no longer matches.
        vm.expectRevert("BadAttestation");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 99, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnSignatureForAnotherJob() public {
        _createJob();
        uint256 jobB = _createJob();
        // Signed against job 1, submitted against job 2.
        bytes memory sig = _attestationSig(1, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("BadAttestation");
        escrow.verifyResult(jobB, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, sig);
    }

    function test_VerifyResult_RevertsOnEmptySignature() public {
        uint256 jobId = _createJob();
        vm.expectRevert();
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, "");
    }

    /// @dev The mint flow's EIP-712 domain is different, so a signature that is
    ///      valid for UnitreeG1Fleet must not be accepted here.
    function test_VerifyResult_RejectsSignatureFromAnotherDomain() public {
        uint256 jobId = _createJob();
        bytes32 structHash =
            keccak256(abi.encode(ATTESTATION_TYPEHASH, jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline));
        bytes32 foreignDomain = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("UnitreeG1Fleet"),
                keccak256("1"),
                block.chainid,
                address(escrow)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(evaluatorKey, MessageHashUtils.toTypedDataHash(foreignDomain, structHash));
        vm.expectRevert("BadAttestation");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, abi.encodePacked(r, s, v));
    }

    function test_VerifyResult_DoesNotMoveFunds() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        assertEq(usdc.balanceOf(address(escrow)), AMOUNT, "evidence is not payment");
        assertEq(usdc.balanceOf(provider), 0);
    }

    // ═══ release ═════════════════════════════════════════════════════════════

    function test_Release_PaysProvider() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);

        vm.expectEmit(true, true, false, true, address(escrow));
        emit JobReleased(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);

        assertEq(usdc.balanceOf(provider), AMOUNT);
        assertEq(usdc.balanceOf(address(escrow)), 0);
        assertEq(escrow.getJob(jobId).state, 3, "RELEASED");
    }

    function test_Release_IsPermissionless() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);

        vm.prank(stranger);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(usdc.balanceOf(provider), AMOUNT);
    }

    function test_Release_RevertsOnUnknownJob() public {
        bytes memory sig = _releaseSig(999, provider, AMOUNT, RESULT_HASH);
        vm.expectRevert("UnknownJob");
        escrow.release(999, provider, AMOUNT, RESULT_HASH, sig);
    }

    function test_Release_RevertsWhileOnlyFunded() public {
        uint256 jobId = _createJob();
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        vm.expectRevert("WrongState");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnFailedResult() public {
        uint256 jobId = _createJob();
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline, attestation);

        // The payer is willing to pay; the protocol still refuses, because a
        // failed result is not a payment instruction.
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        vm.expectRevert("ResultNotPassed");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnScoreBelowPassScore() public {
        uint256 jobId = _createJob();
        uint256 below = PASS_SCORE - 1;
        // v2: status must be consistent with the score (§4.2), so a
        // below-threshold result is attested as `failed`, not as `passed`.
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 2, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 2, deadline, attestation);

        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        vm.expectRevert("ResultNotPassed");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    /// @dev v2: the v1 contract accepted a `passed` attestation with a
    ///      below-threshold score, leaving the inconsistency to be resolved at
    ///      release time. verifyResult now rejects it outright.
    function test_VerifyResult_RevertsOnPassedStatusWithFailingScore() public {
        uint256 jobId = _createJob();
        uint256 below = PASS_SCORE - 1;
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 1, deadline);
        vm.expectRevert("StatusMismatch");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 1, deadline, attestation);
    }

    /// @dev v2: the inverse inconsistency — a `failed` attestation carrying a
    ///      passing score would previously have been releasable on the score
    ///      alone, which is exactly the hole an external review identified.
    function test_VerifyResult_RevertsOnFailedStatusWithPassingScore() public {
        uint256 jobId = _createJob();
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 95, 2, deadline);
        vm.expectRevert("StatusMismatch");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 95, 2, deadline, attestation);
    }

    /// @dev v2: consistency holds at the boundary too.
    function test_VerifyResult_AcceptsFailedStatusExactlyBelowPassScore() public {
        uint256 jobId = _createJob();
        uint256 below = PASS_SCORE - 1;
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 2, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, below, 2, deadline, attestation);
        assertEq(escrow.getJob(jobId).score, below);
    }

    function test_Release_AcceptsScoreExactlyAtPassScore() public {
        uint256 jobId = _createJob();
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, PASS_SCORE, 1, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, PASS_SCORE, 1, deadline, attestation);

        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(usdc.balanceOf(provider), AMOUNT);
    }

    function test_Release_RevertsOnProviderMismatch() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, stranger, AMOUNT, RESULT_HASH);
        vm.expectRevert("ProviderMismatch");
        escrow.release(jobId, stranger, AMOUNT, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnAmountMismatch() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT + 1, RESULT_HASH);
        vm.expectRevert("AmountMismatch");
        escrow.release(jobId, provider, AMOUNT + 1, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnResultMismatch() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes32 otherResult = keccak256("other-result");
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, otherResult);
        vm.expectRevert("ResultMismatch");
        escrow.release(jobId, provider, AMOUNT, otherResult, sig);
    }

    function test_Release_RevertsOnNonPayerSignature() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes32 structHash = keccak256(abi.encode(RELEASE_TYPEHASH, jobId, provider, AMOUNT, RESULT_HASH));
        bytes memory sig = _sign(strangerKey, structHash);
        vm.expectRevert("BadAuthorization");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    /// @dev The evaluator signed the result, but has no authority to pay.
    function test_Release_RevertsWhenEvaluatorTriesToAuthorize() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes32 structHash = keccak256(abi.encode(RELEASE_TYPEHASH, jobId, provider, AMOUNT, RESULT_HASH));
        bytes memory sig = _sign(evaluatorKey, structHash);
        vm.expectRevert("BadAuthorization");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnTamperedAmount() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        // Authorization signed for AMOUNT, submitted with a smaller amount.
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        vm.expectRevert("AmountMismatch");
        escrow.release(jobId, provider, 1e6, RESULT_HASH, sig);
    }

    function test_Release_RevertsOnReplay() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);

        vm.expectRevert("WrongState");
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
    }

    function _domainSeparatorFor(address verifyingContract) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("EvaluationEscrow"),
                keccak256("1"),
                block.chainid,
                verifyingContract
            )
        );
    }

    function _signFor(uint256 key, address verifyingContract, bytes32 structHash) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(key, MessageHashUtils.toTypedDataHash(_domainSeparatorFor(verifyingContract), structHash));
        return abi.encodePacked(r, s, v);
    }

    /// @dev The token re-enters release() during its own transfer. The guard
    ///      rejects the inner call, the token swallows it, and the outer release
    ///      completes — exactly once.
    function test_Release_ReentrancyIsBlockedAndPaysOnce() public {
        ReentrantUSDC evil = new ReentrantUSDC();
        EvaluationEscrow evilEscrow = new EvaluationEscrow(address(evil), evaluator);
        address escrowAddr = address(evilEscrow);

        evil.mint(payer, AMOUNT);
        evil.setEscrow(evilEscrow);
        vm.prank(payer);
        evil.approve(escrowAddr, type(uint256).max);

        vm.prank(payer);
        uint256 jobId = evilEscrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);

        evilEscrow.verifyResult(
            jobId,
            TASK_HASH,
            PLAN_HASH,
            RESULT_HASH,
            87,
            1,
            deadline,
            _signFor(
                evaluatorKey,
                escrowAddr,
                keccak256(abi.encode(ATTESTATION_TYPEHASH, jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline))
            )
        );

        bytes memory sig = _signFor(
            payerKey, escrowAddr, keccak256(abi.encode(RELEASE_TYPEHASH, jobId, provider, AMOUNT, RESULT_HASH))
        );

        // The token re-enters release() during its own transfer. The guard must
        // reject the inner call and leave the outer one to complete normally.
        evil.arm(jobId, provider, AMOUNT, sig);
        evilEscrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);

        assertEq(evil.balanceOf(provider), AMOUNT, "paid exactly once");
        assertEq(evil.balanceOf(escrowAddr), 0);
        assertEq(evilEscrow.getJob(jobId).state, 3, "RELEASED");
    }

    function test_Release_RevertsOnReentrancyAttemptThatPreemptsTransfer() public {
        ReentrantUSDC evil = new ReentrantUSDC();
        EvaluationEscrow evilEscrow = new EvaluationEscrow(address(evil), evaluator);
        address escrowAddr = address(evilEscrow);
        evil.setEscrow(evilEscrow);

        // Fund the escrow directly, then have the token re-enter before the
        // outer transfer: the guard fires on the inner call.
        evil.mint(payer, AMOUNT);
        vm.prank(payer);
        evil.approve(escrowAddr, type(uint256).max);
        vm.prank(payer);
        uint256 jobId = evilEscrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);

        evilEscrow.verifyResult(
            jobId,
            TASK_HASH,
            PLAN_HASH,
            RESULT_HASH,
            87,
            1,
            deadline,
            _signFor(
                evaluatorKey,
                escrowAddr,
                keccak256(abi.encode(ATTESTATION_TYPEHASH, jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline))
            )
        );

        bytes memory sig = _signFor(
            payerKey, escrowAddr, keccak256(abi.encode(RELEASE_TYPEHASH, jobId, provider, AMOUNT, RESULT_HASH))
        );

        evil.setRevertOnReentry(true);
        evil.arm(jobId, provider, AMOUNT, sig);
        vm.expectRevert();
        evilEscrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);

        // Nothing moved and the job is unchanged.
        assertEq(evil.balanceOf(provider), 0);
        assertEq(evil.balanceOf(escrowAddr), AMOUNT);
        assertEq(evilEscrow.getJob(jobId).state, 2, "still RESULT_VERIFIED");
    }

    // ═══ refundExpired ═══════════════════════════════════════════════════════

    function test_RefundExpired_FromFunded() public {
        uint256 jobId = _createJob();
        vm.warp(uint256(deadline) + 1);

        vm.expectEmit(true, true, false, true, address(escrow));
        emit JobRefunded(jobId, payer, AMOUNT);
        escrow.refundExpired(jobId);

        assertEq(usdc.balanceOf(payer), 1_000e6);
        assertEq(escrow.getJob(jobId).state, 4, "REFUNDED");
    }

    function test_RefundExpired_FromResultVerified_StatusFailed() public {
        uint256 jobId = _createJob();
        bytes memory attestation = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline);
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 42, 2, deadline, attestation);

        vm.warp(uint256(deadline) + 1);
        escrow.refundExpired(jobId);
        assertEq(usdc.balanceOf(payer), 1_000e6);
    }

    /// @dev v2: a verified PASSING result can never be refunded — not by a
    ///      stranger, not by the payer. Under v1 this exact sequence clawed back
    ///      a provider's earned payment after the deadline. The payer's remedy
    ///      is `release`, which remains available at any time.
    function test_RefundExpired_RevertsOnPassedVerifiedJob() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);

        vm.expectRevert("NotExpired");
        escrow.refundExpired(jobId);

        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("ResultPassed");
        escrow.refundExpired(jobId);

        // The payer's authority survives the deadline: release still works.
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(usdc.balanceOf(provider), AMOUNT);
        assertEq(usdc.balanceOf(payer), 1_000e6 - AMOUNT);
    }

    /// @dev v2: documents that release is deliberately NOT deadline-gated. The
    ///      payer signed the release; the protocol honors it whenever it lands.
    ///      (v1 also allowed this, but v1 additionally allowed anyone to
    ///      refund the same job after the deadline — a race this test's
    ///      sibling now proves is closed.)
    function test_Release_AfterDeadline_PaysPassedProvider() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);

        vm.warp(uint256(deadline) + 30 days);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(usdc.balanceOf(provider), AMOUNT);
    }

    function test_RefundExpired_IsPermissionlessButPaysPayer() public {
        uint256 jobId = _createJob();
        vm.warp(uint256(deadline) + 1);

        vm.prank(stranger);
        escrow.refundExpired(jobId);

        assertEq(usdc.balanceOf(payer), 1_000e6, "refund always goes to the payer");
        assertEq(usdc.balanceOf(stranger), 0);
    }

    function test_RefundExpired_RevertsOnUnknownJob() public {
        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("UnknownJob");
        escrow.refundExpired(999);
    }

    function test_RefundExpired_RevertsOnExpiredButReleasedJob() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);

        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("WrongState");
        escrow.refundExpired(jobId);
    }

    function test_RefundExpired_RevertsOnCancelledJob() public {
        uint256 jobId = _createJob();
        vm.prank(payer);
        escrow.cancelJob(jobId);

        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("WrongState");
        escrow.refundExpired(jobId);
    }

    function test_RefundExpired_AllowsLateVerificationThenRefund() public {
        uint256 jobId = _createJob();
        vm.warp(uint256(deadline) + 1);
        escrow.refundExpired(jobId);

        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 99, 1, deadline + 3600);
        vm.expectRevert("WrongState");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 99, 1, deadline + 3600, sig);
    }

    // ═══ cancelJob ═══════════════════════════════════════════════════════════

    function test_CancelJob_RefundsPayer() public {
        uint256 jobId = _createJob();

        vm.expectEmit(true, true, false, true, address(escrow));
        emit JobCancelled(jobId, payer, AMOUNT);
        vm.prank(payer);
        escrow.cancelJob(jobId);

        assertEq(usdc.balanceOf(payer), 1_000e6);
        assertEq(escrow.getJob(jobId).state, 5, "CANCELLED");
    }

    function test_CancelJob_RevertsOnUnknownJob() public {
        vm.prank(payer);
        vm.expectRevert("UnknownJob");
        escrow.cancelJob(999);
    }

    function test_CancelJob_RevertsForNonPayer() public {
        uint256 jobId = _createJob();
        vm.prank(stranger);
        vm.expectRevert("NotPayer");
        escrow.cancelJob(jobId);
    }

    /// @dev Once a result exists, the provider has delivered; the payer must use
    ///      the deadline path instead.
    function test_CancelJob_RevertsAfterResultVerified() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        vm.prank(payer);
        vm.expectRevert("WrongState");
        escrow.cancelJob(jobId);
    }

    function test_CancelJob_ThenRefundExpiredReverts() public {
        uint256 jobId = _createJob();
        vm.prank(payer);
        escrow.cancelJob(jobId);

        vm.warp(uint256(deadline) + 1);
        vm.expectRevert("WrongState");
        escrow.refundExpired(jobId);
    }

    // ═══ Evaluator rotation ══════════════════════════════════════════════════

    function test_SetEvaluator_AppliesToNewJobsOnly() public {
        uint256 jobA = _createJob();

        address newEvaluator = vm.addr(0xC0FFEE);
        vm.expectEmit(true, true, false, false, address(escrow));
        emit EvaluatorChanged(evaluator, newEvaluator);
        escrow.setEvaluator(newEvaluator);

        uint256 jobB = _createJob();

        assertEq(escrow.getJob(jobA).evaluator, evaluator, "pending job keeps its evaluator");
        assertEq(escrow.getJob(jobB).evaluator, newEvaluator);

        // The old evaluator can still settle the job it was assigned.
        _verifyPassing(jobA);
        assertEq(escrow.getJob(jobA).state, 2);

        // The new default cannot rewrite a job created before the rotation.
        bytes memory staleSig = _attestationSig(jobB, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline);
        vm.expectRevert("BadAttestation");
        escrow.verifyResult(jobB, TASK_HASH, PLAN_HASH, RESULT_HASH, 87, 1, deadline, staleSig);
    }

    function test_SetEvaluator_RevertsForNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        escrow.setEvaluator(stranger);
    }

    function test_SetEvaluator_RevertsOnZeroAddress() public {
        vm.expectRevert("ZeroEvaluator");
        escrow.setEvaluator(address(0));
    }

    function test_SetEvaluator_CannotCreateAJobWithNoEvaluator() public {
        // setEvaluator rejects zero, so the default can never become unset and
        // a job can never be created that no key can ever attest for.
        vm.expectRevert("ZeroEvaluator");
        escrow.setEvaluator(address(0));
        assertEq(escrow.evaluator(), evaluator, "default unchanged");
    }

    // ═══ Owner powers and pause ══════════════════════════════════════════════

    function test_Pause_BlocksNewJobsOnly() public {
        uint256 jobId = _createJob();
        escrow.pause();

        vm.prank(payer);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        escrow.createJob(provider, AMOUNT, TASK_HASH, PASS_SCORE, deadline);

        // An existing job can still be verified, released, refunded, cancelled:
        // pausing must not strand funds.
        _verifyPassing(jobId);
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(usdc.balanceOf(provider), AMOUNT);
    }

    function test_Pause_DoesNotBlockRefund() public {
        uint256 jobId = _createJob();
        escrow.pause();
        vm.warp(uint256(deadline) + 1);
        escrow.refundExpired(jobId);
        assertEq(usdc.balanceOf(payer), 1_000e6);
    }

    function test_Unpause_RestoresJobCreation() public {
        escrow.pause();
        escrow.unpause();
        uint256 jobId = _createJob();
        assertEq(escrow.getJob(jobId).state, 1);
    }

    function test_Pause_RevertsForNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        escrow.pause();
    }

    function test_Unpause_RevertsForNonOwner() public {
        escrow.pause();
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        escrow.unpause();
    }

    /// @dev The owner has no function that can move an existing job's funds.
    function test_OwnerCannotSeizeJob() public {
        uint256 jobId = _createJob();
        _verifyPassing(jobId);
        escrow.pause();
        escrow.setEvaluator(stranger);

        EvaluationEscrow.Job memory job = escrow.getJob(jobId);
        assertEq(job.payer, payer);
        assertEq(job.provider, provider);
        assertEq(job.amount, AMOUNT);
        assertEq(usdc.balanceOf(address(escrow)), AMOUNT);
    }

    // ═══ Constructor ═════════════════════════════════════════════════════════

    function test_Constructor_RevertsOnZeroUsdc() public {
        vm.expectRevert("ZeroUsdc");
        new EvaluationEscrow(address(0), evaluator);
    }

    function test_Constructor_RevertsOnZeroEvaluator() public {
        vm.expectRevert("ZeroEvaluator");
        new EvaluationEscrow(address(usdc), address(0));
    }

    function test_Constructor_SetsDomainAndOwner() public {
        assertEq(escrow.owner(), address(this));
        assertEq(address(escrow.usdc()), address(usdc));
        assertEq(escrow.evaluator(), evaluator);
        assertEq(escrow.nextJobId(), 1);
    }

    function test_Constructor_EmitsEvaluatorChanged() public {
        vm.recordLogs();
        new EvaluationEscrow(address(usdc), evaluator);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 topic = keccak256("EvaluatorChanged(address,address)");
        bool found;
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].topics[0] == topic) {
                found = true;
                assertEq(address(uint160(uint256(logs[i].topics[1]))), address(0));
                assertEq(address(uint160(uint256(logs[i].topics[2]))), evaluator);
            }
        }
        assertTrue(found, "EvaluatorChanged emitted");
    }

    // ═══ Full lifecycle ══════════════════════════════════════════════════════

    function test_FullLifecycle_HappyPath() public {
        uint256 jobId = _createJob();
        assertEq(escrow.getJob(jobId).state, 1);

        _verifyPassing(jobId);
        assertEq(escrow.getJob(jobId).state, 2);

        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, RESULT_HASH);
        escrow.release(jobId, provider, AMOUNT, RESULT_HASH, sig);
        assertEq(escrow.getJob(jobId).state, 3);
        assertEq(usdc.balanceOf(provider), AMOUNT);
    }

    function testFuzz_ReleaseOnlyForRecordedResult(bytes32 candidate) public {
        vm.assume(candidate != RESULT_HASH);
        vm.assume(candidate != bytes32(0));

        uint256 jobId = _createJob();
        _verifyPassing(jobId);

        // A payer can be tricked into signing a different hash, but the job
        // only ever pays the one the evaluator recorded.
        bytes memory sig = _releaseSig(jobId, provider, AMOUNT, candidate);
        vm.expectRevert("ResultMismatch");
        escrow.release(jobId, provider, AMOUNT, candidate, sig);
    }

    function testFuzz_VerifyResultRejectsAnyScoreAbove100(uint256 score) public {
        score = bound(score, 101, type(uint256).max);
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, score, 1, deadline);
        vm.expectRevert("BadScore");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, score, 1, deadline, sig);
    }

    function testFuzz_VerifyResultRejectsAnyUnknownStatus(uint8 status) public {
        vm.assume(status != 1 && status != 2);
        uint256 jobId = _createJob();
        bytes memory sig = _attestationSig(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 50, status, deadline);
        vm.expectRevert("BadStatus");
        escrow.verifyResult(jobId, TASK_HASH, PLAN_HASH, RESULT_HASH, 50, status, deadline, sig);
    }

    function testFuzz_JobAmountIsAlwaysFullyFunded(uint96 amount) public {
        amount = uint96(bound(amount, 1, 1_000e6));
        vm.prank(payer);
        uint256 jobId = escrow.createJob(provider, amount, TASK_HASH, PASS_SCORE, deadline);
        assertEq(usdc.balanceOf(address(escrow)), amount);
        assertEq(escrow.getJob(jobId).amount, amount);
    }
}
