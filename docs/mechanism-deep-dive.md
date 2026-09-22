# Mechanism Deep Dive — why each part is built the way it is

**Purpose.** This is the engineering rationale behind the protocol, written at
the level of "what attack does this term close." It is the source document for
the pitch deck, the video script, and any technical review.

---

## Part 1 — The scoring function

```
score_exact = 100 × (seedsClean / n) × (0.38·align + 0.32·pick + 0.20·precision + 0.10·eff)
score       = round(score_exact)                      // the on-chain number
```

Every factor is there to close a specific way of faking competence.

### `seedsClean / n` — robustness gate (multiplicative)

The plan is executed against the world under several perturbation seeds. **A
hard violation on ANY seed multiplies the whole score by a fraction of 1** —
and a hard violation on every seed makes it zero.

Why multiplicative rather than additive: a plan that only works on a lucky seed
is not 80% of a plan. It is a plan that will hit a worker. The gate makes
"write a plan that mostly works" worth nothing.

### `align` (0.38) — coverage AND progression, not coverage alone

`1 − 0.5·(pathDistance + progressionDistance)`. Two distances, averaged.

The code comment states the reason plainly: **coverage alone is lenient enough
that a straight line between targets scores ~0.95.** A straight line is not a
solution, it is a sketch of one. Progression alone would punish any legitimate
re-route around a moving worker — a *better* plan would score worse.
Together they say: be on the right route, at the right stage of the job.

### `pick` (0.32) — order-aware, via longest common subsequence

`LCS(serviced order, reference order) / |reference order|`.

Membership alone is bluffable: "I cut all three targets" is true whether you
cut them in the correct sequence or in the order that happened to be nearest.
LCS on the *sequence* makes order cannot be faked, and it degrades gracefully —
servicing 2 of 3 in the right order scores 2/3, not 0.

### `precision` (0.20) — per-target physical parameters

Two published rules:

```
offset_mm = target.stem_mm                  // cut this far clear of the body
force_n   = 2 × stem_mm × (2 − ripe)        // riper stem → softer → less force
```

Tolerance: 20% of `grip_max_n`; force must also stay under it.

**Both are per-target.** `stem_mm` and `ripe` differ target to target, so the
numbers cannot be written once and reused — across targets or across missions.
This is what makes a winning plan non-copy-pasteable: the plan that won
mission 67 has the wrong constants for mission 68.

The constants are *published* on purpose. As the code says: a rubric nobody can
see is not a skill test, it is a lottery where everyone scores zero on the same
term. Published, it is the part of the score a careless plan loses and a careful
one keeps.

### `eff` (0.10) — asymmetric on purpose

`clamp(refLen / max(refLen, runLen), 0, 1)` — at or under the reference distance
is full marks; every extra unit of travel costs.

The asymmetry is deliberate and the comment explains why with data: **93% of
correct plans come in SHORTER than the reference (median 0.62×)** because the
reference is a recorded human path and the direct route between the same targets
is simply shorter. A symmetric ratio would dock the median honest plan ~4 points
and, worse, would make "drive extra laps to pad the distance" a scoring
strategy.

The `runLen > 0` gate exists so that a plan that never moves cannot collect full
efficiency marks by dividing the reference length by itself.

### Why the two-decimal `scoreExact` exists

A competent generic plan lands on **95–97 for nearly everyone**, so ranking on
the rounded integer would make the top of a race window a **mass tie** decided
by the tie-break rather than by the plan. Two decimals separate plans that
really do differ — and that is what the race ranks on. The integer is what goes
on-chain.

---

## Part 2 — The race

Time is sliced into fixed windows (`epoch = floor(now / RACE_WINDOW_SEC)`).
**Each window holds exactly one free-mint slot**, every operator in the window
solves the *same* mission, and the slot goes to the best score **decided only
when the window closes**.

### Why not first-past-the-post

The earlier rule gave the slot to the first passing plan. That made the race a
**latency contest**: an agent closes the loop in ~90 s, a person pasting a brief
into a chat model on a phone needs two or three minutes, so **a human could
never win one no matter how good the plan was.**

Deciding on best score at the close makes submission time worth nothing and plan
quality worth everything. That is the only version of this race where a human
and an agent can compete in the same lane — which matters, because the point of
the dataset is to capture *good planning*, not fast HTTP.

### Why copying is useless by construction

Ranking uses `scoreExact` and **only a strictly better score displaces the
leader**. A plan copied from someone else's post scores *exactly* what the
original did, so it fails to displace it, and the operator who actually solved
the mission keeps the slot.

The copy fails not because it is detected, but because it is *identical* — and
identical is not better.

### The sybil cap that actually bites

Wallets are free to create and the holdings-based gate reads 0 forever once a
winner stops bothering to mint on testnet. So per-wallet caps are soft. The cap
that bites is **per source (IP) per rolling 24 h (default 4)**.

There is also a hard-won observation in the code: raising the per-wallet daily
cap does not reward a good agent, it **deletes free robots** — three wallets
took 16 of the first 31 windows and turned them into 3 slots, because the
contract's `WL_MAX_PER_WALLET` is 1, so every win past the first converts to
nothing for the winner while consuming a window nobody else could win.

### Try-bounding

`RACE_PER_WINDOW_TRIES` (default 8) bounds brute-forcing plan variants inside a
window. An agent can iterate — but a bounded number of times, and each attempt
costs a graded round that lands in the dataset.

---

## Part 3 — The settlement split

```
agent  → challenge → plan → deterministic score
       → EIP-712 EvaluationAttestation   (evidence; CANNOT move funds)
payer  → EIP-712 ReleaseAuthorization    (authority; insufficient alone)
       → EvaluationEscrow releases USDC only when BOTH validate
```

Neither key can settle alone. The evaluator key is a hot key that may be
compromised; the design assumes it will be, and makes that survivable: a
compromised evaluator can forge a *result* on an open job but still cannot pay
itself, because the payer's separate signature is required.

Deployed on Arc mainnet at `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491` and
executed once end to end (0.5 USDC).

---

## The summary a reviewer should take away

This is not "we score agents with an LLM and pay them." Each component is
engineered against a named attack:

| Attack | Closed by |
|---|---|
| Bluff a plan that does not execute | multiplicative seed gate → 0 |
| Look up the answer | reference held server-side, never returned |
| Reverse-engineer the rubric | feedback names only public-state terms |
| Copy a winning plan | per-target cut constants |
| Hit targets in the wrong order | LCS on sequence |
| Pad distance for efficiency marks | asymmetric ratio capped at 1 |
| Win by being fast, not good | best-score-at-close |
| Arbitrage the integer rounding | 2-decimal ranking |
| Spin up wallets | per-IP daily cap |
| Farm the same window | per-window try cap |
| Have the evaluator pay itself | evidence/authority key split |
