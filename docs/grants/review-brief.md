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
| 1 | A frozen v1 settlement protocol exists, separating evaluation evidence from payment authorization | `docs/settlement-spec.md` (SPEC_VERSION 1) | Read §1 and §4; check the two typehashes; run the tests | **True, frozen** |
| 2 | `EvaluationEscrow` implements it with 81 passing tests | `contracts/EvaluationEscrow.sol`, `test/EvaluationEscrow.t.sol` | Install deps, then `forge test` — expect 81 passed | **True** |
| 3 | The settlement contract is **not deployed** | spec preamble, `docs/limitations.md` | Query the Arc explorer for the address — it does not exist | **True (deliberate)** |
| 4 | An evaluation flow is live on Arc mainnet | contract `0x6a3B12532F8e562f99e3292380e7f69D32e10B32`, chain 5042 | Fetch the explorer page; read the runtime code | **True** |
| 5 | 91 unique agents completed 483 deterministically-scored rounds over 64 missions, 88.2% pass | `docs/grants/traction-evidence/` | Run `bash verify.sh` — re-hashes 493 records and re-derives the stats | **True, re-computable** |
| 6 | Scoring is 100% deterministic simulator, not an LLM | `mode: "sim"` in every scored record | `jq` the `mode` field across `records/` | **True** |
| 7 | The program's first official priority ("agentic economic activity") is our direct fit | `application-matrix.md` records official parameters | Visit `circle.com/grant` and the 2026-05-14 relaunch post | **True** |
| 8 | Collection is funded; curation is the academic bottleneck | `research-positioning-2026-09.md` | Resolve arXiv 2505.09603 (DataMIL) and 2403.12945 (DROID) | **Citation verified 2026-09-20** |
| 9 | Traction window is 2026-08-17 → 2026-09-04 | `SUMMARY.json` → `recordsByDay` | Check the `ts` fields in `records/` | **True** |
| 10 | 9 on-chain mint receipts exist in the dataset | `records/tx-receipt/` | Count files; cross-check `nonce` in chain logs | **True** |

## 2. Known weaknesses (stated before you find them)

Ranked by how much damage they do if a reviewer hits them cold.

1. **Dataset provenance is self-attested.** The upstream Filebase bucket is
   private (403 to unauthenticated GET). You can verify the published export
   (SHA-256 manifest, re-derived stats, on-chain receipts) but you cannot
   independently re-pull the source bucket and confirm it produced this
   export. The chain receipts are the only independently-anchored slice.
   *Probe:* the hash chain proves the export is unmodified since publication;
   it does not prove the records describe real agent runs.

2. **A few records are pre-launch, and some arrive in sub-second bursts.**
   Two pre-launch records (08-17, 08-29) are founder end-to-end receipts, not
   participant rounds; they are published unmodified for completeness, and all
   483 scored rounds fall in 09-02..09-04. Separately, 18 of 483 records
   (3.7%) arrive inside sub-second bursts — the largest is 12 records in one
   second (`2026-09-04T12:18:22Z`) from 12 distinct addresses. That pattern is
   consistent with a parallel agent swarm (which is the intended usage) or
   with one operator driving many keys; the dataset cannot distinguish them.
   Also notable: **49 of the 91 participants submitted exactly one round**, and
   no address exceeded 81 rounds. *Probe:* ask for the human-attribution story
   behind 09-04's 47 distinct addresses.

3. **Settlement — the payable half — is not deployed.** Everything about
   payment is a specification plus tests. The only live capability is
   evaluation and on-chain recording. Our one-line summary ("trust and
   settlement layer") is tighter than the truth; the body states the split.

4. **One founder, no audit, no external committers.** 0 stars, 0 forks,
   0 watchers on the repository as of 2026-09-20. No third-party endorsement
   of any kind, and no evidence anyone outside the founder has built on it.

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

9. **The "traction" is participation, not commerce.** 483 scored rounds, 9
   receipts, zero revenue, zero paying counterparties. Reading the dataset as
   commercial validation would be wrong, and the dataset README says so.

10. **Weakest link in the narrative.** "Each verified outcome becomes a
    curated training-data asset" is a roadmap item. The dataset proves agents
    ran and were scored; it does not prove the records are training-usable.
    DataMIL supports *curation matters*, not *our curation produces training
    value*.

## 3. Questions a hostile reviewer should ask us

1. If the upstream bucket is private, what stops you from having generated
   these 492 records yourself?
2. Who were the 91 agents? Can any of them be contacted to confirm they ran
   the flow?
3. Why does the dataset stop on 2026-09-04? Was the flow running on
   2026-09-20, and if so where are those records?
4. Your KPI promises 100 verified outcomes per month. You hit 343 in one day
   on 2026-09-03, then nothing. Which number is real?
5. Which Circle product will M3 integrate, and what breaks if you integrate
   none of them?
6. You say Arc is "strongest" but not exclusive. What concretely stops a
   competitor from deploying the same contract to Base tomorrow?
7. The evaluation layer has been live since ~August. How many distinct
   humans are behind those 91 addresses — could it be one person with 91
   keys?
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
# A. Contracts
cd <repo> && forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 \
  foundry-rs/forge-std --no-git
forge test              # expect: 81 passed, 0 failed
forge fmt --check contracts/EvaluationEscrow.sol test/EvaluationEscrow.t.sol

# B. Traction dataset (expects jq)
cd docs/grants/traction-evidence
bash verify.sh          # re-hashes 493 records; re-derives 483/426/57/91/64
cat SUMMARY.json        # compare with the README headline table

# C. Live links (must all return 200 with a browser User-Agent)
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://stonkrobotics.xyz/skill
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32
curl -s -o /dev/null -w '%{http_code}\n' -A 'Mozilla/5.0' \
  https://github.com/robot-policy-network/robot-policy-network

# D. Citations
curl -s -o /dev/null -w '%{http_code}\n' https://arxiv.org/abs/2505.09603
curl -s -o /dev/null -w '%{http_code}\n' https://arxiv.org/abs/2403.12945
```

## 6. Scoring rubric we would apply to ourselves

| Dimension | Self-score | Justification |
|---|---|---|
| Technical design quality | **Strong** | Evidence/authority split is a real insight; determinism enforced; accepted limitation documented rather than hidden |
| Verifiability of claims | **Strong** | Hashes, re-runnable script, live links, chain addresses |
| Traction / adoption | **Weak** | 91 addresses, 9 receipts, 0 community signal, 0 revenue, no third party building |
| Team | **Weak** | Solo founder, no track record presented, no advisors |
| Market positioning | **Strong** | Sits in a documented academic gap and a funded-but-different competitor set |
| Execution risk | **High** | Unaudited, undeployed payment path; single point of failure |
| Honesty | **Unusually strong** | This document is itself the evidence |

**Overall:** a well-specified, honestly-documented early protocol with one
genuine architectural insight and almost no external validation. The
application's strength is that it does not pretend otherwise.

## 7. What would move this from "promising" to "fundable at a glance"

Ranked by impact per unit of effort:

1. Merge the evidence and the spec to `main` so a reviewer sees them by
   default.
2. Deploy `EvaluationEscrow` to Arc testnet and record one real settlement
   transaction — that single hash would answer questions 1, 3, 7, and 8 above.
3. Get one independent developer to integrate the challenge API and write
   something public about it.
4. Publish the evaluator so executability scoring is reproducible by third
   parties, not just deterministic on our server.
5. Answer the "91 agents, how many humans?" question with a documented
   attribution story (e.g. a KOL campaign or community event) filed alongside
   the dataset.

