# Research & Positioning Memo — 2026-09-20

All claims below verified against primary sources on 2026-09-20. Citations inline.
This memo is the evidence base for the project narrative; the fact sheet governs
what may be claimed in applications.

---

## 1. Academic consensus: the bottleneck moved from collection to curation

**SIEVE** (arXiv:2607.06442, Jul 2026): "More data does not necessarily yield
better policies due to redundancy, noise, and uneven coverage." Their
structure-aware selection (visuo-motor primitives + transition interfaces)
**surpasses full-data training using only 50% of demonstrations and 50% of
training steps**. This is direct experimental proof of "more data ≠ better
policy."

**ATHENA** (arXiv 2604.15546, Apr 2026): treats curation as **active learning
with a world-model scorer** — an external model ranks which trajectories are
worth training on. Validation of an external-scorer curation layer.

**RoboDrop** (arXiv 2511.13406, Nov 2025): filter imperfect demonstrations,
keep only high-performing ones. Raw imitation data is polluted.

**DROID** (Khazatsky et al., RSS 2024 Best Paper; arXiv 2403.12945): 76,000
demonstration trajectories across 564 scenes, collected by a distributed
fleet — raw data at scale is **already open and abundant**.

**Open X-Embodiment** (2023): 1M+ episodes pooled across embodiments. The
collection layer is commoditized.

**Established curation machinery we can cite:** Dawid–Skene consensus
aggregation (1979), Query-by-Committee active learning, CoT reasoning-trace
distillation (DeepSeek-R1 style).

## 2. Industrial landscape: collection is funded, curation+settlement is open

| Player | Raise | Layer | Key gap vs us |
|---|---|---|---|
| **Axis Robotics** | $12M seed, Hack VC (Jul 2026) | **Collection engine**: large-scale sim + egocentric capture + human-in-the-loop post-training | No verification protocol, no settlement, no committee scoring |
| **PrismaX** | $11M, a16z CSX (Jun 2025) | **Collection + teleop + models** flywheel; aims to define teleop standard ("ERC-20 moment for teleoperation") | Incentive structure for *collecting* data; scoring is internal, not on-chain verifiable |
| **RoboTrain** (Virtuals Protocol) | Virtuals launch (May 2026) | **Queued teleop sessions with human verification scoring** (16-member team grades for CLIP/VLM training data) | Explicitly **no crypto settlement** ("product first, token later"); centralized grading, no reproducible deterministic evaluator, no EIP-712 evidence/authorization split |

Adjacent crypto-AI infrastructure: **GAEA, Oasis, PublicAI** (training-data
DePIN marketplaces), **Vana** (data DAOs), **Fraction AI** (AI-agent
competition, $6M). All operate at collection or generic data-DAO layer; none
anchors scoring to real robot trajectories with a deterministic simulator and
an on-chain evidence/authorization payment split.

## 3. Our differentiated position (what is actually true in the code)

Three layers, each defensible:

1. **Deterministic evaluation anchored to real robot trajectories** — `_sim.js`
   is a pure-function 2D end-effector simulator (mulberry32-seeded
   perturbations, same input → same output); `_missions_traj_real.ndjson`
   holds **82 tasks sliced from DROID episodes** with hidden reference
   trajectories that never reach the client. Executability cannot be bluffed;
   the rubric cannot be reverse-engineered. **This is live.**
2. **On-chain verifiable records** — EIP-712 vouchers, nonce replay
   protection, domain-separated from the settlement contract. **Live on Arc
   mainnet (chain 5042).**
3. **Evidence/authorization-split USDC settlement** — `EvaluationEscrow`
   (frozen SPEC_VERSION 1, 81 tests): an `EvaluationAttestation` can never
   move funds; a `ReleaseAuthorization` alone is insufficient; `release()`
   requires both. **Specified + tested, not yet deployed.**

## 4. The narrative: the curation + settlement layer for Physical AI

> Collection is funded and commoditized (DROID, OXE, Axis, PrismaX).
> Academia proved the bottleneck is curation (SIEVE: 50% data beats 100%).
> RoboTrain validates scoring-as-product but is centralized and payment-free.
> **Nobody occupies the intersection: verifiable agent evaluation → curated
> robot-training data → trustless USDC settlement.**

Flywheel: agent committee answers tasks anchored to real trajectories →
deterministic reproducible scoring → on-chain verified records → three
derived data assets (consensus labels, hard cases, reasoning traces) →
verified outcomes trigger milestone USDC release → better data attracts
better agents.

## 5. Honesty boundaries (must hold in every application)

- Live: deterministic eval, 82 DROID-anchored tasks, EIP-712 on-chain
  verification, NFT mint path.
- Planned: consensus aggregation at scale, hard-case mining export,
  reasoning-trace dataset, EvaluationEscrow mainnet deployment.
- Never claim: live data marketplace, commercial dataset sales, Circle/Arc
  endorsement, audit, RoboTrain/Axis/PrismaX partnership.

## Sources

- SIEVE: https://arxiv.org/abs/2607.06442
- ATHENA: https://arxiv.org/abs/2604.15546
- RoboDrop: https://arxiv.org/abs/2511.13406
- DROID: https://arxiv.org/abs/2403.12945
- Axis $12M: https://axisrobotics.ai/blogs/blog/axis-raises-12m-seed-round-to-build-the-data-engine-for-physical-ai
- PrismaX $11M: https://www.prismax.ai/blog/prismax-raises-11m-a16z-robotics-funding
- RoboTrain: https://app.virtuals.io/acp-ai/robotrain + https://www.robotronica.info/en/news/robotics-en/2982-robotrain-launches-on-virtuals-protocol-to-build-decentralized-robot-training-network.html
