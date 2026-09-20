# Circle Developer Grant — Long-Form Application Draft

**Status: DRAFT v2 (2026-09-20).** Every `<PLACEHOLDER>` must be replaced with
founder-confirmed information before submission. All claims must comply with
[`canonical-fact-sheet.md`](canonical-fact-sheet.md); market and competitor
claims are sourced in [`research-positioning-2026-09.md`](research-positioning-2026-09.md).

---

## One-line summary

StonkRobotics (Robot Policy Network) is the evaluation-verification-settlement
layer for the machine economy on Arc: deterministic evaluation of AI agents
against real robot trajectories, on-chain verifiable records, and a frozen
protocol that hard-separates evaluation evidence from payment authorization
for USDC settlement.

## Problem

The machine economy has a trust gap, and the market has already priced the
two layers around it while leaving the middle empty.

**Collection is funded and commoditized.** Axis Robotics raised a $12M seed
(Hack VC, Jul 2026) and PrismaX raised $11M (a16z CSX, Jun 2025) to scale
robot-data collection; DROID (RSS 2024 Best Paper) and Open X-Embodiment
already publish over a million raw trajectories. Raw data is abundant.

**Academia proved the real bottleneck is curation, not collection.** SIEVE
(arXiv 2607.06442, Jul 2026) demonstrates that structure-aware selection with
only 50% of demonstrations and 50% of training steps **surpasses full-data
training** for VLA imitation learning. More data does not yield better
policies; better-selected data does.

**Yet no one occupies the intersection of curation and settlement.** RoboTrain
(Virtuals Protocol, May 2026) validates scoring-as-a-product but relies on a
centralized 16-member grading team with explicitly no crypto settlement.
Generic oracle and escrow projects treat an unverified score as a payment
instruction. The result: robot-training data cannot be trusted as an asset,
and machine work cannot be safely paid, because there is no trustworthy bridge
between "the agent claims it did the work" and "a payer should release funds."

## Product and current implementation

The live system addresses the first two layers today; this grant funds the
third.

**Layer 1 — Deterministic evaluation anchored to real robot trajectories
(live).** Agents request a challenge at `https://stonkrobotics.xyz/skill/`
and submit a structured mission plan. A pure-function 2D end-effector
simulator executes the plan across seeded perturbations — same input always
yields the same output, so a plan that does not run scores zero and cannot be
bluffed. The 82 evaluation tasks are sliced from real DROID episodes with
hidden reference trajectories that never reach the client, so the rubric
cannot be reverse-engineered. Scoring anchors simultaneously to
executability (no hard violations) and alignment (path similarity to the
hidden reference).

**What "verifiable" means here — and what it does not.** Executability is
independently checkable by anyone (the simulator is published and
deterministic). The alignment score is a signed *claim* by the evaluator
about a hidden reference; it is not a trustless computation. What the
protocol adds is accountability rather than magic: the evaluator's
attestation binds `planHash` and `resultHash` into a canonical, published
preimage (spec §4), so any third party can recompute the hashes from the
published plan and result and publicly flag a mismatch (spec §10). The chain
records *who claimed what, immutably* — it does not pretend the claim is
self-proving.

**Layer 2 — On-chain verifiable records (live on Arc mainnet).** Passing
scores are bound into EIP-712 vouchers (recipient, quantity, score, nonce,
deadline) verified by the deployed contract
(`0x6a3B12532F8e562f99e3292380e7f69D32e10B32`, chain ID 5042) with nonce
replay protection and domain separation. These records are the signed,
attributable performance *inputs* from which curated training assets
(consensus labels, hard cases, reasoning traces — see roadmap) are derived.

**Layer 3 — Evidence/authorization-split USDC settlement (specified, tested,
not yet deployed).** The v1 settlement protocol (`docs/settlement-spec.md`,
frozen at `SPEC_VERSION = 1`) defines two independent EIP-712 artifacts: an
`EvaluationAttestation` produced by the evaluator (evidence; can never move
funds) and a `ReleaseAuthorization` signed by the payer (authority;
insufficient alone). `release()` requires both. The `EvaluationEscrow`
reference implementation passes 81 Foundry tests covering signature validity,
domain separation, deadlines, expiry, and settlement paths.

The three layers form a flywheel — the first three stages run today, the
data-asset and settlement stages are the funded roadmap: agent committees
answer trajectory-anchored tasks → deterministic reproducible scoring →
on-chain verified records → *roadmap:* curated data assets (consensus labels,
hard cases, reasoning traces) → verified outcomes trigger milestone USDC
release → better data attracts better agents.

## Why Arc and why Circle

- **Settlement-finality fit.** Machine-speed work needs machine-speed,
  dollar-denominated settlement. Arc-native USDC (ERC-20 interface at
  `0x3600...0000`, 6 decimals) is the natural asset, and Arc's finality model
  matches the agent-payment cadence.
- **Technical guidance already followed.** The protocol uses Arc's own
  recommended ERC-20-only integration pattern, avoiding the native/ERC-20
  dual-interface pitfalls documented at docs.arc.io.
- **Agentic-economic-activity alignment.** The evidence/authorization split
  is purpose-built for the agentic payments Arc is designed to host: agents
  produce verifiable outcomes; payers authorize USDC release against them —
  neither key alone can settle a job.
- **Existing deployment evidence.** The project's only production deployment
  is Arc mainnet, and the evaluation flow already records outcomes there.

## Agentic economic activity

Today: agents complete trajectory-anchored challenges and receive verifiable,
on-chain-recorded scores — machine work that is already provable. Next:
verified outcomes become the trigger condition for milestone-based USDC
funding, so provable work becomes payable work with an auditable evidence
trail, and each settlement simultaneously produces a curated training-data
asset.
## Technical architecture and security boundary

```text
agent  → challenge → mission plan → deterministic score
       → EIP-712 EvaluationAttestation   (evidence; cannot move funds)
payer  → EIP-712 ReleaseAuthorization    (authority; insufficient alone)
       → EvaluationEscrow releases USDC only when BOTH validate
```

- **No independent security audit has been conducted.** M4 funds an external
  review; the frozen spec and 81-test suite are the interim assurance.
- **Trust assumptions are documented, not hidden.** Owner-controlled
  functions (`setEvaluator`, `pause`) can neither redirect an existing job's
  funds nor rewrite a recorded result; pausing blocks only *new* job creation
  so existing funds are never stranded. See `SECURITY.md` and
  `docs/limitations.md`.
- **The one accepted limitation is stated openly** (spec §10): `planHash` is
  not re-computed on-chain, so a payer who skips off-chain recomputation
  trusts the evaluator to have bound the right plan. The protocol makes that
  check cheap and publishable; it does not make it automatic.
- **The settlement contract is not deployed.** Only the evaluation/recording
  flow is live. This application funds its deployment, not its invention.

## Market and competition

| Player | Raise | Layer | Gap we fill |
|---|---|---|---|
| Axis Robotics | $12M seed (Hack VC, 2026) | Collection engine | No verification protocol or settlement |
| PrismaX | $11M (a16z CSX, 2025) | Collection + teleop + models | Internal scoring, not on-chain verifiable |
| RoboTrain (Virtuals) | Virtuals launch (2026) | Teleop + human scoring | Centralized 16-member grading; explicitly no crypto settlement |
| GAEA / Vana / Fraction AI | various | Data DePIN / DAOs | No trajectory-anchored deterministic evaluation |

Collection is funded; curation-plus-settlement is open. Our moat is the
combination competitors structurally lack: a deterministic, reproducible
evaluator anchored to real robot data, plus an on-chain evidence/authorization
split that makes scores payable without making them payment instructions.

## Milestones

Total duration ~12 weeks from grant award (assumed start 2026-09-21 for
planning; dates shift with actual award date).

1. **M1 — Deploy EvaluationEscrow to Arc testnet + mainnet** with the frozen
   v1 spec; publish deployment manifest and verification evidence.
   Due **2026-10-11** (3 weeks). — **$6,000**
2. **M2 — End-to-end settlement demo**: agent challenge → verified outcome →
   USDC release on Arc, with public transaction evidence. The demo moves only
   the founder's own USDC; **no external or user funds touch the contract
   before M4 completes**.
   Due **2026-10-25** (2 weeks). — **$6,000**
3. **M3 — Circle Agent Stack integration**: agents in the workflow operate
   with Circle-native agent payment capabilities
   `<CONFIRM PRODUCT CHOICE: Agent Stack recommended; swap to Wallets or
   Contracts if that matches the implementation better>`.
   Due **2026-11-22** (4 weeks). — **$8,000**
4. **M4 — Independent security review** of the settlement contract (scoped
   review contest or boutique firm, sized to the $5,000 budget), with
   findings published and critical/high issues fixed before any third-party
   funds are accepted. Due **2026-12-20** (4 weeks). — **$5,000**

**Funding gate:** the contract accepts only founder-funded demo escrows until
M4's review is published. This is the enforcement mechanism behind the
promise in Risks that no production fund flows precede the review.

## Budget / use of funds

**Total ask: $25,000 over ~12 weeks** (founder-delegated sizing, 2026-09-20).

| Milestone | Amount | Share |
|---|---|---|
| M1 deployment + verification evidence | $6,000 | 24% |
| M2 end-to-end settlement demo | $6,000 | 24% |
| M3 Circle product integration | $8,000 | 32% |
| M4 independent security review | $5,000 | 20% |

Budget basis: the $5,000 M4 line is sized to a scoped review contest or a
boutique solo-reviewer engagement for a ~300-line, already-test-covered
contract — not a top-tier firm audit, which the budget does not claim to buy.

## Success metrics

Conditional on grant award:

- **100** verified agent outcomes recorded on Arc per month by 2026-12-31.
- **25** end-to-end USDC settlements executed by 2027-01-31.
- **5** unique paying counterparties by 2027-01-31, sourced from the agent
  teams already operating in Arc's ecosystem that need verifiable outcomes —
  the M3 integration is the outreach channel for this commercial motion.
- 100% of settlements backed by an on-chain verifiable attestation.

## Team and applicant information

- Applicant: **Richard** (solo founder)
- Entity: individual, DBA "StonkRobotics"; Legal Entity Name: N/A
  `<FINAL CONFIRM before signing>`
- Email: **ritsuyan4763@gmail.com**
- Team: solo founder — no unconfirmed members listed

## Open-source / ecosystem contribution

The full protocol — contracts, frozen specification, tests, deployment
evidence, and an honest limitations document — is MIT-licensed at
`https://github.com/robot-policy-network/robot-policy-network`. The
deterministic simulator and trajectory-anchored task format are reusable
evaluation infrastructure for any Arc project that needs verifiable agent
outcomes, not only this one.

## Risks and limitations

- **Unaudited, undeployed settlement contract.** Mitigated by the frozen
  spec, 81-test coverage, and M4's external review before any production
  fund flows.
- **Solo-founder execution risk.** Mitigated by the narrow 12-week scope and
  by shipping only already-specified components.
- **Evaluator centralization.** The current evaluator is a single
  deterministic component; decentralizing it is explicitly future work, and
  the evidence/authorization split is designed to survive evaluator rotation
  (`setEvaluator` affects new jobs only).
- **Marketplace is roadmap.** A general-purpose USDC escrow marketplace is
  not a live claim; this application funds only the settlement primitive.
- **Scope disclosure.** The Arc deployment also hosts an ERC-721 collection
  (`UnitreeG1Fleet`) and a separate ARCROBO token
  (`0x90554cEaf18BD5545F4be6520a3077D327727297`). Both are distinct
  subsystems, documented in the repository's README and limitations file;
  they are not part of this proposal and are not required to use the
  evaluation flow. They are disclosed here so diligence finds no surprises.

## Public links and deployment evidence

- Website: `https://stonkrobotics.xyz/`
- Agent workflow: `https://stonkrobotics.xyz/skill/`
- Repository: `https://github.com/robot-policy-network/robot-policy-network`
- Arc mainnet contract: `https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32`
- Deployment manifest: `deployments/arc-mainnet.json` (read-only RPC evidence, checked 2026-09-18)
- Research & positioning memo: `docs/grants/research-positioning-2026-09.md`
- Video / screenshots / deck: `<LINKS — only if they actually exist>`

