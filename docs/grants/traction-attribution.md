# Traction attribution — template for the 91-agent question

# Traction attribution — the 217-wallet question, answered

**Status: FILLED 2026-09-20 (founder-confirmed).** The founder has confirmed
that the participant community was recruited through **posts on X (Twitter)**
(@StonkRobotics and associated posts), not through purchased traffic, bots, or
third-party networks. This section records that confirmation and states
precisely what it does and does not let us claim.

---

## The attribution

| Question | Answer (founder-confirmed) |
|---|---|
| Where did the 217 wallets come from? | **X (Twitter) publication** — the project's own account and community posts about the live arena |
| Was traffic purchased? | No — recruitment was organic X distribution |
| Were participants incentivized? | Yes — the arena is a **free-to-play competition** (99.7% free-tier). Winning windows earn the free mint slot; no payment was made to participants |
| Were any wallets operated by the founder? | Only the launch-day end-to-end test wallet; all other participants are external |
| How many distinct humans? | **Unknown and not claimed.** 217 wallets recruited via X is the defensible figure; we do not assert 217 people |

## Why the cohort is 208-on-day-one

The arena opened on **2026-09-16** (Arc mainnet mint open). X distribution
front-loads: a post reaches its audience in hours, not weeks. 208 of 217
addresses arrived on day one and only 9 followed — which is what an
announcement-driven X cohort looks like, and what a purchased-bot cohort would
*also* look like. The distinction is behavioural, and it is in the data:

- **median per-address answer diversity 0.988** — 91.2% of wallets submitted
  near-unique plans every round. A bot network replaying a scripted payload
  does not do that.
- **82% of the cohort remained active 4+ days later**, 123 wallets active all
  five days — sustained voluntary return after an announcement, not a
  one-shot airdrop farm.
- Where farming *does* appear, we name it: the four heaviest wallets
  (~1,350 rounds each, ~26-second cadence, answer diversity ≈0.09) are visibly
  cache-replaying. That is disclosed in `traction-highlights.md`, not hidden.

## What this lets us claim (and what it does not)

| Claim | Supportable? |
|---|---|
| "217 wallets were recruited through X and formed a sustained community" | **Yes** — founder-confirmed sourcing + behavioural evidence above |
| "82% retention across five days with ~121 wallets competing hourly" | **Yes** — re-derivable from the dataset |
| "217 users" / "217 unique humans" | **No** — wallets are not people |
| "organic growth" | **Not yet** — 9 new addresses post-launch; acquisition is unproven |
| "paid demand" | **No** — 0 priority entries |

## Non-negotiable rule for anyone writing about this

Use **"217 wallets recruited via X"**, never "217 users". If a reviewer asks
for human counts, the honest answer is that we can evidence wallets, sourcing,
and behaviour — not headcount — and that answering it properly would require
optional identity linking, which the arena deliberately does not do.


---

## Data appendix (what the dataset itself shows)

- 217 addresses submitted at least one scored round; **only 3 submitted exactly
  one round**; the median address submitted 297 rounds; the heaviest submitted
  1,381.
- Daily volume: 14,027 / 11,247 / 13,812 / 22,086 / 3,966 (partial) across
  09-16..09-20 — the window starting exactly at the Arc mainnet mint open.
- 2.7% of records arrive inside sub-second bursts (max 8/second) — consistent
  with parallel agent submissions during race windows.
- All records use the deterministic simulator path (`mode: "sim"`).
