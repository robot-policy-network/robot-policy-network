// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title EvaluationEscrow
 * @notice Holds USDC for a robot-policy evaluation job and releases it only when
 *         an evaluator-attested result and the payer's release authorization agree.
 *
 * The design point is the split between EVIDENCE and AUTHORITY:
 *
 *   - The EVALUATOR signs an EvaluationAttestation: "this plan scored X against
 *     this task". It can never move funds.
 *   - The PAYER signs a ReleaseAuthorization: "pay this provider this amount for
 *     this result". It alone moves funds, and it alone decides.
 *
 * `release()` requires both. Neither key can settle a job by itself, and a score
 * is never treated as a payment instruction.
 *
 * The contract escrows; it does not evaluate. `planHash`, `taskHash`, and
 * `resultHash` are opaque commitments that the contract stores and compares but
 * cannot recompute — verifying a result means re-running the published evaluator
 * off-chain, which is the point of publishing it. The contract's job is to make
 * sure the *payment* is bound to the commitment the payer authorized.
 *
 * USDC on Arc has two interfaces over one balance: a native 18-decimal view used
 * for gas, and an ERC-20 6-decimal view at 0x3600...0000. This contract uses the
 * ERC-20 interface exclusively, per Arc's own integration guidance. Every amount
 * here is in 6-decimal units (1_000_000 == 1.00 USDC).
 *
 * See docs/settlement-spec.md for the frozen protocol. SPEC_VERSION = 1.
 */
contract EvaluationEscrow is Ownable, Pausable, ReentrancyGuard, EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // ─── Types ──────────────────────────────────────────────────────────────

    struct Job {
        address payer;
        address provider;
        address evaluator; // fixed at creation; the only key verifyResult accepts
        uint16 passScore; // 0-100, the threshold this job is graded against
        uint8 state;
        uint64 deadline;
        uint256 amount; // USDC, 6 decimals
        bytes32 taskHash; // committed by the payer at creation
        bytes32 planHash; // recorded by verifyResult
        bytes32 resultHash; // recorded by verifyResult
        uint256 score; // recorded by verifyResult
    }

    // ─── Constants ──────────────────────────────────────────────────────────

    uint8 internal constant _STATE_NONE = 0;
    uint8 internal constant _STATE_FUNDED = 1;
    uint8 internal constant _STATE_RESULT_VERIFIED = 2;
    uint8 internal constant _STATE_RELEASED = 3;
    uint8 internal constant _STATE_REFUNDED = 4;
    uint8 internal constant _STATE_CANCELLED = 5;

    uint8 internal constant _STATUS_PASSED = 1;
    uint8 internal constant _STATUS_FAILED = 2;

    /// @dev Distinct from UnitreeG1Fleet's domain, so no signature from the mint
    ///      flow can ever be replayed here (or vice versa).
    bytes32 internal constant _ATTESTATION_TYPEHASH = keccak256(
        "EvaluationAttestation(uint256 jobId," "bytes32 taskHash," "bytes32 planHash," "bytes32 resultHash,"
        "uint256 score," "uint8 status," "uint256 deadline)"
    );

    bytes32 internal constant _RELEASE_TYPEHASH =
        keccak256("ReleaseAuthorization(uint256 jobId,address provider,uint256 amount,bytes32 resultHash)");

    // ─── Storage ────────────────────────────────────────────────────────────

    /// @notice USDC ERC-20 interface address (6 decimals on Arc).
    IERC20 public immutable usdc;

    /// @notice Default evaluator for NEW jobs. Rotating it cannot affect a job
    ///         already created, because each job captures its own evaluator.
    address public evaluator;

    uint256 public nextJobId = 1;
    mapping(uint256 => Job) private _jobs;

    // ─── Events ─────────────────────────────────────────────────────────────

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

    // ─── Constructor ────────────────────────────────────────────────────────

    constructor(address usdc_, address evaluator_) Ownable(msg.sender) EIP712("EvaluationEscrow", "1") {
        require(usdc_ != address(0), "ZeroUsdc");
        require(evaluator_ != address(0), "ZeroEvaluator");
        usdc = IERC20(usdc_);
        evaluator = evaluator_;
        emit EvaluatorChanged(address(0), evaluator_);
    }

    // ─── Job lifecycle ──────────────────────────────────────────────────────

    /**
     * @notice Fund a job against a task. Caller must have approved `amount` USDC.
     * @dev The plan is NOT committed here. The provider writes the policy and
     *      submits it after the job exists, so the plan is bound at
     *      `verifyResult` instead — through `planHash`, and transitively through
     *      `resultHash` which the payer authorizes at release.
     */
    function createJob(address provider, uint256 amount, bytes32 taskHash, uint16 passScore, uint64 deadline)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 jobId)
    {
        require(provider != address(0), "ZeroProvider");
        require(amount != 0, "ZeroAmount");
        require(taskHash != bytes32(0), "ZeroTaskHash");
        require(deadline > block.timestamp, "DeadlineInPast");
        require(passScore <= 100, "BadPassScore");
        require(evaluator != address(0), "ZeroEvaluator");

        jobId = nextJobId++;
        _jobs[jobId] = Job({
            payer: msg.sender,
            provider: provider,
            evaluator: evaluator,
            passScore: passScore,
            state: _STATE_FUNDED,
            deadline: deadline,
            amount: amount,
            taskHash: taskHash,
            planHash: bytes32(0),
            resultHash: bytes32(0),
            score: 0
        });

        // Pull after the state write; ReentrancyGuard covers a hostile token.
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        emit JobCreated(jobId, msg.sender, provider, evaluator, amount, taskHash, passScore, deadline);
    }

    /**
     * @notice Record an evaluator-signed result. Permissionless: the attestation
     *         is bound to the job and the evaluator is fixed at creation, so
     *         anyone may carry it on-chain.
     * @dev Does NOT move funds. Verification and payment are separate steps.
     */
    function verifyResult(
        uint256 jobId,
        bytes32 taskHash,
        bytes32 planHash,
        bytes32 resultHash,
        uint256 score,
        uint8 status,
        uint256 sigDeadline,
        bytes calldata sig
    ) external {
        Job storage job = _jobs[jobId];
        if (job.state == _STATE_NONE) revert("UnknownJob");
        if (job.state != _STATE_FUNDED) revert("WrongState");
        if (block.timestamp > sigDeadline) revert("AttestationExpired");
        if (block.timestamp > job.deadline) revert("JobExpired");
        if (taskHash != job.taskHash) revert("TaskMismatch");
        if (planHash == bytes32(0)) revert("ZeroPlanHash");
        if (resultHash == bytes32(0)) revert("ZeroResultHash");
        if (score > 100) revert("BadScore");
        if (status != _STATUS_PASSED && status != _STATUS_FAILED) revert("BadStatus");

        bytes32 structHash = keccak256(
            abi.encode(_ATTESTATION_TYPEHASH, jobId, taskHash, planHash, resultHash, score, status, sigDeadline)
        );
        if (_hashTypedDataV4(structHash).recover(sig) != job.evaluator) revert("BadAttestation");

        job.state = _STATE_RESULT_VERIFIED;
        job.planHash = planHash;
        job.resultHash = resultHash;
        job.score = score;

        emit ResultVerified(jobId, planHash, resultHash, score, status);
    }

    /**
     * @notice Pay the provider. Requires that the result passed AND that the
     *         payer signed this exact settlement.
     * @dev `provider` and `amount` are taken as parameters rather than read from
     *      the job so that a signature built against stale state fails with a
     *      diagnosable error instead of a generic one.
     */
    function release(uint256 jobId, address provider, uint256 amount, bytes32 resultHash, bytes calldata sig)
        external
        nonReentrant
    {
        Job storage job = _jobs[jobId];
        if (job.state == _STATE_NONE) revert("UnknownJob");
        if (job.state != _STATE_RESULT_VERIFIED) revert("WrongState");
        if (job.score < job.passScore) revert("ResultNotPassed");
        if (provider != job.provider) revert("ProviderMismatch");
        if (amount != job.amount) revert("AmountMismatch");
        if (resultHash != job.resultHash) revert("ResultMismatch");

        bytes32 structHash = keccak256(abi.encode(_RELEASE_TYPEHASH, jobId, provider, amount, resultHash));
        if (_hashTypedDataV4(structHash).recover(sig) != job.payer) revert("BadAuthorization");

        job.state = _STATE_RELEASED;
        usdc.safeTransfer(job.provider, job.amount);
        emit JobReleased(jobId, job.provider, job.amount, resultHash);
    }

    /**
     * @notice Reclaim funds after the deadline. Permissionless to call, but the
     *         refund always goes to the payer. This is the backstop for every
     *         outcome that is not a completed release.
     */
    function refundExpired(uint256 jobId) external nonReentrant {
        Job storage job = _jobs[jobId];
        if (job.state == _STATE_NONE) revert("UnknownJob");
        if (job.state != _STATE_FUNDED && job.state != _STATE_RESULT_VERIFIED) {
            revert("WrongState");
        }
        if (block.timestamp <= job.deadline) revert("NotExpired");

        job.state = _STATE_REFUNDED;
        usdc.safeTransfer(job.payer, job.amount);
        emit JobRefunded(jobId, job.payer, job.amount);
    }

    /**
     * @notice Payer withdraws from a job that has not produced a result yet.
     * @dev Unavailable once a result is verified, so a provider who delivered
     *      cannot be paid and then clawed back.
     */
    function cancelJob(uint256 jobId) external nonReentrant {
        Job storage job = _jobs[jobId];
        if (job.state == _STATE_NONE) revert("UnknownJob");
        if (job.state != _STATE_FUNDED) revert("WrongState");
        if (msg.sender != job.payer) revert("NotPayer");

        job.state = _STATE_CANCELLED;
        usdc.safeTransfer(job.payer, job.amount);
        emit JobCancelled(jobId, job.payer, job.amount);
    }

    // ─── Views ──────────────────────────────────────────────────────────────

    function getJob(uint256 jobId) external view returns (Job memory) {
        return _jobs[jobId];
    }

    // ─── Owner ──────────────────────────────────────────────────────────────

    /// @notice Rotates the evaluator for NEW jobs only. Existing jobs keep the
    ///         evaluator they captured at creation, so this can neither
    ///         invalidate a pending job nor rewrite a recorded result.
    function setEvaluator(address evaluator_) external onlyOwner {
        require(evaluator_ != address(0), "ZeroEvaluator");
        emit EvaluatorChanged(evaluator, evaluator_);
        evaluator = evaluator_;
    }

    /// @notice Blocks new job creation. Existing jobs can still be verified,
    ///         released, refunded, or cancelled — pausing must not strand funds.
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
