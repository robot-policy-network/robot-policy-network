# Evaluation reproducibility — what a third party can and cannot verify

**Status: honest capability statement + a concrete improvement proposal.**

The application claims scoring is "deterministic and reproducible." That claim
is narrower than it sounds, and this document exists so nobody has to take it
on faith. It states exactly what an outside party can currently verify, what
they cannot, and what would have to change to close the gap.

---

## 1. What "deterministic" actually means here

The evaluator has two paths with very different properties:

| Path | Used for | Scored by | Reproducible? | Gameable? |
|---|---|---|---|---|
| **Simulator** | trajectory missions (`traj-real-*`) | executing the submitted action plan in a pure-function 2D simulator across seeded perturbations, then comparing the executed path to a hidden reference | **Yes** — same `(world, plan, seed)` always yields the same output; the PRNG is a local `mulberry32` seeded explicitly, with no `Date.now()` and no `Math.random()` | No — a plan that does not execute scores zero, and the reference never reaches the client |
| **Text rubric / LLM** | non-trajectory missions, and as an LLM fallback | keyword/structure matching over the answer text, or an LLM call | Keyword path: yes. LLM path: no | **Yes** — the rubric is reverse-engineerable; see the red-team write-up |

All 483 records in the published traction dataset are on the **simulator**
path (`mode: "sim"`).

## 2. Verifiability levels

We grade our own claims against three levels:

**L0 — Trust.** "We scored it correctly." Requires trusting the operator.
The text-rubric path is L0. It must never gate a payment.

**L1 — Commitment (where the protocol sits today).** The evaluator publishes
hashes and signs them. A third party can:

- recompute `planHash` and `resultHash` from a published plan and result object
  using the canonical serialization in `settlement-spec.md` §3–§4;
- confirm the signature recovers the expected evaluator address;
- confirm the on-chain record matches the published artifact.

This proves *who claimed what, immutably*. It does **not** prove the claim is
true — the hidden reference trajectory is not published, so the alignment
score cannot be independently recomputed.

**L2 — Independent recompute.** A third party reruns the scorer themselves and
gets the same number. Executability on the simulator path already reaches L2 in
principle, **but the simulator source and the task manifest are not published
in this repository**, so in practice it is still L1 for an outside reviewer.

## 3. The trade-off we made, stated plainly

The reference trajectory is hidden so the rubric cannot be reverse-engineered
from the client (or from the published dataset — note `missionBrief` is `null`
in every collected record). That is a deliberate anti-gaming choice, and its
cost is exactly the verifiability above: **we bought un-gameability with
verifiability.**

We think that trade is correct for a live adversarial environment, but it is a
real cost and it must be disclosed rather than glossed. A reviewer who asks
"can I check your alignment score myself?" gets the honest answer: not today.

## 4. Proposal: publish what can be published

The following change would move the simulator path to genuine L2 without
revealing the references:

1. **Publish the simulator** (the deterministic simulator, the scorer, and the
   PRNG) in a public repository under the same MIT license.
2. **Publish a task manifest** containing, per task: `taskId`, the world state,
   the perturbation seeds, and `keccak256(referenceTrajectory)` — the *hash* of
   the reference, never the reference itself.
3. **Publish a runner** that, given a submitted plan and the manifest, produces
   the executability score and the alignment score, plus the derived
   `planHash` / `resultHash`.
4. **Assert reproducibility in CI**: for N pinned task/plan pairs, the runner
   must reproduce the exact published scores. Any drift fails CI.

What that buys:

- An outside party can **recompute executability** exactly — it is a pure
  function of published inputs.
- An outside party can **verify the commitment**: the hash of the reference the
  scorer used must equal the hash in the manifest. They still cannot *see* the
  reference, so they cannot cheaply reverse-engineer it, but they can now prove
  the scorer used the same reference it always used, and that no scoring run
  silently swapped it.
- A disputed score becomes an *auditable artifact* rather than a private claim:
  the parties compare the published plan, the recomputed hashes, and the
  recorded on-chain values.

What it does **not** buy: protection against a colluding evaluator who publishes
a manifest whose hidden reference was wrong from the start. That residual trust
is irreducible in this design — and it is precisely why the protocol never lets
an evaluator move funds (`settlement-spec.md` §1).

## 5. Why this matters to the settlement layer

`EvaluationEscrow.release()` requires **both** an evaluator attestation and a
payer authorization. An evaluator who scores dishonestly still cannot pay
themselves: the payer must separately authorize that exact `resultHash`. The
verifiability gap above therefore degrades *fairness* (a provider could be
under-scored and lose a job) but not *custody* (no key can drain the escrow).

That is the design reason the evidence/authorization split exists, and it is
also why this document can be honest about being at L1 without the project being
unfundable: the gap is a fairness risk the payer controls, not a solvency risk
the protocol fails to contain.

## 6. Current status

| Item | Status |
|---|---|
| Simulator path is deterministic by construction | **True** — verified by code and by `mode: "sim"` across all 483 records |
| Third parties can recompute executability today | **No** — the simulator is not published in this repository |
| Third parties can verify hash commitments today | **Yes** — `settlement-spec.md` §3–§4, and the dataset pins every record |
| Publishing simulator + task manifest (L2) | **Proposed, not done** — a post-grant engineering task |
| Text rubric must never gate settlement | **Adopted as policy** — see [`security/red-team-findings.md`](../security/red-team-findings.md) |

