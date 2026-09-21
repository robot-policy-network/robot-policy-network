# Video Script - 5 minutes, Circle Grants submission

**How to use:** open each file at the marked timestamp, follow the on-screen
action, read the narration. Upload to YouTube (unlisted) or Loom.

**Before recording:** close all other tabs. Increase editor font size. Have ready:
1. contracts/EvaluationEscrow.sol in your editor
2. script/EndToEndSettlement.s.sol in your editor
3. Arc explorer at the settlement contract address
4. Terminal ready to run cast call
5. docs/grants/traction-evidence/ in your editor

---

## [0:00-0:20] Intro

**On screen:** the repo README.md

**Say:**
> Hi, I am Richard, founder of StonkRobotics - also known as Robot Policy
> Network. We are building the trust and settlement layer for machine work on
> Arc. I will show you three things: the contract, a real settlement that
> already executed on mainnet, and our traction data.

## [0:20-1:30] Code: EvaluationEscrow.sol

**On screen:** contracts/EvaluationEscrow.sol

**Say:**
> This is EvaluationEscrow on Arc mainnet. The core design: evidence and
> authority are different keys.
>
> createJob. (scroll to it) The payer escrows USDC. safeTransferFrom pulls
> Circle native USDC from the payer into the escrow - that is the ERC-20
> interface at 0x3600...0000.
>
> verifyResult. (scroll to it) The evaluator signs an EIP-712 attestation -
> jobId, taskHash, planHash, resultHash, score, deadline. The contract
> verifies the signature. This records evidence on-chain. It CANNOT move
> funds - there is no transfer here.
>
> release. (scroll to it) The payer signs a separate ReleaseAuthorization.
> The contract checks score against passScore, verifies the resultHash
> matches, recovers the payer signature. Only then does it call safeTransfer
> to pay. Neither key acts alone.

## [1:30-2:30] Code: EndToEndSettlement.s.sol

**On screen:** script/EndToEndSettlement.s.sol

**Say:**
> This script runs the complete flow. In _settle, we fund a job, the
> evaluator signs the attestation off-chain using EIP-712 typed data - the
> domain separator uses the contract address as verifyingContract, version
> 1. The payer signs a separate ReleaseAuthorization.
>
> escrow.verifyResult records the evidence. escrow.release moves the USDC.
> The script asserts the provider received exactly the escrowed amount and
> the job state is RELEASED.

(scroll to _settle - point out the verifyResult and release calls)

## [2:30-3:30] On-chain proof

**On screen:** Arc explorer, then terminal

**Say:**
> Deployed on Arc mainnet at 0x479F...7491. Here is the settlement that
> already executed.
>
> (terminal:)
> cast call 0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491 getJob 1 --rpc-url https://rpc.mainnet.arc.io
>
> Job 1: payer 0x92bF..., provider 0x5dF7..., state 3 - RELEASED. Amount:
> 500000 = 0.5 USDC. The release tx was 0x4a8ccd2d...
>
> (show on explorer) The Transfer event shows the escrow paid the provider
> 0.5 USDC. The attestation was verified in a separate tx. Two independent
> signatures, both required.

## [3:30-4:15] Traction

**On screen:** docs/grants/traction-evidence/ in your editor

**Say:**
> Our evaluation flow has been running continuously since mainnet launch.
> In five days, 217 wallets submitted 65,138 scored rounds across 67 real
> robot tasks. Every record is SHA-256 pinned. Let me run the verifier.
>
> (run: bash verify.sh)
> It re-hashes every record and re-derives the stats. You do not have to
> trust our numbers - the script recomputes them.

## [4:15-5:00] Ask

**On screen:** the milestones table

**Say:**
> M1 and M2 are done - deployed and settled on mainnet, our own funds. This
> grant funds two things:
>
> M3: Circle Agent Stack integration. Our 217-wallet community will
> transact through Circle primitives. Target: 25+ USDC settlements through
> Agent Stack by end of January.
>
> M4: Independent security review. The contract is unaudited. We want
> findings published and fixed before third-party funds.
>
> One thing to know about us: we ship. The contract is deployed. A settlement
> has executed. The data is public. Thank you.

---

## Recording tips

- Use Loom (free, screen+camera) or OBS
- If over 5 min, cut traction shorter (verify.sh in 10s instead of 30s)
- If you stumble, pause 2s and redo that section (cut later)
- Key moments reviewers remember: release() code showing BOTH signatures,
  the on-chain getJob showing state 3, and verify.sh output ALL PASS
