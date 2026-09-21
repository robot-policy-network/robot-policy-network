# Adversarial Review — pitch deck + video script
**Reviewer stance: the strongest possible evaluator. Findings, then fixes.**
**Reviewed 2026-09-20. Artifacts: `pitch-deck.html` (17 slides), `video-script.md`.**

## P0 — must fix before submission

**V1. The video does not demonstrate the required thing.**
Circle requires "Demonstrate the user flow where Circle infrastructure powers
your product." The script shows code + a `cast call getJob(1)` reading a *past*
transaction. That is not a user flow. The actual user flow (install skill →
GET /api/challenge → submit plan → get score → voucher) is never shown on the
live product (stonkrobotics.xyz/skill/). This is the single largest gap
against an explicit requirement. *Fix: add a live product segment.*

**V2. The on-chain "settlement demo" is self-dealing, and the video doesn't say so.**
In the executed settlement, the payer (0x92bF…) is the founder, the evaluator
AND the provider are the same founder-generated key (0x5dF7…). So on the
explorer, the evaluator paid itself. That is precisely the conflict the
protocol claims to prevent. `deployments/arc-mainnet-settlement.json` discloses
it; the video narration does not. *Fix: say it on camera — "in this demo the
same founder plays payer and provider; the evaluator key is a throwaway."*

**V3. "impossible to fake" is contradicted by our own red-team doc.**
The video hook says "the mechanism that makes the scoring impossible to fake."
`docs/security/red-team-findings.md` documents that the text rubric WAS gamed.
A reviewer who reads both sees an overclaim. *Fix: say "hard to fake" and
point at the self-disclosure.*

## P1 — credibility issues a sharp reviewer will catch

**D1. The daily-volume chart reads as a collapse.** Sep 20 shows 3,966 as a bar
half the height of Sep 19's 22,086. It is a partial day, but the chart does not
say that. Reviewer sees a cliff. *Fix: label Sep 20 as partial.*

**D2. "90.8-point separation" oversells a 0.05% fail rate.** 36 fails out of
65,138. The separation is real but the framing "proves the evaluator
discriminates" is backwards: with 99.94% passing, the stronger and more
defensible evidence is the *difficulty curve* (traj-real-81 drew 184 wallets
and scored them 83–87) — that shows gradation, not a pass/fail wall.
*Fix: lead with the difficulty curve; keep the separation as secondary.*

**D3. The attack-closure table conflates two defenses.** Row "Copy a winning
plan → precision uses per-target constants." But everyone in a race window
solves the SAME mission, so per-target constants are identical for everyone in
that window — they do not stop same-window copying. Copying within a window is
stopped by the strictly-better-score rule, not by per-target constants. A sharp
reviewer catches the mismatch. *Fix: per-target constants stop cross-mission
reuse; strictly-better-score stops same-window copying. State them separately.*

**D4. Formula weights are unexplained.** `0.38/0.32/0.20/0.10` is presented as
if meaningful, but no basis is given. "Why 0.38 not 0.40?" has no answer.
*Fix: either state these are tuned heuristics chosen by the founder, or drop
the specific weights from the headline and present the structure.*

**D5. "median 121 wallets per hourly window" is computed over active windows only.**
windowSec=3600, so 5 days ≈ 120 windows, but only 80 had activity — ~33% of
windows were empty. The figure is technically defensible but materially
misleading without the denominator. *Fix: say "121 wallets per active hourly
window (80 of 120 windows had activity)."*

**D6. Market slide never computes the addressable market.** $305B stablecoins
and $52.6B AI agents are two different markets; the "bridge" between them is
asserted, not sized. There is no SOM. *Fix: frame as "two growing markets the
bridge connects" and add an honest "sizing is unsolved; here is the wedge" line
rather than implying a number.*

**D7. Business model has no numbers.** Settlement fee (no rate), priority tier
(no price), data licensing (no buyer). *Fix: state this is unproven and the
arena is the price-discovery vehicle.*

**D8. Competition table shows us at $0 raised vs $11–12M competitors without an
answer.** *Fix: the moat is the evidence/authority split + 65k-record dataset +
deterministic evaluator — a combination, stated as such.*

## P2 — polish

**D9.** verify.sh prints "all day-file hashes match", not "ALL PASS" as the
video script claims. Align the quoted output.

**D10.** The video names Circle products only loosely. The required transcript
must name each product and where it appears in code — make the narration say
the names out loud.

## What is already strong (keep)
- Attack-closure table, race design rationale, sybil economics — genuinely good.
- On-chain evidence table with real hashes.
- "Do not trust our arithmetic — recompute it" framing.
- Founder-caveat honesty (founder-funded, unaudited, $0 revenue).
