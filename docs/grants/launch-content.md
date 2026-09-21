# Launch Content Pack — ready-to-post drafts

**Purpose.** Materials to earn *organic* attention for the protocol. Every draft
here points at a verifiable artifact (a frozen spec, a test suite, a dataset, a
live link) rather than a claim, because that is what earns engineering
credibility — and credibility is what converts into stars, contributors, and
reviewer goodwill.

**Rule for all content:** no superlatives, no "revolutionary", no "first ever",
no inflated numbers. State the design decision, show the artifact, invite
attack. The red-team transparency is the most interesting thing we have; lead
with it.

---

## 1. Arc community post (Discord / forum)

**Title:** How does a machine get paid for work without anyone trusting the
machine's word?

> We've been building on Arc and hit a problem worth sharing, because we don't
> think we're the only ones who will hit it.
>
> **The setup.** An agent claims it completed a task. A payer wants to release
> USDC. Today's options are: (a) agent-payment tools where a human still
> decides — so nothing is verified; (b) escrow/oracle designs that treat a
> reported score as the payment instruction — so a wrong or manipulated score
> moves money; (c) human review, which works and cannot keep up.
>
> **What we built.** A split we think is the actual primitive missing here: the
> party that produces *evidence* and the party that grants *authority* are
> different keys.
>
> - `EvaluationAttestation` — the evaluator says "this plan scored X against
>   task T". **Cannot move funds.**
> - `ReleaseAuthorization` — the payer says "pay this provider this amount for
>   this result". **Insufficient alone.**
> - `release()` requires both. So an evaluator can never pay itself, and a payer
>   cannot be tricked into paying for a result whose preimage names a different
>   plan.
>
> **The evaluation side is execution-anchored, not text-anchored.** Tasks carry
> a hidden reference trajectory from real robot episodes; the agent submits a
> structured action plan; a pure-function simulator executes it across seeded
> perturbations. A plan that doesn't run scores zero. Determinism is enforced:
> seeded PRNG, no clock, no global randomness — same `(world, plan, seed)` gives
> the same score on any machine.
>
> **Why we're posting it, not just shipping it.** We red-teamed our own scorer
> and found the original text rubric was trivially gameable — a generic template
> scored 80–100. We published the finding, not just the fix:
> `docs/security/red-team-findings.md`.
>
> **Current state, honestly.** Evaluation and on-chain recording are live on Arc
> mainnet (chain 5042). The settlement contract is frozen at `SPEC_VERSION = 2`
> with 85 passing tests and a deploy script CI proves works — but it is **not
> deployed yet**. We would rather say that plainly than imply otherwise.
>
> Repro: spec · tests · traction dataset with a re-runnable verifier · an
> adversarial review brief we wrote against ourselves (please attack it).
>
> Two questions for people who know Arc better than we do: is the ERC-20-only
> USDC pattern the right long-term call, and is there an idiomatic Arc way to
> make the evaluator's commitment verifiable without publishing the reference
> trajectory?

## 2. X / Farcaster thread

1/ A machine's work is getting cheap to perform and expensive to trust. We built
the missing primitive on @arc: **a score can never move money.**

2/ The split: an evaluator signs an evaluation attestation (evidence). The payer
signs a release authorization (authority). `release()` requires BOTH. An
evaluator cannot pay itself; a payer cannot pay for a result they didn't
authorize.

3/ Scoring is by **execution**, not by text. Agents submit structured action
plans; a deterministic simulator runs them against hidden reference trajectories
from real robot episodes. A plan that doesn't execute scores zero. Same input →
same score, always.

4/ We attacked our own scorer first. The original text rubric was gameable — a
template scored 80–100 without demonstrating anything. We published the finding,
not just the fix. [link]

5/ Where it actually is: evaluation + on-chain recording live on Arc mainnet.
The settlement contract is frozen (SPEC_VERSION 2, 85 tests, CI-proven deploy
path) and **deployed at `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491` with one real settlement executed** — on
founder funds, 0.5 USDC, no third-party money and no audit. Stated plainly in
the repo.

6/ Everything is checkable: frozen spec, 85-test suite, and a 492-record
traction dataset with a script that re-hashes every record and re-derives every
statistic. Don't trust our numbers — recompute them. [links]

7/ If you're building agentic payments on Arc, the pattern is yours: the
evidence/authority split is the part we think everyone will need. MIT, and we'd
rather be corrected than quoted.

## 3. Directory submission (built-on-arc style)

```
Project:  Robot Policy Network (StonkRobotics)
Category: Developer infrastructure / Agentic payments
Chain:    Arc mainnet (5042)
Live:     Evaluation flow + on-chain result recording
          Contract: 0x6a3B12532F8e562f99e3292380e7f69D32e10B32
Not live: EvaluationEscrow settlement (frozen spec, tested, undeployed)
Links:    repo · spec · dataset verifier · adversarial review brief
One line: Separates evaluation evidence from payment authorization so an
          agent's verified work can settle in USDC without any single key
          being able to do both.
Evidence: frozen SPEC_VERSION=2, 85 passing tests, CI deploy-path smoke
          test, 492-record SHA-256-pinned dataset with re-runnable verifier
```

## 4. awesome-list PR blurb

> Adds Robot Policy Network — an MIT-licensed reference implementation of an
> evidence/authority split for machine-work settlement on Arc. The evaluator
> signs evidence (`EvaluationAttestation`); the payer signs authority
> (`ReleaseAuthorization`); release requires both. Includes a frozen v2 spec,
> an 85-test Foundry suite, a verified deploy script, and a tamper-evident
> traction dataset. Useful as a pattern reference for anyone designing agentic
> payments where the scorer must not be the payer.

## 5. Integration invitation (for the "one independent developer" goal)

> We're looking for one team or developer building agents on Arc (or anywhere
> with USDC) who'd be willing to integrate the challenge API and tell us where
> it breaks. We're not asking for a testimonial — we're asking for friction
> reports, and we'll publish what you find. The evaluation layer is live and
> free to call; the settlement layer is deployed and has executed one
> founder-funded settlement, so you can read the receipts but nobody else's
> funds are involved,
> so nothing you do can put funds at risk.

That framing converts better than a partnership ask, because it is honest about
what we want (evidence of external use) and what the integrator gets (a working
evaluation loop and published attribution for any finding).

---

## Posting order and ethics

1. **Arc community first** — it is the audience that can actually use the
   pattern, and it is where a grant reviewer may already be reading.
2. **X/Farcaster second**, linking the community thread.
3. **Directory + awesome-list** once a community thread exists (a listing with
   no discussion reads as spam).
4. **Integration invitation** after the pattern has one public explainer.

### Do not buy stars

`star-history.com` makes inorganic spikes obvious, GitHub's stargazer list
exposes empty accounts, and a reviewer who spots manipulation will discount the
*entire* application — the opposite of the goal.

**Realistic goal: 20–50 organic stars over a few weeks with real referrers.**
That is worth more than 500 bought ones, and it is true. The three mechanisms
that actually produce them, in order of yield:

1. a technical post in a place where Arc builders already read;
2. a genuinely useful artifact someone else can reuse (the evidence/authority
   pattern, and the dataset verifier);
3. a candid failure report (the gameable-rubric finding) — engineers star
   projects that publish their own mistakes, because it signals the code is
   honest.

## Checklist

| Item | Status |
|---|---|
| Arc community post drafted | ✅ above |
| X/Farcaster thread drafted | ✅ above |
| Directory submission text | ✅ above |
| awesome-list blurb | ✅ above |
| Integration invitation | ✅ above |
| Links inside drafts resolve | ⏳ fill in after PR #1 merges to `main` |
| Post to Arc community | ⏳ not yet posted |

