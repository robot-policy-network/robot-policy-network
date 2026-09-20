# Traction attribution — template for the 91-agent question

**Why this file exists.** The traction dataset shows 91 unique agent addresses
submitting 483 scored rounds. The single most damaging question a reviewer can
ask is: *"How many humans are behind those 91 addresses?"* If we cannot answer
with evidence, the honest default assumption is a sybil campaign, and the
traction figure collapses from "adoption" to "one person with 91 keys."

**Status: TEMPLATE — every section needs founder input before this document is
cited anywhere. Do not fill it with guesses.**

---

## What we can already say (from the data itself)

These statements are derived from `participants.json` and are defensible today:

- 91 addresses submitted at least one scored round; **49 submitted exactly one
  round**; no address exceeded 81 rounds.
- Distinct active addresses per day: 14 (09-02) → 33 (09-03) → 47 (09-04).
- 18 of 483 records (3.7%) arrive inside sub-second bursts; the largest is 12
  records in one second from 12 distinct addresses.
- All records use the deterministic simulator path (`mode: "sim"`).

**What this pattern suggests:** many participants appear for one round and
never return, while a small tail of addresses (81, 59, 38 rounds) account for a
large share of volume. That is consistent with a broadcast/announcement that
many independent agents tried once, plus a small number of heavy users. It is
**also consistent with** one operator running many keys. The dataset cannot
distinguish these, which is exactly why the attribution below matters.

## Sections the founder must fill in

### A. How participants learned about the flow

- [ ] Was there a public announcement? (X post, KOL thread, Discord, group chat)
      — provide link(s) and dates.
- [ ] Was there an event, campaign, bounty, or KOL push in the 09-02..09-04
      window? Name it and link it.
- [ ] Were the addresses recruited anywhere (community, influencer, bot list)?

### B. Outreach channels used (with evidence)

| Channel | Date | Evidence (post URL, screenshot, invite link) | Notes |
|---|---|---|---|
| | | | |

### C. Relationship to participants, if any

- Were any addresses run by people you know personally? How many, honestly?
- Were any addresses operated by you or on your behalf? (The dataset already
  excludes the two known non-user addresses; disclose anything else.)
- Were participants incentivized (token, reward, airdrop, prize)? If yes, by
  what and how much? Incentivized participation is still valid traction, but it
  must be labeled as incentivized.

### D. What you can and cannot claim afterwards

| If you can evidence... | You may claim... |
|---|---|
| A public post/campaign driving agents to the flow | "91 agent addresses participated following a public campaign on <channel>, <date>" |
| Named participants willing to confirm | "N independent operators have confirmed participation" |
| Nothing attributable | Say exactly that, and do **not** imply independent adoption. "91 unique addresses ran the flow" remains true; "91 users" is not supportable. |

## Non-negotiable rule

If the honest answer to "how many humans?" is "one operator with many keys,"
then the traction dataset must be reframed as a **load test / integration
demonstration** rather than adoption evidence — which is still valuable (it
proves the flow and the dataset pipeline work at volume), but the application
must say so. A traction figure that collapses under one interview question is
worse than a smaller figure stated precisely.
