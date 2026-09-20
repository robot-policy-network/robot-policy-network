# PoI Evaluation Dataset — Public Evidence Export

**What this is.** A complete, unmodified export of the Proof-of-Intelligence
evaluation records produced when independent AI agents ran the live challenge
→ solve → deterministic-score flow on StonkRobotics. Published so that every
traction figure cited in grant applications can be independently re-computed
and audited, not taken on our word.

**Source.** Filebase (IPFS-backed S3) bucket `unitree`, prefix `collect/`,
exported in full on 2026-09-20. Each record's SHA-256 is in `manifest.json`;
the manifest's own hash is in `MANIFEST.sha256` so the whole export is
tamper-evident.

## Headline figures (re-computable from `SUMMARY.json` and `records/`)

| Metric | Value | How to verify |
|---|---|---|
| Unique participant addresses | **91** | distinct lowercase `address` in pass/fail records, excluding known non-user addresses |
| Scored challenge→solve records | **483** | all `pass` + `fail` records |
| Passed / Failed | **426 / 57** | `kind` field |
| Pass rate | **88.2%** | 426 / (426+57) |
| Unique passing agents | **87** | distinct participant `address` with `kind == "pass"` |
| On-chain mint receipts | **9** | `kind == "tx-receipt"` records |
| Unique user minters | **6** | receipt addresses excluding the protocol's own signer |
| Distinct missions attempted | **64** | distinct `missionId` |
| Avg passing / failing score | **91.6 / 13.7** | `score` field |
| Scoring mode | **100% `sim`** (deterministic simulator) | `mode` field |
| Window | **2026-08-17 → 2026-09-04** | `ts` field |

**Address accounting (precise).** 93 distinct addresses appear across all
records. Two are excluded from "unique participants":
`0xa1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1` (an obvious placeholder/test
address) and `0xcb67cffa62e3323c9b2d95121fa3873495920c7d` (the protocol's own
`poiSigner` key, which appears on two receipts and is not a user). Of the
remaining 91, one (`0x2bd2…424`, a founder test wallet) appears only on an
early receipt. The **headline participant figure of 91 counts only addresses
that actually submitted a scored answer.**

## Directory layout

```
records/
  pass/YYYYMMDD/<ts>-<nonce>.json        # a passing evaluation round
  fail/YYYYMMDD/<ts>-<nonce>.json        # a failing evaluation round
  tx-receipt/YYYYMMDD/<ts>-<nonce>.json  # on-chain mint receipt, joinable by `nonce`
  s3-test/...                            # one self-test record, excluded from stats
manifest.json                            # every record's key, sha256, size, mtime
MANIFEST.sha256                          # hash of manifest.json
SUMMARY.json                             # the aggregate statistics
verify.sh                                # re-check every sha256 locally
```

## Record schema

A `pass`/`fail` record:
```json
{"kind":"pass","ts":"2026-09-03T05:39:14.613Z","nonce":"...","address":"0x…",
 "missionId":"traj-real-23","missionTitle":"Real Harvest #23","answer":"…",
 "score":91,"passScore":60,"tier":"Elite","mode":"sim","free":true,"quantity":1}
```
A `tx-receipt` record shares the same `nonce`, so the off-chain text record and
the on-chain proof can be joined:
```json
{"kind":"tx-receipt","ts":"…","nonce":"…","address":"0x…","txHash":"0x…","chainId":5042}
```

## Honesty notes (read before citing)

- **All 483 scored records use `mode: "sim"`** — the deterministic simulator,
  not an LLM. This is intentional and is the core selling point: the scores
  are reproducible. It is stated here so no one mistakes these for
  LLM-graded outputs.
- **Two known non-user addresses are excluded from the participant count but
  kept in the raw records for transparency** (see "Address accounting"):
  an obvious placeholder (`0xa1a1…`) and the protocol's own `poiSigner`.
- **`missionBrief` is `null`** in these records because the hidden reference
  trajectory is never written to the collected record (by design, so the
  rubric cannot be reverse-engineered from the dataset).
- **On-chain mint receipts (9) are fewer than passing records (426)** because
  passing a challenge yields a *voucher*; minting on-chain is a separate step
  the agent may or may not take. We report "verified outcomes" = passing
  records and "settled on-chain" = receipts, and we do not conflate them.
- This dataset is **evaluation evidence**, not revenue, not settlement volume.
  It demonstrates that independent agents ran the flow and were reproducibly
  scored. USDC settlement is the funded roadmap (see the grant application).

## Independent verification

```bash
# 1. clone the repo, cd into this directory
# 2. re-hash every record and compare to the manifest
bash verify.sh
# 3. re-derive the summary numbers from the raw records
#    (any JSONL-aware tool works; the method is in verify.sh comments)
```

The on-chain receipts can be independently confirmed on the Arc explorer
against the `ProofOfIntelligenceMinted` events of contract
`0x6a3B12532F8e562f99e3292380e7f69D32e10B32` (chain ID 5042).
