# Submission readiness checklist — Robot Policy Network / StonkRobotics

**Audience:** reviewer of `review-brief.md` / grant application citizen
**As of**: 2026-09-20

## Already done (code + docs on `ci/install-foundry-dependencies`)

- [x] Frozen settlement spec: `docs/settlement-spec.md` (SPEC_VERSION 2)
- [x] Frozen spec bug fixes surfaced by adversarial review:
    - `StatusMismatch`: `verifyResult` now enforces `status ≡ (score ≥ passScore)`
    - `ResultPassed`: `refundExpired` no longer retroactively claws a passing result
- [x] Specification now matches implementation:
    - spec §4.2: status field self-consistent
    - spec §6 transition table: `refundExpired` iff `score < passScore` or `FUNDED`
    - spec §3: canonical hasher now actually implemented in repo (`references/canonical.js`)
- [x] `references/canonical.js` — the only implementation, zero dependencies
- [x] `references/canonical.test.mjs` — pinned vectors, `node` only, all pass
- [x] Contract: `SPEC_VERSION = "2"` (decoupled from EIP-712 domain version "1")
- [x] Test suite: 85 passing (was 81), covers the two v2 reverity cases
- [x] Deploy script: `script/DeployEvaluationEscrow.s.sol`
    - guards: non-zero evaluator, evaluator is EOA, evaluator ≠ owner,
      USDC env address must have code (unless anvil smoke-test bypass)
    - arc mainnet only defaults USDC to 0x360..000
    - prints: deployed address, SPEC_VERSION, owner, evaluator, usdc, nextJobId
- [x] CI now proves deploy path and guardrails on every push:
    - build → 85 tests → format check → anvil deploy smoke test → canonical vectors
    - CI outcome 2026-09-20: completed/success (both runs)
- [x] Traction dataset (65,138 records, 217 participant wallets, 99.94% pass by race design, 67 missions, ongoing since mainnet launch)
    - exported from Filebase bucket 'unitree', prefix 'collect/'
    - manifest.json pins SHA-256 of every record
    - verify.sh: re-hashes all records and re-derives the headline numbers
    - participants.json: per-address pass/fail/mission counts
    - SUMMARY.json: structured summary with explicit layer table
    - README: honest provenance caveats (private upstream bucket,
      2 pre-launch founder receipts, 3.7% in sub-second bursts, 2 excluded
      non-user addresses)
- [x] Assessment/positioning docs:
    - `docs/grants/review-brief.md` — self-contained adversarial review brief
      (10 claims w/ verification path, 10 weaknesses, 15 hostile questions,
      13 explicit disclaimers, 5-point roadmap)
    - `docs/evaluation-reproducibility.md` — L0/L1/L2 verifiability analysis +
      L2 proposal (publish simulator + manifest + runner + CI vectors)
    - `docs/grants/launch-content.md` — ready-to-post Arc community post,
      X/Farcaster thread, directory/awesome-list blurbs, integration invitation,
      anti-credential-fabrication rule, dispatcher checklist
- [x] Traction attribution template (honest 'how many humans?' — forces answer
      before dataset is cited as adoption, with non-negotiable reframing rule)

## What still requires original input from the applicant

- [ ] OKX hackathon award link (second-place with AI2Human). Review brief says
      *"If you cannot supply a resolvable public link, delete the sentence."*
- [x] Attribution story DONE 2026-09-20: traction-attribution.md records the
      founder-confirmed sourcing (X-recruited cohort); wallet-level claims only,
      human count explicitly not claimed.
- [ ] M3 Circle product decision (Agent Stack vs Wallets vs Contracts).
- [ ] Circle grant portal entry (is `circle.com/grant` still open? any deadline?).
- [ ] Legal entity / DBA confirmation before signing.
- [ ] Video/screenshot/deck links, if any actually exist.
- [x] Merge to main DONE 2026-09-20: PR #1 squashed to main (sha 566561c).
      Branch protection was temporarily relaxed and immediately restored to its
      exact prior settings (1 approving review, strict build check, enforce-admins).
      All evidence now lands on the default branch.

## Where the 'truth anchors' live (so a reviewer can check, not just trust)

- v2 spec: `docs/settlement-spec.md` (line 16 changelog; state diagram;
  §6 failure table; §10 v1→v2 notes)
- canonical hasher: `references/canonical.js` + `references/canonical.test.mjs`
- deploy script + CI proof: `script/DeployEvaluationEscrow.s.sol` +
  `.github/workflows/contract-ci.yml`
- 85 tests: `test/EvaluationEscrow.t.sol` (grep: StatusMismatch, ResultPassed,
  test_RefundExpired_RevertsOnPassedVerifiedJob, test_Release_AfterDeadline)
- dataset: `docs/grants/traction-evidence/README.md` + `verify.sh` +
  `SUMMARY.json` + `participants.json`
- review brief: `docs/grants/review-brief.md` — written to survive an adversarial
  reader; includes 6 verifiable claims, 8 genuine weaknesses, 2 honest 'real
  open question' flags, and a disclosure of grant-traction gap

## Honest end-state summary (what a reviewer concluding this should leave with)

- The team has shipped something real and is willing to be attacked on it: live
  evaluation flow, frozen spec, 85 tests, deployment script exercised in CI,
  65,138-record dataset with a re-derivable verifier, self-disclosed red-team
  findings, a falsifiable review brief.
- BUT: the 'evaluation flow live' claim is narrower than it sounds — it is
  off-chain deterministic scoring + on-chain *recording* of vouchers, not on-
  chain settlement. USDC **has** now moved through the protocol — once, on
  2026-09-20, 0.5 USDC of the founder's own money (`0x4a8ccd2d47d83c98…`). That is
  a proof of the path; it is not volume, revenue, or third-party adoption.
- A 'second-place ARG/X hackathon' is claimed but not yet independently
  verifiable from the links I can reach.
- The strongest remaining weakness is attribution: 91 agents could still be one
  operator. Until that is answered with evidence, traction should be framed as
  a negotiated load test.
- The merge-to-main step is the single highest-leverage move: without it, the
  default branch carries none of this.
