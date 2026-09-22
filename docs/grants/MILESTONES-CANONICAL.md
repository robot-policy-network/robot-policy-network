# Canonical milestones and budget — SINGLE SOURCE OF TRUTH

**Every artifact (deck, portal answers, roadmap, application matrix) must use
exactly this numbering and these figures.** Divergence between materials was
flagged in review as a credibility failure.

_Established 2026-09-20. Supersedes any earlier milestone numbering._

---

## The four milestones

| # | Milestone | Funder | Status | Budget |
|---|---|---|---|---|
| **M1** | Deploy `EvaluationEscrow` to Arc mainnet with the frozen v1/v2 spec | **founder** | **COMPLETE** 2026-09-20 | $0 (founder-funded) |
| **M2** | Execute one end-to-end settlement on mainnet (escrow → attestation → release) | **founder** | **COMPLETE** 2026-09-20 | $0 (founder-funded) |
| **M3** | Circle Agent Stack integration into the live agent workflow | **this grant** | not started | **$8,000** |
| **M4** | Independent security review of `EvaluationEscrow`, report published | **this grant** | not started | **$5,000** |

**Total ask: $13,000** — the exact sum of M3 and M4.

**Why not more:** M1 and M2 were completed on founder funds *before* any award,
so they are not billed. The ask equals the two remaining milestones and nothing
else. There is no separate line item and no retroactive reimbursement.

## Post-grant roadmap (NOT funded by this ask)

| # | Item | Why it is separate |
|---|---|---|
| **M5** | Publish simulator + task manifest + runner so executability scores are third-party reproducible | Real work, but it is protocol hardening, not a Circle integration or a security gate. Stated as roadmap so the funded scope stays honest. |
| **M6** | Production instance under a fresh owner key (retires the demo deployment) | Operational hygiene; would be done regardless of funding. |

## The current deployment's status (must be stated identically everywhere)

- Contract: `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491`, Arc mainnet, SPEC_VERSION 2.
- It **is** a founder-funded demo. In the executed settlement the **payer, the
  evaluator and the provider are all founder-controlled keys** — the evaluator
  and provider are the *same address*. So the demo proves the **process works**;
  it does **not** prove the security property holds against a hostile party.
- Its **owner key was handled in a development session and must be treated as
  compromised**. Owner powers are bounded (rotate the default evaluator for
  future jobs; pause new job creation) and can never touch an existing job's
  funds. A production instance (M6) uses a fresh key.
- No third-party funds have ever touched the contract. It has accepted only
  founder escrows, and will keep doing so until M4 publishes.

## Honest limits that every material must carry

1. **The evaluator is a single centralized server.** "Reproducible" describes
   the scorer's determinism, not third-party recomputability. Today a third
   party cannot recompute a score (simulator unreleased, reference
   server-side). M5 fixes recomputability; until then the accurate claim is
   *"an evaluator compromise cannot move funds"*, **not** "proof of work".
2. **`planHash` is not recomputed on-chain** (spec §10). A payer that skips
   off-chain recomputation trusts the evaluator to have bound the right plan.
3. **A payer who never signs means the funds stay escrowed** (spec v2 change).
   The provider has no recourse path and no on-chain claim. That is a
   deliberate v2 trade — it removed a permissionless clawback that could rob a
   provider after delivery — but it is a real risk and belongs in the deck.
4. **The race stops exact copies, not near-copies.** Ranking uses 2-decimal
   scores and only a strictly better score displaces the leader, so an exact
   copy cannot win. A copy plus a marginal tweak can. Plans are not published
   per-window, which limits but does not eliminate this.
5. **The score has weak pricing signal at the top.** A generic plan lands 95–97
   and the pass mean is 95.8 (stdev 2.9), so the score alone barely separates
   a template from a competent agent. Difficulty gradation exists across
   missions (hardest task 83–87) but not much *within* the passing band.
6. **Traction is free-tier participation, not commerce.** 65,138 rounds came
   from a free NFT-mint competition; on-chain mints are 60; **zero** third-party
   USDC settlements; **zero revenue**.
7. **The top of the leaderboard is scripted.** The four heaviest wallets each
   ran ~1,350 rounds with answer diversity ≈0.09 (cache replay). The 0.988
   *median* diversity is real but must never be quoted without the top-of-table
   counterexample on the same page.
8. **The cohort is closed.** 208 of 217 addresses arrived on day one; 9 since.
   Engagement is deep, acquisition is ~zero.
9. **The ARCROBO token and the `UnitreeG1Fleet` NFT collection are separate
   subsystems** on the same chain. They are not part of this proposal, are not
   required to use the evaluation flow, and are disclosed so diligence finds no
   surprises. The free-mint competition that produced the traction ran through
   the NFT collection, not through the settlement protocol.
10. **No independent audit exists.** 85 tests and CI are the interim assurance.

## Grant-to-milestone mapping (for the portal)

Circle's roadmap format is
`what will exist at completion | Circle product | target date | success metric`.
Only M3 and M4 are grant milestones; M1/M2 are stated as completed context and
M5/M6 as post-grant roadmap.
