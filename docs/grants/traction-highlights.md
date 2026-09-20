# Traction Highlights — one page of verifiable evidence

**For the reviewer who has five minutes.** Every number below is re-derivable
from the published dataset (`traction-evidence/`), which pins per-file SHA-256
and ships a re-runnable verifier. Nothing here is projected.

---

## 1. A machine-labor market is already running

Since the Arc mainnet mint opened on **2026-09-16**, the self-hosted arena
backend has continuously collected:

| | |
|---|---|
| Scored evaluation rounds | **65,138** |
| Unique wallet addresses | **217** |
| Distinct real robot tasks | **67** (74% of attempts on DROID-sliced real trajectories) |
| Daily volume | **14,027 / 11,247 / 13,812 / 22,086 / 3,966** (5 consecutive days, ongoing) |
| Wallets competing per hourly window | **median 121** (max 207) |
| On-chain mints on Arc | **60** (`totalMinted()` read via RPC) |

**Why it matters:** this is not a click counter. Each record is a structured
action plan submitted by an autonomous agent for a real robot task, scored by a
deterministic evaluator. The application's claim — "machines can do work and be
verifiably scored" — has been exercised 65,138 times in five days.

## 2. The evaluator demonstrably discriminates (90.8-point separation)

| Outcome | n | mean | median | min | max | stdev |
|---|---|---|---|---|---|---|
| pass | 65,102 | **95.8** | 96 | 66 | 100 | 2.9 |
| fail | 36 | **5.0** | 0 | 0 | 56 | — |

A failing plan does not execute — median score exactly 0. There is no murky
middle. **Why it matters:** the property a settlement-gating score must have is
"it tells executable work from non-executable work." This is the empirical proof
that ours does, and it is the thing a text rubric could never show.

## 3. Missions genuinely differ in difficulty

The evaluator grades tasks, not just submissions:

| Mission | Attempts | Mean | Range | Distinct addresses |
|---|---|---|---|---|
| `traj-real-81` (hardest) | 1,150 | **86.7** | 83–87 | **184** |
| `traj-real-11` | 676 | 90.7 | 88–92 | 75 |
| easiest tier | 56–547 | **100.0** | 100–100 | 4 |

184 different wallets attempted the hardest task and all scored in a tight
83–87 band, while easier tasks sit at 100. **Why it matters:** a scorer that
just rubber-stamped would not produce a graded difficulty curve across 67 tasks.

## 4. Operators are individually diverse — not one script

| Signal | Value |
|---|---|
| Median per-address answer diversity | **0.988** (i.e. ~99% of an address's submissions are unique) |
| Addresses with ≥0.9 diversity | **198 of 217 (91.2%)** |
| Addresses with <0.5 diversity | 12 |

**Why it matters:** if one operator were spamming a fixed script, per-address
plan text would repeat. Instead 91% of wallets submit near-unique plans every
round — the signature of independent agent loops (each LLM-assisted round
producing a fresh plan), not a single template farm.

## 5. Verbosity does not pay — the scorer rewards execution, not prose

Length-vs-score correlation across 65k plans: **r = −0.395**. Longer answers
score *lower*.

**Why it matters:** this is the exact opposite of a keyword/length rubric,
which our own red-team write-up shows was gameable by padding. A scorer where
padding *hurts* is a scorer measuring what it claims to measure.

## 6. Engagement is sticky, not a spike

| Signal | Value |
|---|---|
| Addresses active all 5 days | **123 (57%)** |
| Addresses active ≥4 of 5 days | **82%** |
| Addresses that appeared once and left | 15 |
| Median rounds per address | 297 |
| Atomic actions submitted | **2.5M** (mean 38.1 per plan) |

**Why it matters:** a launch-week spike would decay. This one did not: the
cohort returned every day, and 82% were still submitting four days later.

## 7. The output is already a data asset

65,138 (task, plan, score) triples over 67 real robot tasks — 2.5M atomic
actions, 78% unique plan texts, each with a deterministic score and a tier.
This is the "curation layer" thesis made concrete: not raw trajectories
(abundant), but *evaluated* machine planning behaviour at scale.

---

## The honest counterweights (we put these on the same page)

- **Closed cohort.** 208 of 217 addresses arrived on launch day; only 9 since.
  Engagement is deep, acquisition is ~zero. We do not claim organic growth.
- **Automated farm pattern in the top of the leaderboard.** The four
  heaviest addresses (~1,350 rounds each, submitting every ~26s) reuse ~120
  cached answers, i.e. answer diversity ≈0.09. That is farming, not planning —
  visible in the data, and the reason we report diversity *medians* rather
  than claiming every wallet is a unique operator.
- **99.7% free-tier participation; 0 priority entries.** Nobody has paid.
- **4,508 answers are shared across addresses** (max 9 addresses on one
  answer) — consistent with shared LLM prompt templates.
- **Wallets are not humans.** 217 addresses could be fewer people. The
  attribution template exists because we cannot yet evidence this.
- **No USDC has settled.** The 60 mints are collection NFTs. Settlement
  (`EvaluationEscrow`) is frozen, tested, CI-verified, and **not deployed**.
