# Canonical Fact Sheet

**Purpose.** This is the single source of truth for every external application
(grants, hackathons, accelerators, investor materials). Every claim used in an
application must trace back to a row in this file. Nothing marked `Planned` or
`Do not claim` may be presented as existing.

_Last updated: 2026-09-20._

## Verified (public evidence exists)

| Fact | Evidence |
|---|---|
| Project name: StonkRobotics / Robot Policy Network | Public website and repository |
| Website: `https://stonkrobotics.xyz/` | Live site |
| Agent workflow: `https://stonkrobotics.xyz/skill/` | Live site |
| Repository: `https://github.com/robot-policy-network/robot-policy-network` | Public repo |
| Network: Arc mainnet, Chain ID `5042` | `deployments/arc-mainnet.json` |
| Fleet contract: `0x6a3B12532F8e562f99e3292380e7f69D32e10B32` | Arc explorer, read-only RPC check 2026-09-18 |
| ARCROBO token: `0x90554cEaf18BD5545F4be6520a3077D327727297` | Arc explorer |
| Arc-native USDC address: `0x3600000000000000000000000000000000000000` | `deployments/arc-mainnet.json` |
| Live flow: challenge → mission plan → reproducible score → EIP-712 voucher → on-chain verification/recording | Contract source + live workflow |
| `EvaluationEscrow` v2 spec frozen (`SPEC_VERSION = 2`), 85 passing Foundry tests | `docs/settlement-spec.md`, `forge test` in CI |
| Evaluation evidence and payment authorization are separate EIP-712 artifacts | `docs/settlement-spec.md` §1 |
| Live production traction: 65,138 scored evaluation rounds from 217 unique wallets across 67 missions, ongoing since mainnet launch (2026-09-16); 100% deterministic scoring; Arc mainnet `totalMinted() = 60` | `docs/grants/traction-evidence/` (SHA-256-pinned export + `verify.sh`); RPC read 2026-09-20. Note: 217 addresses = wallets, not humans; provenance operator-attested |
| Canonical serializer published in-repo with pinned vectors (`references/canonical.js`) | `node references/canonical.test.mjs` — ALL VECTORS PASS; CI |

## Founder-confirmed (not independently verifiable; user must reconfirm before use)

| Fact | Status |
|---|---|
| Applicant / project lead identity: **Richard** | CONFIRMED 2026-09-20 |
| Applicant email: **ritsuyan4763@gmail.com** | CONFIRMED 2026-09-20 |
| **Founder track record — AI2Human Network** (prior/parallel project, same founder): GitHub org `ai2humannetwork` (created 2026-06-27, bio: "The execution and verification layer for the agent economy"), 6 public repos incl. Base settlement contracts, proof-kit, protocol specs, agent skills | **VERIFIED 2026-09-20 via GitHub API** |
| **Founder track record — AI2Human live product**: `https://ai2human.work/` (verification layer for open-world AI agents; proof → review → conditional USDC settlement; whitepaper + live demo) | **VERIFIED 2026-09-20 (HTTP 200)** |
| **X Layer (OKX) hackathon — 2nd prize (AI2Human)** | **VERIFIED 2026-09-20** — public post from official account @ai2humannetwork: https://x.com/ai2humannetwork/status/2071909716704293211 (states: "As an @XLayerOfficial hackathon 2nd prize winner…")
| Grant ask: **$13,000** = M3 ($8,000 Circle Agent Stack integration) + M4 ($5,000 independent security review). M1/M2 completed on founder funds and not billed. `MILESTONES-CANONICAL.md` is the single source | CONFIRMED 2026-09-20 |
| Milestones: fast schedule, M1–M4 from 2026-10-11 to 2026-12-13 | CONFIRMED 2026-09-20 |
| Legal entity: none; apply as individual, DBA "StonkRobotics" | Assumed per plan — final confirm before signing |
| Circle product for M3: Circle Agent Stack (recommended) | Recommended — confirm or swap before submission |
| No conflict of interest with Circle/Arc teams | NEEDS CONFIRMATION |
| Authorization to use project name, logo, screenshots publicly | NEEDS CONFIRMATION |

## Planned (roadmap only — never present as live)

- General-purpose USDC job escrow and milestone-based settlement on Arc.
- Post-grant: production instance under a fresh owner key (M6) and third-party-reproducible evaluation (M5).
- Note: the demo deployment at 0x479F... is founder-funded, its owner key must be
  treated as compromised, and it is retired by M6. See MILESTONES-CANONICAL.md.
- Provider/robot-policy marketplace.
- Integration of Circle products (Agent Stack, Wallets, or Contracts — exact
  selection must match the milestone plan before it is claimed).

## Do not claim

- Any independent security audit (none has been conducted; answer
  `N/A — no independent audit has been conducted` if asked).
- Current revenue, transaction volume, user counts, or partner names not
  supplied by the founder.
- Circle or Arc sponsorship, endorsement, or partnership.
- Byte-for-byte reproducibility of the deployed bytecode from this repository.
- An established "Arc Builders Fund" fund or fixed amount — the public page
  describes a Circle Ventures internal initiative, not a funding commitment.
