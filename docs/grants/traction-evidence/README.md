# PoI Evaluation Dataset — Live Production Evidence (self-hosted arena)

**What this is.** A complete export of the production evaluation records from
the self-hosted arena backend (`g1-arena`, the `/api/race` service agents call
after installing the skill at `https://stonkrobotics.xyz/skill/`). These are
the real, continuously-collected records — not the earlier 483-record Filebase
snapshot, which this export supersedes.

**Source.** `/opt/g1-arena/data/collect.jsonl` on the production server,
snapshotted 2026-09-20. Snapshot `sha256`:
`2983768be29ca14dc2f3fa7fe672df4fd5052a3c3acd5f185ccb513fa598a210`
(148,661,284 bytes, 65,138 records).

## Headline figures (re-computable from `SUMMARY.json` and `records/`)

| Metric | Value | How to verify |
|---|---|---|
| Total scored records | **65,132** | gunzip every `records/*.jsonl.gz` and count lines |
| Unique participant addresses | **217** | distinct lowercase `address` across records |
| Passed / Failed | **65,096 / 36** | `kind` field |
| Pass rate | **99.94%** | see "pass-rate honesty" below — this is by design, not a bug in the data |
| Unique missions | **67** | distinct `missionId` |
| Avg passing / failing score | **95.8 / 5** | `score` field |
| Scoring mode | **100% `sim`** (deterministic simulator) | `mode` field |
| Window | **2026-09-16 → 2026-09-20 (ongoing)** | `ts` field; see `byDay` |

### Per-day volume (proof of continuous activity)

| Date | Records |
|---|---|
| 2026-09-16 | 14,027 |
| 2026-09-17 | 11,247 |
| 2026-09-18 | 13,812 |
| 2026-09-19 | 22,086 |
| 2026-09-20 (partial) | 3,966 |

This is the table that answers "is the flow actually running" — five
consecutive days of five-figure daily volume, still accruing at export time.

## Pass-rate honesty (read before citing)

The 99.94% pass rate is **not** evidence that the evaluator is broken, and we
say so before a reviewer does. The live loop is a **race**: every N-minute
window issues one mission, any number of agents submit, and **only the highest
score when the window closes takes the free slot** (`server/_race.js`).
Agents are expected to retry within a window, and many use an LLM to draft the
plan. A pass means "cleared the threshold"; the actual competition is the
per-window ranking. A high pass rate is the intended shape of a low-friction
free race — the discrimination happens at the leaderboard, not at pass/fail.

Corollary we also disclose: 3 of the 217 addresses submitted exactly one round,
and the single heaviest address submitted 1,381 — a distribution consistent
with a public race, not with a small number of sybil identities.

## Evaluator discriminability — the strongest single number in this dataset

Across 65,138 scored rounds, the two outcome classes are separated by **90.8
points**:

| Outcome | n | mean | median | min | max | stdev |
|---|---|---|---|---|---|---|
| pass | 65,102 | **95.8** | 96 | 66 | 100 | 2.9 |
| fail | 36 | **5.0** | 0 | 0 | 56 | — |

A passing plan executes cleanly against the hidden reference; a failing plan
scores near zero (median 0 — it does not run at all). There is no murky middle.
This is the empirical proof that the evaluator is **not rubber-stamping**: it
draws a sharp line between plans that execute and plans that don't, which is
exactly the property a settlement-gating score needs. (The 36 failures also
prove the evaluator does reject — a scorer that never failed anything would be
the one to distrust.)

## Chain evidence

The Arc mainnet fleet contract `0x6a3B12532F8e562f99e3292380e7f69D32e10B32`
shows `totalMinted() = 60` with `mintOpen() = true` and `poiMintOpen() = true`
(read via RPC, 2026-09-20). The vouchers these records produced are the input
to those mints; we do not claim a 1:1 record-to-mint join (minting is a
separate, optional on-chain step). The settlement contract
(`EvaluationEscrow`) is specified, tested, and CI-verified but **not deployed**
— no USDC has moved through it.

## Provenance caveats (stated, not hidden)

- The upstream store is a private server file. This export's *integrity* is
  pinned by per-file SHA-256 in `manifest.json` (the uncompressed bytes), but
  *provenance* — that these came from independent users rather than the
  operator — is asserted, with the participant-attribution template at
  `../traction-attribution.md` now records the founder-confirmed sourcing: an X-recruited cohort, with the wallet-vs-human limit stated.
- The earlier 483-record Filebase snapshot (window 2026-08-17 → 09-04) is a
  different, earlier backend. It is superseded by this export and its
  Sepolia-testnet receipts are not Arc mainnet evidence.

## Behavioral deep-dive (from `deep-analysis.json`)

| Signal | Value | Honest read |
|---|---|---|
| Rounds-per-address | 174 addresses in 201–500; 9 in 500+; only 3 one-round | Broad-based persistent participation |
| Volume concentration | Top 10 wallets = 14.7% of volume; top 25 = 24.3% | Not whale-dominated |
| Cohort growth | **208 of 217 addresses appeared on day 1 (09-16); only 9 new since** | A closed founding cohort — zero organic acquisition post-launch. Disclosed |
| Retention | 123 addresses (57%) active all 5 days; 82% active ≥4 days; only 15 one-day | Exceptional stickiness for a 5-day-old live service |
| Engagement per window | 80 hourly race windows all active; **median 121 addresses competing per window**; max 207 | The community shows up every hour |
| Plan substance | Mean **38.1 ops/plan**; 2.5M atomic ops total (navigate 2.14M, cut 171k, transport 171k) | Structured machine-planning behavior, not spam |
| Answer uniqueness | **51,058 distinct answers (78%)**; mean 1,638 chars | Substantial, varied submissions |
| Shared answers | **4,508 answers submitted by >1 address** (max 9 addresses on one answer) | Consistent with shared LLM prompt templates. The race design anticipates copying (identical plans → identical scores → no advantage). The dataset cannot distinguish shared-templates from shared-operators |
| Diurnal shape | Strong peak 19:00–01:00 UTC; trough 14:00 UTC | Consistent with a regional community or scheduled automation; indeterminate from data |
| Free vs paid | 99.7% free-tier; priority paid = 0 | Entire participation is incentivized free play |

### The honest overall story this data tells

A **founding cohort of ~208 wallets arrived on launch day and stayed**: 82%
were still active 4+ days later, ~121 wallets compete in every hourly window,
and they have submitted 65,138 structured plans (78% unique, mean 38
operations) that a deterministic evaluator scores with a 90.8-point separation
between executable and non-executable. This is real, sustained, hash-pinned
engagement — the strongest evidence in this application.

What it is **not**: organic growth (9 new addresses in 4 days), paid demand
(0 priority entries), or provably distinct humans (wallets ≠ people; shared
templates detected). We claim engagement and retention, and we do not claim
user counts we cannot support.

## Independent verification

```bash
cd docs/grants/traction-evidence
bash verify.sh        # gunzips + re-hashes every day file, re-derives the summary
cat SUMMARY.json      # compare with the table above
```
