# Circle Developer Grants — Portal Submission Pack

**Paste-ready answers, organized by the portal's known information categories.**
Everything below is final — no placeholders. Source of truth:
`circle-developer-grant-draft.md` (v5), `canonical-fact-sheet.md`,
`traction-highlights.md`.

**Submission date: 2026-09-20. M3 product: Circle Agent Stack (decided).**

---

## 1. Project / DBA name

StonkRobotics (protocol name: Robot Policy Network)

## 2. One-line summary

The trust and settlement layer for the machine economy on Arc: a system where
autonomous agents do verifiable work and get paid in USDC — with evaluation
evidence and payment authorization cryptographically separated so no score can
ever move money by itself.

## 3. What are you building? (the problem and the product)

Arc's first priority use case is agentic economic activity. But there is a
missing primitive at the center of that ambition: **how does a machine get paid
for work without a human trusting the machine's word?**

Agent-payment tools let agents spend USDC on a human's behalf — the human still
decides. Escrow and oracle designs treat an unverified score as a payment
instruction — a manipulated result moves money. Neither produces what a machine
economy needs: **a payment triggered by proof of work, not by a claim of work,
at machine cadence.**

StonkRobotics closes this with a hard cryptographic split:

- The **evaluator** signs an `EvaluationAttestation`: "this plan scored X
  against task T." **Cannot move funds.**
- The **payer** signs a `ReleaseAuthorization`: "pay this provider this amount
  for this result." **Insufficient alone.**
- `release()` requires **both**. Neither key can settle a job by itself.

The evaluation side is execution-anchored: agents submit structured action
plans for tasks sliced from real robot trajectories (DROID dataset), and a
deterministic simulator executes them across seeded perturbations. A plan that
doesn't run scores zero. Passing and failing populations are separated by
90.8 points (pass mean 95.8, fail mean 5.0, median 0).

## 4. What is live today? (traction and evidence)

- **Evaluation + on-chain recording: live on Arc mainnet** since launch
  (contract `0x6a3B12532F8e562f99e3292380e7f69D32e10B32`, chain 5042).
- **65,138 scored evaluation rounds from 217 unique wallets** across 67 real
  robot trajectory tasks in 5 days (14,027 / 11,247 / 13,812 / 22,086 / 3,966
  daily), ongoing. Every record is published with SHA-256 pins and a
  re-runnable verifier: `docs/grants/traction-evidence/`.
- **Settlement contract deployed on Arc mainnet**:
  `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491` (SPEC_VERSION 2). A **complete
  settlement has executed** — 0.5 USDC escrowed, evaluator attestation
  recorded, USDC released after the payer's separate authorization validated.
  Transaction hashes in `deployments/arc-mainnet-settlement.json`.
- **Arc mainnet mints: 60** (`totalMinted()` on the fleet contract).
- **85 Foundry tests passing**; CI proves the deploy path and runs a full
  settlement on every push.
- Frozen specification: `docs/settlement-spec.md` (SPEC_VERSION 2).

## 5. Why Arc and why Circle

Built for the program's first stated priority: **agentic economic activity**,
with Arc core to the flow of value and settlement.

- Arc-native USDC (ERC-20 interface, 6 decimals) is the settlement asset; the
  protocol follows Arc's own ERC-20-only integration guidance.
- **Circle Agent Stack integration is a funded milestone (M3)**: agents in the
  workflow will operate with Circle-native agent payment capabilities.
- The evidence/authorization split is purpose-built for agentic payments:
  neither key alone can settle a job.
- The Arc node natively handles USDC's compliance precompile
  (`0x1800…0001::isBlocklisted`) inside transferFrom — documented in
  `docs/arc-integration-notes.md` (forge's local simulation cannot; real
  transactions can).

## 6. Proposed milestones

| # | Milestone | Funder | Due | Budget |
|---|---|---|---|---|
| M1 | Deploy `EvaluationEscrow` to Arc mainnet | founder | COMPLETE 2026-09-20 | $0 |
| M2 | One end-to-end settlement on mainnet | founder | COMPLETE 2026-09-20 | $0 |
| M3 | Circle Agent Stack integration | **this grant** | 2026-11-22 | **$8,000** |
| M4 | Independent security review, report published | **this grant** | 2026-12-20 | **$5,000** |

**Total ask: $13,000** = M3 + M4 exactly. M1 and M2 were completed on founder
funds before any award and are **not billed** — no retroactive reimbursement.
Post-grant roadmap (not funded): M5 third-party-reproducible evaluation,
M6 production instance under a fresh owner key. Single source of truth:
`MILESTONES-CANONICAL.md`.

## 7. Success metrics (conditional on award)

- 100 verified agent outcomes/month by 2026-12-31.
- 25 end-to-end USDC settlements by 2027-01-31.
- 5 unique paying counterparties by 2027-01-31 (via M3 Agent Stack channel).
- 100% of settlements backed by an on-chain verifiable attestation.

## 8. Team

- **Richard**, solo founder.
- Prior: **AI2Human Network** (`ai2human.work`) — verification layer for
  open-world AI agents. GitHub `ai2humannetwork` (6 repos incl. Base
  settlement contracts). **2nd prize, X Layer (OKX) hackathon** —
  https://x.com/ai2humannetwork/status/2071909716704293211
- Entity: individual, DBA "StonkRobotics"; Legal Entity Name: N/A.
- Email: richard@stonkrobotics.xyz

## 9. Links

- Website: https://stonkrobotics.xyz/
- Agent workflow: https://stonkrobotics.xyz/skill/
- Repo: https://github.com/robot-policy-network/robot-policy-network
- Evaluation contract: https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32
- Settlement contract: 0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491

## 10. Honest limitations

- No independent audit. 85 tests + CI deploy/settlement proof are interim.
- One settlement executed (founder-funded, 0.5 USDC). Not volume.
- Scoring is off-chain deterministic; on-chain recording via vouchers.
- Marketplace is roadmap. ARCROBO token and NFT collection are separate
  subsystems, not part of this proposal.

