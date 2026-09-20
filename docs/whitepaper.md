# Robot Policy Network — Whitepaper (draft v1)

**Verifiable evaluation and USDC settlement for machine work**

_Published 2026-09-20. Draft; the frozen protocol is
[`settlement-spec.md`](settlement-spec.md) (`SPEC_VERSION = 2`)._

---

## Abstract

Autonomous agents and robots increasingly produce economically meaningful work,
but there is no trustworthy way to pay for it. Every existing mechanism either
lets a human remain the decider, or lets an unverified claim move money. This
paper describes Robot Policy Network: a protocol that separates **evaluation
evidence** from **payment authorization** cryptographically, so that a machine's
work can be provably evaluated and settled in USDC without any single key being
able to do both. We describe the deterministic evaluation method, the EIP-712
artifact pair, the settlement contract, the security model and its accepted
limitations, and the current status of each component — including which parts
are live and which are specified but not yet deployed.

## 1. The problem

Machine work is becoming cheap to perform and expensive to trust.

Consider an agent that claims to have completed a task. A payer faces a
question with no cheap answer: did it? Today's answer set is small and each
option fails in a characteristic way.

- **Agent-payment tooling** lets an agent *spend* a human's money. The human
  still decides; nothing is verified. This automates the wallet, not the trust.
- **Escrow and oracle designs** typically bind payment to a reported value. If
  the report is wrong — hallucinated, manipulated, or simply a bad proxy — money
  moves anyway. The score *is* the payment instruction, which makes it the
  attack surface.
- **Human review** works and does not scale: it is slower than the work it
  reviews, so it cannot sit in a machine-speed loop.

The common defect is a missing distinction. "This work scored 91" and "pay this
provider 25 USDC for this result" are different statements made by different
parties, with different incentives. Systems that collapse them into one
signature inherit the weaker trust assumption of the two.

## 2. Design principle: evidence and authority are separate

The protocol's central rule is that **a score is not a payment instruction**.

|  | Evaluation evidence | Payment authorization |
|---|---|---|
| Producer | Evaluator (deterministic scorer) | Payer (job creator) |
| Artifact | `EvaluationAttestation` | `ReleaseAuthorization` |
| States | "this plan scored X against task T under evaluator E" | "I authorize paying P this amount for job J" |
| Can move funds | **No** | **No, by itself** |

Settlement requires both. Three consequences follow:

1. **An evaluator cannot pay itself.** Even a fully dishonest evaluator only
   produces a claim; a separate payer key must authorize that exact result.
2. **A payer cannot rewrite history.** A release is bound to a `resultHash` the
   evaluator already attested, so paying a different result than the one
   verified fails.
3. **Owner privilege is bounded.** The contract owner can rotate the *default*
   evaluator for future jobs and pause *new* job creation. It cannot redirect an
   existing job's funds, rewrite a recorded result, or strand escrowed money.

## 3. Evaluation: score by execution, not by text

Cheap-to-fake scoring invalidates the whole design, so the evaluation layer
anchors to execution.

Each task carries a **hidden reference trajectory** derived from real robot
episodes. The agent submits a **structured action plan** (navigate / move /
grip / cut / transport / wait). The evaluator then:

1. **Executes** the plan in a pure-function 2D end-effector simulator against a
   structured world state, across several seeded perturbations, and collects the
   executed path and any constraint violations (collision, over-force, safety).
2. **Scores executability**: a plan that produces a hard violation, or that
   cannot be executed, scores zero. This cannot be bluffed from the text of the
   answer.
3. **Scores alignment**: similarity between the executed path and the hidden
   reference. The reference never reaches the client, so it cannot be looked up
   or fitted.

Determinism is a property of the code, not a promise: the simulator is a pure
function of `(world, plan, seed)`, with a local explicitly-seeded PRNG and no
clock or global randomness in the scoring path. Same inputs produce the same
score on any machine.

**Why not an LLM judge?** An LLM score is not reproducible, not auditable, and
not deterministic, so it cannot anchor an on-chain artifact. A rubric over text
is deterministic but proxy-based and gameable — we proved this against our own
scorer and documented it in
[`security/red-team-findings.md`](security/red-team-findings.md) (RT-1). Both
are therefore admissible only for non-settlement purposes.

## 4. Commitments: how a claim becomes auditable

A score is useless on-chain unless an outside party can re-derive what was
scored. The protocol therefore canonicalizes every artifact before hashing it.

- **Canonical serialization** (spec §3): object keys sorted ascending by UTF-16
  code unit, recursively, over UTF-8 bytes; arrays preserve order; explicit
  number formatting. Anyone can recompute a hash from a published record without
  access to our runtime.
- **Three commitments per job**: `taskHash` (the task, including the hidden
  reference, committed by the payer at job creation), `planHash` (the submitted
  plan, recorded by `verifyResult`), and `resultHash` (the full result object,
  which embeds `planHash`, and is what the payer authorizes at release).
- **EIP-712 domain**: `EvaluationEscrow` / version `1`, with a domain distinct
  from the collection contract's, so no signature from the mint flow can ever be
  replayed into settlement (or vice versa).

The important property is *transitive binding*: because `resultHash` contains
`planHash`, and the payer signs `resultHash`, a payer cannot be tricked into
funding a result whose preimage names a different plan from the one evaluated.

## 5. Settlement contract

`EvaluationEscrow` escrows USDC and enforces the split. Its lifecycle:

```
createJob(provider, amount, taskHash, passScore, deadline)   → FUNDED
verifyResult(... evaluator signature ...)                     → RESULT_VERIFIED
release(jobId, provider, amount, resultHash, payer signature) → RELEASED
refundExpired(jobId)          → REFUNDED   (deadline backstop)
cancelJob(jobId)              → CANCELLED  (payer, only pre-verification)
```

Design notes worth stating explicitly:

- **`release` requires `score >= passScore`.** Verification proves a result
  exists; only a passing result is payable.
- **`verifyResult` is permissionless.** Anyone may carry a valid attestation
  on-chain; the evaluator is fixed at job creation, so a third party cannot
  substitute their own.
- **`refundExpired` is permissionless to call but always refunds the payer** —
  the backstop for every outcome that is not a completed release.
- **`cancelJob` is unavailable after verification**, so a provider who delivered
  cannot be paid and then clawed back.
- **Pausing blocks only new job creation**; existing jobs can still be verified,
  released, refunded, or cancelled, so a pause never strands funds.
- **Amounts are 6-decimal USDC** through Arc's ERC-20 interface, never mixed
  with the 18-decimal native view.

The contract escrows; it does not evaluate. `planHash`, `taskHash`, and
`resultHash` are opaque to it. Its job is to make sure the *payment* is bound to
the commitment the payer authorized.


## 6. Security model and accepted limitations

**Trust assumptions.** The evaluator is a single hot key per job. The owner
controls configuration. The payer controls its own funds. The protocol assumes
the evaluator may be dishonest and the payer may be careless; it is designed to
survive both without losing custody.

**Stated limitations (not hidden):**

1. **`planHash` is not re-computed on-chain** (spec §10). The contract never
   sees the plan. A payer who does not recompute the preimage off-chain trusts
   the evaluator to have bound the right plan. The protocol makes that check
   cheap and publishable; it does not make it automatic. On-chain
   canonicalization was considered and rejected: the plan is written *after* the
   job exists, and a duplicate canonicalizer in Solidity that drifts produces a
   *different hash* rather than an error — a silent failure class.
2. **Alignment scoring is not independently recomputable today.** The reference
   is hidden, which is what makes it un-gameable and also what makes it
   unverifiable. Graded honestly in
   [`evaluation-reproducibility.md`](evaluation-reproducibility.md) (L1 of
   L0/L1/L2), with a concrete proposal to restore recomputability without
   revealing references.
3. **No independent audit exists.** CI (85 tests plus a deploy-path smoke test)
   is the current assurance.
4. **The settlement contract is not deployed.**

## 7. What is live, and what is not

| Component | Status |
|---|---|
| Deterministic evaluation of trajectory-anchored tasks | **live** |
| On-chain recording of verified results (Arc mainnet, chain 5042) | **live** |
| Public traction dataset (492 records, SHA-256 pinned) | **published** |
| Frozen settlement specification (`SPEC_VERSION = 2`) | **published** |
| `EvaluationEscrow` implementation + 85-test suite | **written, tested** |
| Verified deploy script (unsafe-input guards, CI smoke test) | **written, tested** |
| `EvaluationEscrow` on Arc mainnet | **not deployed** |
| USDC settlement in production | **not live** |
| Curated training-data assets (labels, hard cases, traces) | **roadmap** |

## 8. Relation to prior work

- **Curation, not collection, is the bottleneck.** DataMIL (Dass et al., MIT;
  arXiv 2505.09603) shows performance-aware selection beats naive scaling, and
  that naive selection can actively harm downstream success. Raw data is already
  abundant (DROID, arXiv 2403.12945; Open X-Embodiment, 1M+ episodes).
- **Collection is funded and commoditized.** Axis Robotics ($12M seed) and
  PrismaX ($11M, a16z CSX) scale collection and teleoperation; neither defines a
  verification protocol or a payment-authorization split.
- **Scoring-as-a-product exists, without settlement.** RoboTrain (Virtuals,
  2026) validates grading agent output, but relies on centralized human graders
  and no on-chain settlement.
- **What is missing** is the intersection: verifiable evaluation that can
  *authorize* payment without being *able* to make it. That intersection is this
  protocol's contribution.

## 9. Roadmap

1. Deploy `EvaluationEscrow` to Arc testnet, then mainnet, with the frozen spec.
2. Execute one end-to-end settlement with public transaction evidence.
3. Integrate a Circle agent-payment surface so agents transact through Circle
   primitives rather than only settling on Arc.
4. Publish the simulator and task manifest so executability scores become
   independently recomputable (reproducibility §4).
5. Obtain an independent security review before accepting third-party funds.
6. Extend from single-job settlement to milestone-based machine funding.

## 10. Conclusion

The machine economy needs one primitive before it can be an economy: a way for a
machine to be paid for work that a counterparty does not have to take on faith.
The contribution here is not a smarter scorer or a faster chain — it is a
protocol-level separation of the party who *claims* an outcome from the party who
*authorizes* payment, so that neither can act alone. Everything else in this
repository exists to make that separation testable: a deterministic evaluator, a
canonical commitment scheme, a contract with a bounded owner, an 85-test suite,
and an honest account of where the trust still sits.

