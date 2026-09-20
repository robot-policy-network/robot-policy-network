# Adversarial Review Brief — StonkRobotics / Robot Policy Network

**Purpose.** This file exists to be handed to an independent reviewer (human or
AI) with no prior context. It states what we claim, where the evidence lives,
how to verify each number, and — deliberately — every weakness we already know
about. If you find a problem not listed here, that is a finding worth reporting.

**Prepared:** 2026-09-20. **Reviewer instruction:** do not trust any number in
this document. Re-derive it. Every figure below has a stated verification path.

---

## 1. What the project claims (and where the proof is)

| # | Claim | Evidence location | How to verify | Status |
|---|---|---|---|---|
| 1 | A frozen settlement protocol exists, separating evaluation evidence from payment authorization | `docs/settlement-spec.md` (**SPEC_VERSION 2**, frozen) | Read §1 and §4; check the two typehashes; read the v1→v2 changelog | **True, frozen** |
| 2 | `EvaluationEscrow` implements it with 85 passing tests | `contracts/EvaluationEscrow.sol`, `test/EvaluationEscrow.t.sol` | Install deps, then `forge test` — expect 85 passed | **True — local Foundry implementation and tests with a mock ERC-20; not deployed, not audited, no real USDC settlement has ever executed** |
| 3 | The settlement contract is **not deployed** | spec preamble, `docs/limitations.md` | Query the Arc explorer for the address — it does not exist | **True (deliberate)** |
| 4 | A deterministic evaluation and score-recording flow is live on Arc mainnet | contract `0x6a3B12532F8e562f99e3292380e7f69D32e10B32`, chain 5042 | Fetch the explorer page; read the runtime code. Note precisely what this means: scores are produced off-chain by our deterministic evaluator and **recorded** on-chain via voucher/mint; no evaluator attestation and no USDC flow through the settlement protocol exist on-chain | **True, with the scope above** |
| 5 | 217 unique addresses submitted 65,138 scored rounds over 67 missions, 99.94% pass (by race design — see pass-rate honesty) | `docs/grants/traction-evidence/` | Run `bash verify.sh` — re-hashes 5 day-files and re-derives the stats | **Recomputable from the published export; source provenance remains operator-attested** (see §2.1) |
| 6 | Scoring is 100% deterministic simulator, not an LLM | `mode: "sim"` in every scored record | `jq` the `mode` field across records | **Recomputable from the published export; source provenance remains operator-attested** |
| 7 | The program's first official priority ("agentic economic activity") is our direct fit | `application-matrix.md` records official parameters | Visit `circle.com/grant` and the 2026-05-14 relaunch post | **True** |
| 8 | Robotics research indicates data quality and curation are important bottlenecks; this project tests whether verified evaluation improves that layer | `research-positioning-2026-09.md` | Resolve arXiv 2505.09603 (DataMIL) and 2403.12945 (DROID) | **Citations verified 2026-09-20. The citations support the *importance of curation*, not that this project has solved it** |
| 9 | Traction window is 2026-09-16 → ongoing (mainnet launch day start) | `SUMMARY.json` → `scoredByDay` | Check the `ts` fields in records | **Recomputable from the published export; source provenance remains operator-attested** |
| 10 | The Arc mainnet fleet contract shows `totalMinted() = 60`, `mintOpen() = true`, `poiMintOpen() = true` | RPC read 2026-09-20 | `cast call 0x6a3B12532F8e562f99e3292380e7f69D32e10B32 'totalMinted()(uint256)' --rpc-url https://rpc.mainnet.arc.io` | **True — real on-chain mints; no 1:1 join to evaluation records is claimed** |

### Dataset layers — read this before quoting any number

The counts below answer different questions. Quoting "65,138" as participants,
or "217" as records, would both be wrong:

| Layer | Count | Meaning |
|---|---|---|
| Scored rounds (current arena, since mainnet launch) | **65,138** | `pass` + `fail` records (65,102 + 36); 100% `mode: "sim"` |
| Pass / Fail | **65,102 / 36** | 99.94% pass — by design (retry-until-clear race); see pass-rate honesty |
| Unique participant addresses | **217** | Distinct wallets with ≥1 scored round; median 297 rounds, max 1,381, only 3 single-round — a heavy-repeat mining community, not 217 casual users |
| Unique missions | **67** | Distinct `missionId` values |
| Window | 2026-09-16 → ongoing | Daily volume: 14,027 / 11,247 / 13,812 / 22,086 / 3,966 (partial) |
| Arc mainnet mints | **60** | `totalMinted()` on `0x6a3B…`; separate optional on-chain step, no 1:1 join claimed |
| Superseded earlier export | 483 records | Filebase era, window 2026-08-17 → 09-04; preserved in git history, superseded by this export |

## 2. Known weaknesses (stated before you find them)

Ranked by how much damage they do if a reviewer hits them cold.

1. **Dataset provenance is self-attested.** The upstream Filebase bucket is
   private (403 to unauthenticated GET). You can verify the published export
   (SHA-256 manifest, re-derived stats, on-chain receipts) but you cannot
   independently re-pull the source bucket and confirm it produced this
   export. The chain receipts are the only independently-anchored slice — and
   even they are **Sepolia testnet** receipts, not Arc mainnet. *Probe:* the
   hash chain proves the export is unmodified since publication; it does not
   prove the records describe real agent runs.

2. **Provenance is operator-attested, and the arena rewards heavy repeat
   usage.** The upstream store is a private server file. You can verify the
   published export (per-file SHA-256 in the manifest, re-derived stats,
   `totalMinted() = 60` on-chain) but you cannot independently re-pull the
   source. Separately, the usage shape is a *mining community*: only 3 of 217
   addresses submitted exactly one round, the median address submitted 297
   rounds, the top address 1,381, and 2.7% of records arrive in sub-second
   bursts (max 8/second). That is consistent with a repeated-competition game
   played by a loyal base — which is the intended design — but it is also
   consistent with fewer humans behind many wallets, and the dataset cannot
   distinguish them. *Probe:* ask for the human-attribution story; the
   attribution is recorded in `traction-attribution.md` (founder-confirmed: X-recruited cohort), with the wallet-vs-human limit stated rather than blurred.

3. **Settlement — the payable half — is not deployed.** Everything about
   payment is a specification plus tests. The only live capability is
   evaluation and on-chain recording. Our one-line summary ("trust and
   settlement layer") is tighter than the truth; the body states the split.

4. **One founder — with a verifiable prior shipping record, but no external
   validation.** On the positive side the applicant has shipped **AI2Human
   Network** (`ai2human.work`, GitHub org `ai2humannetwork`, 6 public repos
   incl. Base settlement contracts, created 2026-06-27) — the same
   "prove → verify → settle" thesis applied to human execution. That is real
   evidence of shipping ability, which Circle's criteria explicitly weight.
   On the negative side: `ai2humannetwork` has **0 followers and 0 stars**
   across its repos, this repository has **0 stars / 0 forks / 0 watchers**,
   no independent audit exists, and no third party is known to build on
   either project. The OKX hackathon second-place claim is
   **founder-confirmed but not independently verifiable** — the official
   announcement appears to publish winners as an image. *Probe:* ask for a
   resolvable URL for the award, and ask why one project settles on Base and
   the other on Arc.

5. **`main` does not contain the work.** The default branch is protected and
   lags 15 commits; all evidence lives on `ci/install-foundry-dependencies`.
   A reviewer checking the default branch first sees an older README and no
   traction dataset. **Highest-impact fixable item.**

6. **The scoring rubric was reverse-engineered once.** Our own run reports
   document that a deterministic keyword rubric could be satisfied by a
   template — which is why the current evaluator scores against hidden
   reference trajectories instead. Presented as a red-team finding; a hostile
   reader may read it as "they shipped a gameable evaluator before."

7. **No Circle product is integrated yet.** "Circle products as building
   blocks" is a plan (M3), not a fact. The only Circle surface used is
   Arc-native USDC as a settlement unit of account in the spec — and that
   path is not deployed either.

8. **Competitor claims are second-hand.** Axis ($12M), PrismaX ($11M), and
   RoboTrain characterisations rest on press coverage and company posts. The
   deep links we first used returned 404 or were unfetchable, so we cite them
   qualitatively. If a figure is stale the competitive argument weakens, but
   the position does not collapse.

9. **The "traction" is participation, not commerce.** 65,138 scored rounds, 60
   Arc mainnet mints, zero revenue, zero paying counterparties. Reading the
   dataset as commercial validation would be wrong, and the dataset README says
   so.

10. **Weakest link in the narrative.** "Each verified outcome becomes a
    curated training-data asset" is a roadmap item. The dataset proves agents
    ran and were scored; it does not prove the records are training-usable.
    DataMIL supports *curation matters*, not *our curation produces training
    value*.

## 3. Questions a hostile reviewer should ask us

1. If the upstream bucket is private, what stops you from having generated
   these 65,138 records yourself?
2. Who were the 217 addresses? Can any of them be contacted to confirm they
   ran the flow? (The earlier 483-record Filebase era had a separate 91.)
3. Why does the dataset stop on 2026-09-04? Was the flow running on
   2026-09-20, and if so where are those records?
4. Your KPI promises 100 verified outcomes per month. You hit 343 in one day
   on 2026-09-03, then nothing. Which number is real?
5. Which Circle product will M3 integrate, and what breaks if you integrate
   none of them?
6. You say Arc is "strongest" but not exclusive. What concretely stops a
   competitor from deploying the same contract to Base tomorrow?
   **Our honest answer, stated here so you can hold us to it:** nothing stops
   them at the bytecode level. The contract is standard Solidity and the
   pattern is open-source (MIT). Arc is the initial target because its
   stablecoin-native settlement model — native USDC with an ERC-20 interface
   over the same balance, designed for exactly this kind of flow — fits the
   product best, not because the bytecode is unportable. Any exclusivity comes
   from distribution, data, and integrations, not from bytecode lock-in.
7. The evaluation layer has been running since mainnet launch. How many
   distinct humans are behind those 217 addresses — could it be one operator
   with a wallet farm? **(Answered at wallet level, honestly capped at human
   level: `traction-attribution.md` records the founder-confirmed sourcing
   (X-recruited cohort) plus the behavioural evidence — 91.2% near-unique
   answers, 82% five-day retention — and explicitly does not claim human
   counts it cannot evidence.)**
8. What is your actual cost per verified evaluation, and who pays it?
9. `EvaluationEscrow` is 292 lines with 1,060 lines of tests and no audit.
   Why should a payer trust it with funds after a $5,000 review?
10. If Circle declines, does anything change for the project, or does this
    continue anyway?

## 4. Claims we explicitly disclaim

Do not credit us with these; we have not claimed them anywhere:

- No independent audit. No audit completed or scheduled before M4.
- No revenue, no paying customers, no partnership, no endorsement by Circle
  or Arc.
- No byte-for-byte reproducibility between this repository and the deployed
  bytecode.
- No proof that any real robot hardware was involved. Trajectories derive from
  public datasets (DROID / Open X-Embodiment lineage); the simulator is 2D.
- No claim that USDC has ever moved through this protocol.
- The ARCROBO token and the `UnitreeG1Fleet` ERC-721 collection are separate
  subsystems, disclosed in the Risks section, and are not part of the
  proposal.

## 5. Verification recipes

```bash
# A. Contracts (dependency installs must be separate commands, as CI runs them)
cd <repo>
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-git
forge install foundry-rs/forge-std --no-git
forge test              # expect: 85 passed, 0 failed
forge fmt --check contracts/EvaluationEscrow.sol test/EvaluationEscrow.t.sol \
  script/DeployEvaluationEscrow.s.sol

# B. Canonical serializer (the only implementation of spec §3; zero deps)
node references/canonical.test.mjs   # expect: ALL VECTORS PASS

# C. Traction dataset (expects jq)
cd docs/grants/traction-evidence
bash verify.sh          # re-hashes 5 day-files; re-derives 65,138/65,102/36/217/67
cat SUMMARY.json        # compare with the README headline table

# D. Live links (must all return 200 with a browser User-Agent; bare curl
#    without a UA returns 403/502 on several of these due to anti-bot)
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://stonkrobotics.xyz/skill
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://github.com/robot-policy-network/robot-policy-network

# E. Citations
curl -s -o /dev/null -w '%{http_code}\n' https://arxiv.org/abs/2505.09603
curl -s -o /dev/null -w '%{http_code}\n' https://arxiv.org/abs/2403.12945
```

**Where the automated proof lives.** The CI workflow is
`.github/workflows/contract-ci.yml` on branch
`ci/install-foundry-dependencies`; its jobs are: build → 85 Foundry tests →
format check → anvil deploy smoke test (deploys `EvaluationEscrow`, asserts
`owner`/`evaluator`/`usdc`/`nextJobId` read back as constructed, and asserts the
`evaluator == owner` guard reverts) → canonical serialization vectors. Run
history is public under the repository's Actions tab.

## 6. Scoring rubric we would apply to ourselves

| Dimension | Self-score | Justification |
|---|---|---|
| Technical design quality | **Strong** | Evidence/authority split is a real insight; determinism enforced; accepted limitation documented rather than hidden |
| Verifiability of claims | **Strong** | Hashes, re-runnable script, live links, chain addresses |
| Traction / adoption | **Mixed** | 65,138 scored rounds from 217 wallets over 5 days (ongoing), 60 on-chain mints — but heavy-repeat usage, 0 revenue, 0 community signal, no third party building |
| Team | **Mixed** | Solo founder, but with a verifiable shipped prior project (AI2Human Network: live product + 6 public repos). Award claim unverifiable; no advisors; no external validation |
| Market positioning | **Strong** | Sits in a documented academic gap and a funded-but-different competitor set |
| Execution risk | **High** | Unaudited, undeployed payment path; single point of failure |
| Honesty | **Unusually strong** | This document is itself the evidence |

**Overall:** a well-specified, honestly-documented early protocol with one
genuine architectural insight and almost no external validation. The
application's strength is that it does not pretend otherwise.

## 7. What would move this from "promising" to "fundable at a glance"

Ranked by impact per unit of effort:

1. Merge the evidence and the spec to `main` so a reviewer sees them by
   default. **(PR open; blocked on protected-branch review.)**
2. Deploy `EvaluationEscrow` to Arc testnet and record one real settlement
   transaction — that single hash would answer questions 1, 3, 7, and 8 above.
   **(Deploy script now exists and is CI-proven; only the funded deploy +
   keys remain.)**
3. Get one independent developer to integrate the challenge API and write
   something public about it. **(Invitation text drafted in
   `launch-content.md` §5; needs an actual external taker.)**
4. Publish the evaluator so executability scoring is reproducible by third
   parties, not just deterministic on our server. **(Analysis + 4-step
   proposal now in `../evaluation-reproducibility.md`; implementation is a
   post-grant task.)**
5. Answer the "217 addresses, how many humans?" question with a documented
   attribution story (e.g. a KOL campaign or community event) filed alongside
   the dataset. **(Template created at
   `traction-attribution.md`; sourced via X, human count not claimed.)**
6. Ship a whitepaper. **(Done — `../whitepaper.md`, 10 sections, honest
   live/proposed status table.)**

### Related documents

| Document | Purpose |
|---|---|
| `traction-highlights.md` | **One-page evidence dossier** — the strongest verifiable numbers, with counterweights on the same page |
| `traction-evidence/README.md` | The dataset, its integrity model, behavioral deep-dive, and probe caveats |
| `traction-evidence/deep-analysis.json` + `deep-analysis-2.json` | Raw analysis outputs (participation, cohort, retention, diversity, difficulty, correlations) |
| `../whitepaper.md` | Full protocol write-up with honest status table |
| `../evaluation-reproducibility.md` | L0/L1/L2 verifiability analysis + L2 proposal |
| `../security/red-team-findings.md` | Self-disclosed findings, incl. the gameable rubric |
| `traction-attribution.md` | The 217-wallet attribution: X-recruited cohort, what it does and does not support |
| `launch-content.md` | Community/X/directory/integration drafts |
| `circle-developer-grant-draft.md` | The application itself (v5) |
| `canonical-fact-sheet.md` | Claim governance: verified / confirmed / planned / do-not-claim |

