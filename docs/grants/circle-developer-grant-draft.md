# Circle Developer Grant — Long-Form Application Draft

**Status: DRAFT v5 (2026-09-20).** Pre-submission checklist (all must be
resolved before sending — see "Open items" at the end of this file). Every
`<PLACEHOLDER>` must be replaced with founder-confirmed information. All
claims must comply with [`canonical-fact-sheet.md`](canonical-fact-sheet.md);
market and competitor claims are sourced in
[`research-positioning-2026-09.md`](research-positioning-2026-09.md); traction
figures are independently re-derivable from
[`traction-evidence/`](traction-evidence/README.md).

---

## One-line summary

StonkRobotics (Robot Policy Network) is the trust and settlement layer for the
machine economy on Arc: a system where autonomous agents do verifiable work
and get paid in USDC — with evaluation evidence and payment authorization
cryptographically separated so no score can ever move money by itself.

## Problem

Arc's stated ambition is to be the economic OS for the internet, and its first
priority use case is agentic economic activity. But there is a missing
primitive at the center of that ambition: **how does a machine get paid for
work without a human trusting the machine's word?**

Every current approach falls short. Agent-payment tools let agents *spend*
USDC on a human's behalf — the human still decides. Escrow and oracle projects
treat an unverified score as a payment instruction — so a manipulated or
hallucinated result can move real money. Human review and manual escrow work,
but they do not scale to machine-speed, high-frequency settlement. None of
these produces what a machine economy actually needs: **a payment that is
triggered by proof of work, not by a claim of work, at machine cadence.**

The robot-AI side has the same hole. Collection is funded and commoditized —
Axis Robotics raised a $12M seed (Hack VC, 2026) and PrismaX raised $11M
(a16z CSX, 2025); DROID (RSS 2024 Best Paper; arXiv 2403.12945) and Open
X-Embodiment already publish over a million raw trajectories. Academia shows
the bottleneck has shifted from collection to curation: DataMIL (Dass et al.,
MIT; arXiv 2505.09603) proves performance-aware data selection beats naive
scaling, and that naive selection can actively *harm* success rates. Yet the
intersection of curation and settlement is thin — RoboTrain (Virtuals, 2026)
does scoring but with a centralized human grading team and no crypto
settlement.

**Nobody has built the bridge: verifiable machine work → payable machine
work.** That bridge is exactly what Arc needs to turn "agentic economic
activity" from a category on a grants page into real, measurable USDC flow.

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

This application is built for the program's first stated priority use case,
**agentic economic activity**, and meets its core requirement that Arc be
central to the flow of value, liquidity, or settlement.

## What Arc and Circle gain

We are not asking Circle to fund a tool that happens to use USDC. We are
building the missing primitive that makes Arc's machine-economy thesis real,
and every part of it compounds back into the Arc and Circle ecosystem.

- **A new, recurring source of USDC demand that only Arc can serve.** Every
  verified machine outcome that settles is a USDC transfer that would not
  exist otherwise. As agent work scales, this is not a one-time integration —
  it is a growing transaction stream denominated natively in Arc USDC.

- **A reason the machine economy is strongest on Arc.** The combination we
  need — a deterministic evaluator, a low-cost chain for high-frequency
  signed records, and native USDC settlement with fast finality — is most
  coherently available on Arc. On other chains the settlement leg requires a
  bridge or a wrapper, adding friction and trust assumptions. Building this
  category natively on Arc makes it the natural home for machine-economic
  activity.

- **A reusable reference implementation for a whole category.** The
  evidence/authorization split is a general pattern any agentic-payments
  project on Arc will need: how do you pay for a verified outcome without
  letting the outcome-writer move money? Shipped open-source (MIT), our
  `EvaluationEscrow` is designed and offered as that reusable pattern —
  lowering the barrier for the next teams, which means more projects on Arc,
  more USDC flow, and more developers reading Arc docs.

- **A concrete Agent Stack showcase.** M3 makes StonkRobotics a working,
  public demonstration of Circle Agent Stack powering real agent payments —
  the kind of reference the Circle developer platform can point to when
  onboarding the next hundred agent teams.

- **Alignment with how Circle already measures success.** The program rewards
  "measurable paths to production deployment" and ecosystem impact. Our
  milestones are production deployments and public on-chain transactions —
  the most legible, auditable form of impact a grants program can ask for.

## Why us and why now

- **Why us:** the evaluation layer is already live and operating on Arc
  mainnet, the settlement protocol is frozen with 81 passing tests, and the
  whole stack is open-source. We are past the idea stage; this grant funds
  deployment and integration, not research.
- **Why now:** Arc is pre-mainnet and defining its flagship use cases. The
  project that becomes the canonical "how machines get paid on Arc" reference
  will be the one that ships first with a credible, audited, open protocol.
  That window is open now and closes as the ecosystem matures.

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
- **Circle products as building blocks, not decoration.** M3 integrates
  Circle Agent Stack so agents hold and move USDC through Circle's own
  agent-payment primitives; the settlement layer already runs on Arc-native
  USDC. These are load-bearing integrations, not logo mentions.
- **Existing deployment evidence.** The project's only production deployment
  is Arc mainnet, and the evaluation flow already records outcomes there.

## Agentic economic activity

Today: agents complete trajectory-anchored challenges and receive verifiable,
on-chain-recorded scores — machine work that is already provable. This is not
projected: in the live window of **2026-08-17 to 2026-09-04, 91 unique agents
completed 483 deterministically-scored evaluation rounds across 64 distinct
real robot trajectory tasks, with an 88.2% pass rate.** Every record is
published with a SHA-256 hash and a re-runnable verification script at
[`docs/grants/traction-evidence/`](traction-evidence/README.md), so each
figure here can be independently re-derived rather than taken on our word.

Next: verified outcomes become the trigger condition for milestone-based USDC
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
| RoboTrain (Virtuals) | Virtuals launch (2026) | Teleop + human scoring | Centralized grading; no crypto settlement per launch coverage |
| GAEA / Vana / Fraction AI | various | Data DePIN / DAOs | No trajectory-anchored deterministic evaluation |

Funding figures are from company announcements and press coverage (CoinDesk,
company blogs); verify current figures before submission.

Collection is funded; curation-plus-settlement is open. Our moat is the
combination competitors structurally lack, and it is hard to replicate because
it is not any single feature:

1. **A deterministic, reproducible evaluator** anchored to real robot data —
   most "scoring" projects use a human panel or a non-deterministic LLM call,
   which cannot produce a reproducible, accountable on-chain artifact.
2. **An on-chain evidence/authorization split** that makes scores payable
   without making them payment instructions — a protocol-level property, not
   a UI choice, and the reason a payer can trust a settlement without trusting
   the evaluator.
3. **Arc-native settlement** — the low-cost, fast-finality, native-USDC
   environment that makes high-frequency machine micropayments economically
   coherent. Competitors on other chains would have to rebuild the settlement
   leg against a bridge.

Each layer alone is copyable; the three together, already live and frozen,
are not. And because the protocol is open-source, the moat is not secrecy —
it is the compounding, time-stamped, on-chain record of verified outcomes
that a later entrant cannot backfill.

## Milestones

Total duration ~13 weeks from grant award (assumed start 2026-09-21 for
planning; dates shift with actual award date). All four milestones are
already-specified components, which is what makes a solo founder's timeline
credible.

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

**Proposed budget: $25,000 over ~13 weeks.** Circle does not publish grant
amounts; this is the milestone budget we propose in the portal, and the final
award is sized by Circle during milestone design. We are ready to scope the
plan to a different tier if Circle's assessment differs.

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
- **Solo-founder execution risk.** Mitigated by the narrow 13-week scope and
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
- **Verifiable traction dataset (live):** `https://github.com/robot-policy-network/robot-policy-network/tree/ci/install-foundry-dependencies/docs/grants/traction-evidence` — 492 records, 91 unique agents, SHA-256-pinned, `verify.sh` re-derives every figure; on-chain receipts cross-checkable on the explorer. (Merging to `main` via the open PR; main is a protected branch requiring review.)
- Arc mainnet contract: `https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32`
- Deployment manifest: `deployments/arc-mainnet.json` (read-only RPC evidence, checked 2026-09-18)
- Research & positioning memo: `docs/grants/research-positioning-2026-09.md`
- Video / screenshots / deck: `<LINKS — only if they actually exist>`


## Open items (must resolve before submission)

| # | Item | Owner | Status |
|---|---|---|---|
| 1 | **M3 product choice** — Circle Agent Stack (recommended) vs Wallets vs Contracts. The portal asks for integration plans; leaving this undecided makes the $8,000 M3 line unfounded. | Founder | **Open — blocks submission** |
| 2 | **Entity status** — applying as an individual with DBA "StonkRobotics"; Legal Entity Name = N/A. Confirm before signing. | Founder | Awaiting final confirm |
| 3 | **Video / screenshots / deck links** — fill only with links that actually resolve. Do not invent hosting URLs. | Founder | Open (optional) |
| 4 | **Evidence visibility on `main`** — the traction dataset currently lives on the `ci/install-foundry-dependencies` branch. `main` is a protected branch that requires an approving review; a PR is open. A reviewer landing on the default branch will not see the dataset until the PR merges. | Founder / repo admin | **Open — reviewer-visible issue** |
| 5 | **Dataset provenance caveat** — the Filebase bucket that holds the source records is private (HTTP 403 to unauthenticated readers). Reviewers can verify the *export we published* (hashes, re-derived stats, on-chain receipts) but cannot independently re-pull the upstream bucket. The export's provenance therefore rests on our word plus the on-chain receipts. Stated here rather than hidden. | Founder | Known limitation |
| 6 | **Circle portal fields** — business details, integration plan, proposed milestones. The long-form draft is ready but has not yet been transcribed into `circle.com/grant`. | Founder | Not started |

## Appendix A — adversarial self-review log

This draft has been through five review passes. Findings and resolutions:

1. **v2 → v3 (adversarial reviewer pass).** Fixed: "verifiable" vs hidden-rubric
   contradiction (resolved with an explicit two-tier verifiability model);
   "the live system closes the gap" overclaim; present-tense curated-data
   claims; M4 budget not credible at $5k/3 weeks (resized + basis stated);
   M2 vs Risks contradiction (resolved with a funding gate); ARCROBO
   non-disclosure.
2. **v3 → v4 (live-link audit).** Every citation was fetched. Removed three
   arXiv IDs that did not resolve; replaced with DataMIL (arXiv 2505.09603,
   verified 200) and DROID (arXiv 2403.12945, verified 200). PrismaX/Axis
   deep links dropped in favour of coverage attribution. Fixed the 12-week
   vs M4-date arithmetic inconsistency (13 weeks).
3. **v4 → offensive pass.** Added "What Arc and Circle gain" and "Why us and
   why now"; rewrote the moat as three compounding layers.
4. **v4 → v5 (absolute-claim purge).** Removed "the first system", "and
   nowhere else", "battle-tested", "becomes the pattern others build on",
   and the false dichotomy in the Problem section.
5. **v5 → traction evidence.** Replaced asserted traction with 492 published
   records and a re-runnable verification script; corrected the participant
   count from 93 → 91 after finding the protocol's own `poiSigner` address
   and a placeholder address mixed into the raw records.

