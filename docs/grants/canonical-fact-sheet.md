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
| `EvaluationEscrow` v1 spec frozen (`SPEC_VERSION = 1`), 81 passing Foundry tests | `docs/settlement-spec.md`, `forge test` in CI |
| Evaluation evidence and payment authorization are separate EIP-712 artifacts | `docs/settlement-spec.md` §1 |

## Founder-confirmed (not independently verifiable; user must reconfirm before use)

| Fact | Status |
|---|---|
| Applicant / project lead identity: **Richard** | CONFIRMED 2026-09-20 |
| Applicant email: **ritsuyan4763@gmail.com** | CONFIRMED 2026-09-20 |
| Grant ask: **$25,000 over ~12 weeks** (founder delegated sizing) | CONFIRMED 2026-09-20 |
| Milestones: fast schedule, M1–M4 from 2026-10-11 to 2026-12-13 | CONFIRMED 2026-09-20 |
| Legal entity: none; apply as individual, DBA "StonkRobotics" | Assumed per plan — final confirm before signing |
| Circle product for M3: Circle Agent Stack (recommended) | Recommended — confirm or swap before submission |
| No conflict of interest with Circle/Arc teams | NEEDS CONFIRMATION |
| Authorization to use project name, logo, screenshots publicly | NEEDS CONFIRMATION |

## Planned (roadmap only — never present as live)

- General-purpose USDC job escrow and milestone-based settlement on Arc.
- `EvaluationEscrow` deployment to Arc mainnet (spec frozen, not deployed).
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
