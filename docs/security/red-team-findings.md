# Red-team findings — self-disclosed

**Status: first-party self-disclosure, 2026-09-20.** No external researcher
reported any of this. We are publishing it because a gameable scoring path is
a material fact about a system that intends to gate payments, and because
reviewers should not have to discover it themselves.

---

## RT-1 — The text rubric was trivially gameable (severity: high, resolved by design change)

**Component.** The non-trajectory scoring path: a deterministic
keyword/structure rubric used when no LLM key is configured, and as an LLM
fallback.

**Finding.** The rubric is reverse-engineerable. Its scoring lines reward
recognisable surface features — an ordered step list, an explicit abort
condition, a measurable success criterion, overlap with the brief's tokens, and
an effort band. An answer that satisfies each line as text clears the pass
threshold without demonstrating any actual planning capability. We confirmed
this ourselves: our own field run reports record that a single generic template
scored 80–100 across missions, and that a token-extraction step could construct
near-maximal answers exactly.

**Impact if it had shipped in a payment path.** An agent could earn settlement
for text that looks like a plan while carrying no executable content. Anyone who
read the rubric could farm it at zero cost. In a system whose entire purpose is
"pay for verified work," this is the failure mode that matters most.

**Root cause.** Scoring was anchored to *surface features of the answer*, not to
*what the answer does when executed*. Any rubric over text is a proxy for
capability, and the proxy was cheap to satisfy.

**Remediation shipped.** A trajectory path was introduced: each task carries a
hidden reference trajectory taken from real robot episodes, the submitted plan
must be a **structured action plan**, and the evaluator **executes it** in a
pure-function simulator across seeded perturbations. Scoring then combines two
things that cannot be bluffed from text:

- **executability** — a plan that causes a collision, an over-force grip, a
  safety violation, or a timeout scores zero, regardless of how well written it
  is;
- **alignment** — how closely the executed path reproduces the hidden reference.

All 483 records in the published traction dataset run on this path
(`mode: "sim"`). The rubric's own anti-gaming heuristics (keyword-stuffing and
step-count penalties) are documented in the code, but they are a mitigation for
a fundamentally proxy-based scorer, not a fix.

**Residual risk (accepted).** The text-rubric path still exists in the
codebase for non-trajectory missions and as an LLM fallback. It is gameable by
construction. **Policy adopted:** a rubric-scored or LLM-scored result must
never gate a settlement. Only a deterministic, execution-anchored score may be
wired to `EvaluationEscrow.verifyResult`. The published dataset's `mode` field
exists precisely so this can be audited.

## RT-2 — Scoring anchored to a hidden reference is unverifiable by design (severity: medium, accepted)

**Finding.** Hiding the reference trajectory prevents reverse-engineering, and
simultaneously prevents third parties from independently recomputing the
alignment score. We are trading verifiability for un-gameability.

**Impact.** A provider who believes they were under-scored cannot prove it.
A payer must trust the evaluator's alignment number.

**Containment.** The full analysis, including a concrete proposal to restore
independent recomputability without revealing references, is in
[`../evaluation-reproducibility.md`](../evaluation-reproducibility.md). The
custody risk is contained by the evidence/authorization split: an evaluator
cannot move funds (`settlement-spec.md` §1).

## RT-3 — Determinism is a property of code, not a promise (severity: low, mitigated)

**Finding.** "Deterministic" is only true while the scorer is free of ambient
state. `Date.now()` and `Math.random()` are the classic ways determinism
silently dies.

**Mitigation.** The simulator uses an explicit local `mulberry32` PRNG seeded
per run, with no clock and no global randomness in the scoring path. The
protocol's reproducibility statement is tied to `(world, plan, seed)` tuples,
which is testable rather than rhetorical. CI pins the deploy path and the test
suite; a future CI job should pin scoring vectors (proposal item 4 in the
reproducibility document).

## RT-4 — Prior dataset contains non-user and self-test addresses (severity: low, disclosed)

**Finding.** When publishing the traction dataset we found the protocol's own
`poiSigner` address and an obvious placeholder address (`0xa1a1…`) mixed into
the records, plus two pre-launch founder receipts.

**Handling.** Rather than quietly filtering them, we published the export
unmodified, excluded the non-user addresses from the participant count, reduced
the headline figure from 93 to **91**, and documented the exclusions in the
dataset README. Publishing the raw form means a reviewer can reach the same
conclusion we did rather than trusting our arithmetic.

---

## Why we are publishing this

A settlement protocol whose evaluator can be farmed is not a settlement
protocol; it is a faucet. We found this by attacking our own scorer, and the
architecture that resulted — execution-anchored scoring, plus a hard split
between the party that produces evidence and the party that authorizes payment
— exists because of this finding, not in spite of it.

**Disclosure status:** self-reported, 2026-09-20. No bounty was paid because no
external party was involved. If you find something in this list that is
*understated*, that is a finding worth reporting — see [`../../SECURITY.md`](../../SECURITY.md).
