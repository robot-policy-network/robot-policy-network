# Settlement protocol specification

**Status: FROZEN — `SPEC_VERSION = 1`**
**Date: 2026-09-20**

This document freezes the v1 protocol for verified evaluation results and USDC
job settlement. Any change to a hash preimage, a typehash, a state transition,
or an error code requires a new `SPEC_VERSION` and a new contract deployment.
Change history belongs in [`CHANGELOG.md`](../CHANGELOG.md).

> **Deployment status.** `EvaluationEscrow` is **not deployed** on Arc mainnet.
> The address in [`../deployments/arc-mainnet.json`](../deployments/arc-mainnet.json)
> belongs to `UnitreeG1Fleet`, which is a collection contract and has no
> settlement path. See [`limitations.md`](limitations.md).

---

## 1. Scope and the evidence/authorization split

The protocol has two independent halves, and the split between them is the
whole point of the design:

| | Evaluation evidence | Payment authorization |
|---|---|---|
| Producer | Evaluator (deterministic simulator) | Payer (job creator) |
| Artifact | `EvaluationAttestation` | `ReleaseAuthorization` |
| Proves | "this plan scored X against task T under evaluator E" | "I authorize paying P this amount for job J" |
| Can move funds | **No** | **No, by itself** |
| EIP-712 domain | `EvaluationEscrow` / `1` | `EvaluationEscrow` / `1` |
| Typehash name | `EvaluationAttestation` | `ReleaseAuthorization` |

A verified score is never a payment instruction. The evaluator key is not the
payer key, and neither signature is sufficient on its own:
`release()` requires *both*.

Roles:

- **payer** — creates and funds a job; signs `ReleaseAuthorization`.
- **provider** — the address that receives the payout.
- **evaluator** — signs `EvaluationAttestation`; a hot key held by the backend.
  The contract accepts exactly one evaluator address per job, fixed at creation.
- **owner** — may rotate the evaluator *default* and pause new job creation. The
  owner can never redirect an existing job's funds.

---

## 2. Units and decimals

Arc's native USDC has two interfaces over one balance
([docs](https://docs.arc.io/arc/references/evm-differences)):

| Interface | Address | Decimals | Used for |
|---|---|---|---|
| ERC-20 | `0x3600000000000000000000000000000000000000` | 6 | **this protocol** |
| Native | — | 18 | gas only |

**Every USDC amount in this protocol is expressed in ERC-20 units (6 decimals).**
`1_000_000` means 1.00 USDC. This follows Arc's own integration guidance to rely
solely on the ERC-20 interface for balances and transfers.

Two consequences the implementation must respect:

1. `balanceOf` truncates the low 12 decimal places of the native value. An
   amount below `1e-6` USDC is not representable here and must not be offered.
2. A 6-decimal amount is always a whole number of native `1e12` units, so no
   rounding occurs when the ERC-20 interface settles natively. The reverse is
   not true — never read a 6-decimal value into 18-decimal arithmetic.

Note that `UnitreeG1Fleet` charges in **18-decimal** native units
(`TOKEN_PRICE = 5e18`). That is a different subsystem serving the NFT mint.
Amounts from the two subsystems must never be compared or converted implicitly.

---

## 3. Canonical serialization

All hashes in this protocol are `keccak256` over the UTF-8 bytes of a string
produced by the following rules. These rules exist so an independent party can
recompute a hash from a published record without access to our runtime.

1. **Object keys are sorted ascending by UTF-16 code unit**, recursively.
2. **No insignificant whitespace.** No spaces after `:` or `,`.
3. **Strings** are emitted as JSON strings with exactly these escapes:
   `\"` `\\` `\b` `\f` `\n` `\r` `\t`, and `\u00XX` for other C0 controls.
   `/` is **not** escaped. Non-ASCII characters are emitted literally as UTF-8
   (not `\uXXXX`).
4. **Numbers** must be integers. Floats, `NaN`, `Infinity`, and `-0` are
   rejected. Integer values outside `Number.MAX_SAFE_INTEGER` are rejected.
5. **Booleans** are `true`/`false`. **`null` is rejected** — omit the key instead
   so that "absent" has exactly one encoding.
6. Arrays preserve order.

Implementations: [`web/lib/canonical.js`](../../unitree-g1-mint/web/lib/canonical.js)
is the authoritative JavaScript implementation. It is the *only* implementation:
the contract does not canonicalize anything and recomputes no hash. It stores
and compares the 32-byte commitments it is given.

`planHash` uses the plan-only object; `taskHash` uses the task-only object;
`resultHash` uses the full result object. The three preimages are disjoint.

**Why hashing is off-chain.** Canonical JSON is a byte-exact serialization
contract between two implementations; Solidity would be the second. `taskHash`
and `resultHash` are taken as opaque commitments for reasons the contract cannot
argue with — the task contains the hidden reference trajectory (which must never
reach a client) and the result contains fixed-point values that have no cheap
Solidity representation. `planHash` joins them because a second canonicalizer is
a second place for the two sides to disagree, and a disagreement about a hash
preimage is silent: it produces a *different* hash, not an error.

Instead, every commitment is bound at the **signature layer**, where a mismatch
is a revert rather than a silent reinterpretation. The payer signs over
`resultHash` (§4.4), and the result preimage contains `planHash` (§4.2), so the
plan a result was computed from is inside the bytes the payer authorized. That
is the property v1 needs; it does not need the contract to re-derive it. See §10
for what this costs and why it was accepted.

---

## 4. Artifacts

### 4.1 `planHash`

The preimage is the plan exactly as submitted, with keys sorted:

```json
{"ops":[{"op":"grip","state":"open"},{"op":"move","to":"t3"}],"policyId":"string"}
```

- `ops` — the action list, in order. Required, array (may be empty).
- `policyId` — optional string; the provider's own policy identifier.

`planHash` binds the exact byte-level meaning of the submitted plan. The
evaluator signs it inside the attestation and the contract records it on the job
at `verifyResult`, so a job cannot be settled against a plan other than the one
the evaluator scored. Because it also sits inside the `resultHash` preimage
(§4.2), it is transitively covered by the payer's `ReleaseAuthorization`: the
payer's signature is over a result that names this plan. The contract itself
cannot recompute it and does not try (§10).

### 4.2 `resultHash`

The preimage is the canonical result object:

```json
{
  "benchmark":"string",
  "evaluatorVersion":"string",
  "environmentVersion":"string",
  "passScore":"integer 0-100",
  "planHash":"0x…32 bytes",
  "score":"integer 0-100",
  "scoreExact":"string, 2dp",
  "status":"passed|failed"
}
```

- `score` — `scorePlan().score`, integer 0–100. This is the on-chain number.
- `scoreExact` — `scorePlan().scoreExact` rendered as a **string** with two
  decimal places (`"87.35"`). It is a string because it is a fixed-point value,
  not an integer, and rule 4 forbids floats in the preimage. The free race
  already ranks on this value (`_race.js`), so it is part of the signed record.
- `passScore` — the threshold this result was graded against. It is recorded on
  the job (§5) *and* inside the preimage, so the `status` derivation is
  reproducible from the signed record alone rather than from mutable state.
- `status` — `"passed"` when `score >= passScore`, else `"failed"`.
- `benchmark`, `evaluatorVersion`, `environmentVersion` — identify *what* was
  run, so a later evaluator change cannot silently reinterpret an old result.

`resultHash` deliberately does **not** contain `jobId`, `payer`, `provider`,
`amount`, or `taskHash`. Those bind a result to a *payment* or to a *task*;
keeping them out means one result hash can be quoted in more than one context
without being re-signed, and the binding is done by the on-chain job record and
the attestation's own `taskHash`/`planHash` fields instead.

### 4.3 `EvaluationAttestation` (EIP-712)

```solidity
EvaluationAttestation(
    uint256 jobId,
    bytes32 taskHash,
    bytes32 planHash,
    bytes32 resultHash,
    uint256 score,
    uint8   status,        // 1 = passed, 2 = failed
    uint256 deadline
)
```

- `jobId` — binds the attestation to one job; an attestation is not portable.
- `taskHash` — must equal the job's `taskHash`, so a result computed against a
  different task is rejected (`TaskMismatch`).
- `planHash` — the plan this result was computed from. The contract cannot see
  inside `resultHash`, so without this field it would have no way to know which
  plan was scored. It is recorded on-chain for audit; the binding that makes it
  meaningful is that `planHash` is inside the `resultHash` preimage (§4.2), and
  both are signed.
- `score` duplicates the value inside `resultHash` on purpose. The contract
  cannot open the preimage, so it cannot enforce the agreement — but it *does*
  enforce `score <= 100` and it stores `score` as the number `release` grades
  against. A verifier who recomputes `resultHash` therefore gets a second,
  independent check that the signed score is the scored score; a mismatch means
  the attestation is internally inconsistent and should be rejected off-chain.
- `status` uses `uint8` rather than `bool` so a third terminal state can be
  added without a preimage change; v1 defines only `1` and `2`.
- `deadline` — unix seconds; the attestation is rejected at `block.timestamp > deadline`.
  The struct field is named `deadline`; the function parameter is `sigDeadline`,
  because a job has its own `deadline` and the two are independent: an
  attestation may expire before the job does (it is then never usable) but never
  after, since `verifyResult` also requires `block.timestamp <= job.deadline`.

There is deliberately **no `nonce`**. A nonce would defend against replay, but
replay is already impossible: `verifyResult` moves the job out of `FUNDED` and
no transition returns it, so a given attestation can be consumed at most once,
and `jobId` binds it to a single job. The `verifyingContract` in the domain
covers the redeployment case, where ids would restart. Adding a field that can
only ever equal `jobId` would enlarge the signing surface for no added property.

### 4.4 `ReleaseAuthorization` (EIP-712)

```solidity
ReleaseAuthorization(
    uint256 jobId,
    address provider,
    uint256 amount,
    bytes32 resultHash
)
```

- Signed by the **payer**, and the contract requires
  `ECDSA.recover(...) == job.payer`, so no other account can authorize a payout.
- `provider` and `amount` are duplicated from the job record so that what the
  payer saw when signing is what the contract enforces. If either disagrees with
  the job, the transaction reverts.
- `resultHash` binds the authorization to the exact evaluation the payer is
  paying for. A second attestation with a different result cannot be released
  under an authorization signed for the first.
- **No `deadline`.** It is unnecessary: the authorization is bound to one job,
  one provider, one amount, and one result hash, and only the payer can produce
  it. Adding one would only create a way for a valid authorization to lapse for
  no benefit.
- **No `nonce`.** `release()` is single-shot; the job leaves `RESULT_VERIFIED`
  on first success, so the same signature cannot be submitted twice.

Both structs share the domain `EIP712("EvaluationEscrow", "1")` and verify
against `chainId` and the escrow address. This domain is distinct from
`UnitreeG1Fleet`'s, so no signature from the mint flow can ever be replayed here.

---

## 5. State machine

```
   (none) ──createJob──▶ FUNDED ──cancelJob──▶ CANCELLED
                           │  │
               verifyResult│  └─refundExpired (after deadline)─┐
                           ▼                                  │
                    RESULT_VERIFIED ──release──▶ RELEASED      │
                           │                                  │
                           └─refundExpired (after deadline)───┴─▶ REFUNDED
```

| State | Value | Meaning | Allowed next |
|---|---|---|---|
| `FUNDED` | 1 | USDC held by the escrow | `verifyResult`, `cancelJob` |
| `RESULT_VERIFIED` | 2 | A valid attestation is recorded | `release`, `refundExpired` |
| `RELEASED` | 3 | Paid to provider | terminal |
| `REFUNDED` | 4 | Returned to payer | terminal |
| `CANCELLED` | 5 | Payer withdrew before any result | terminal |

An unsigned job has no state; `getJob` on an unknown id returns the zero struct
and `verifyResult`/`release`/`refundExpired` revert with `UnknownJob`.

Transitions:

- `createJob` → `FUNDED`. Requires `amount > 0`, `provider != 0`,
  `deadline > block.timestamp`, `taskHash != 0`, `evaluator != 0`, and
  `0 <= passScore <= 100`. The plan is **not** committed here: the provider
  writes the policy after the job exists, so `planHash` is bound at
  `verifyResult` instead. `createJob` therefore commits only the task, the
  threshold, and the economics — the parts the payer must fix before the
  provider starts work.
- `verifyResult` → `RESULT_VERIFIED`. Requires `state == FUNDED`,
  `block.timestamp <= sigDeadline`, `block.timestamp <= job.deadline`, a valid
  evaluator signature, `taskHash == job.taskHash`, and non-zero
  `planHash`/`resultHash` with `score <= 100` and `status` in `{1, 2}`.
  `planHash` and `resultHash` are recorded here; neither can be changed
  afterwards, because `verifyResult` runs once per job.
- `release` → `RELEASED`. Requires `state == RESULT_VERIFIED`, a valid payer
  signature, and `resultHash`/`provider`/`amount` matching the job.
- `refundExpired` → `REFUNDED`. Requires `block.timestamp > job.deadline` and
  `state` in `{FUNDED, RESULT_VERIFIED}`.
- `cancelJob` → `CANCELLED`. Requires `msg.sender == job.payer` and
  `state == FUNDED`. It exists so a payer can recover funds from a job that will
  never be evaluated; after a result is verified the payer must instead wait for
  the deadline and call `refundExpired`, so a provider is never paid and then
  clawed back.

**One-way rule.** `RESULT_VERIFIED` cannot return to `FUNDED`. A result can be
superseded only by a *new job*, never by a second attestation against the same
one, because `verifyResult` runs once per job.

**One evaluator per job.** `job.evaluator` is captured from the default at
creation. Rotating the default therefore cannot invalidate or re-sign pending
jobs, and a compromised default cannot rewrite results for jobs already issued.
There is no rescoring path: a wrong result costs a new job.

---

## 6. Failure and refund rules

| Situation | Outcome |
|---|---|
| Provider never delivers | `refundExpired` after deadline → full refund to payer |
| Task ran, `score < passScore` | Attestation with `status = 2`. `release` rejects it (`ResultNotPassed`); funds follow the deadline path |
| Task passed, payer never signs | `refundExpired` after deadline → payer refunded |
| Payer abandons before any result | `cancelJob` → immediate refund |
| Evaluator signs a result for a different task | `verifyResult` reverts (`TaskMismatch`) |
| Attestation carries a zero `planHash` or `resultHash` | `verifyResult` reverts (`ZeroPlanHash` / `ZeroResultHash`). "No plan" is not a state that can be attested |
| Evaluator's `planHash` is not the plan that was scored | Not detectable on-chain — the contract cannot open `resultHash`. It is detectable *off-chain*: `planHash` is inside the `resultHash` preimage (§4.2), so any third party recomputing `resultHash` from the published plan gets a different hash and the attestation fails to verify (§10) |
| Attestation expires before submission | `verifyResult` reverts (`AttestationExpired`); job falls back to the deadline path |
| Result verified but release not signed before deadline | `refundExpired` succeeds — the deadline is the backstop for every non-release outcome |
| Neither `release` nor `refundExpired` is called | Funds remain in the escrow indefinitely. There is no automatic execution |

`verifyResult` is permissionless: anyone holding a valid attestation may submit
it, because the attestation is bound to the job and the evaluator is fixed. This
keeps the outcome from depending on our backend staying online to push a
transaction at the right moment.

`refundExpired` is likewise permissionless once the deadline passes, but the
refund always goes to `job.payer`.

The only non-refundable state is `RELEASED`, and reaching it requires three
independent signatures or authorizations (the payer's funding transaction, the
evaluator's attestation, and the payer's release).

---

## 7. Security boundary

- **The evaluator signature is evidence, not authority.** It cannot move funds.
- **The payer signature is authority, not evidence.** It cannot be produced by
  the backend, which never holds payer keys.
- **A `failed` result is not a payment instruction.** The contract rejects
  releasing against `status = 2` outright rather than paying zero.
- **Only deterministic results are settled.** The LLM-based scorer in
  `_poi.js` (`scoreWithRules`, and the `OPENAI_API_KEY` path) produces a score
  for the mint flow only. It must never reach `verifyResult`. A settlement
  attestation must be derived from `scorePlan()`, whose determinism is the
  property being paid for.
- **Vouchers are not interchangeable.** The `PoIVoucher` typehash in
  `UnitreeG1Fleet` has a different name, domain, and field set. It is not valid
  input to `verifyResult`, and `ReleaseAuthorization` is not valid input to
  `mintWithProof`.
- **The owner cannot seize a job.** Owner powers are limited to rotating the
  default evaluator and pausing new job creation. Neither affects an existing
  job's `evaluator` or its funds.
- **Reentrancy.** Every state change precedes its transfer and all transitions
  are guarded, so a malicious ERC-20 is the only reentrancy vector that matters.
- **Residual risk.** The evaluator key is a hot key. Its compromise allows a
  forged *result* on any open job but not a payment: an attacker still needs the
  payer's `ReleaseAuthorization`, and a payer who does not trust a result can
  simply let the deadline pass. Payer key compromise is out of scope — it implies
  loss of the funds directly.

---

## 8. Error codes

Each condition has exactly one revert string, and each is asserted in the tests.

`createJob`
`ZeroAmount`, `ZeroProvider`, `ZeroTaskHash`, `DeadlineInPast`, `ZeroEvaluator`, `BadPassScore`

`verifyResult`
`UnknownJob`, `WrongState`, `AttestationExpired`, `JobExpired`, `BadAttestation`, `TaskMismatch`, `ZeroPlanHash`, `ZeroResultHash`, `BadScore`, `BadStatus`

`release`
`UnknownJob`, `WrongState`, `ResultNotPassed`, `BadAuthorization`, `ProviderMismatch`, `AmountMismatch`, `ResultMismatch`

`refundExpired`
`UnknownJob`, `WrongState`, `NotExpired`

`cancelJob`
`UnknownJob`, `WrongState`, `NotPayer`

Owned / token
`NotOwner`, `Paused`, `ZeroUsdc`, `ZeroEvaluator`

`UnknownJob` is checked before `WrongState` in every function, so an unknown id
is never reported as a state error. Within `verifyResult` the expiry checks run
in the order listed, so when both the attestation and the job have lapsed the
error is `AttestationExpired` (the tighter bound) rather than `JobExpired`.
Within `createJob` the checks run in the order listed, and within `release` the
payer's signature is recovered last, so a malformed job reference is diagnosable
without a signature.

Struct and integer errors are delegated to Solidity's built-in checks (for
example a `uint8` status outside `{1,2}` reverts without a custom message).

---

## 9. Off-chain contract (what the backend must produce)

The backend is responsible for the parts a contract cannot do. For each
settlement-eligible evaluation it must:

1. Resolve the job to its frozen `plan` and `passScore`.
2. Run `scorePlan(task, plan)` with the task's declared `seeds`.
3. Build the result object of §4.2 — including the `planHash` of the exact plan
   that was run — and compute `resultHash`.
4. Sign `EvaluationAttestation` with the evaluator key and a `sigDeadline` no
   later than `job.deadline`.
5. Publish the plan, the result object, and the evaluator version alongside the
   signature, so a third party can recompute both hashes.

Step 3 is the load-bearing one. The evaluator is the only party that can bind
`planHash` to a result, because it is the only party that saw the plan. If it
signs a `resultHash` built from a different plan than the one it ran, nothing
on-chain notices — the check is that a third party recomputing the preimage from
the published plan gets the signed hash back (§10).

The backend must not: hold payer keys, submit `release`, treat a score as a
payment instruction, or produce a settlement attestation from a non-deterministic
scorer.

---

## 10. Accepted limitation: `planHash` is not verified on-chain

`planHash` is the one commitment the contract cannot check, because the contract
never sees the plan. Two options were considered:

**(a) Off-chain hashing, opaque on-chain.** `createJob(provider, amount,
taskHash, passScore, deadline)` commits no plan; `verifyResult` carries a
`planHash` signed by the evaluator, which the contract records but cannot
recompute. Cheap and simple, but the plan binding rests entirely on the
evaluator's signature and on third parties re-deriving `resultHash`.

**(b) On-chain canonicalization.** `createJob(..., Plan calldata plan, ...)`,
with `_canonicalJson` rebuilding the exact preimage in Solidity and reverting on
mismatch. Removes the evaluator's discretion over `planHash` at the cost of a
second implementation of §3, in a second language, that must agree byte-for-byte
with `canonical.js` forever.

**v1 ships (a).** The reason is that (b) buys less than it appears to, and costs
a class of bug that fails silently:

- The plan is written *after* the job exists (the provider submits it), so a
  plan committed at `createJob` is not the plan that will be scored. Making it
  work would require a second plan-committing transition, i.e. another state and
  another signature — a larger surface than the field it protects.
- (b) verifies the *serialization*, not the *evaluation*. A malicious evaluator
  who scores a different plan can still produce a `planHash` that canonicalizes
  correctly from the plan it claims. The property (b) actually enforces is "the
  bytes hash to what they say they hash to", which the signature already gives.
- A duplicate canonicalizer that drifts produces a *different hash*, not an
  error. Every failure mode is a silent one, and the drift is only discoverable
  after a payer has funded a job that can no longer be settled.

What v1 relies on instead is that `planHash` sits inside the `resultHash`
preimage (§4.2) and `resultHash` is what the payer signs (§4.4). So:

- The payer authorizes a payout against a result whose preimage names the plan.
- Any third party can recompute `resultHash` from the published plan and result
  object, using the published `canonical.js`, and compare it to the signed value.
- A mismatch is a *failed verification* of a published artifact, which is exactly
  the check the protocol asks its users to perform, and it is observable without
  our runtime.

The cost is real and is stated rather than hidden: a payer who does not run the
recomputation is trusting the evaluator to have bound the right plan. The
protocol makes that check cheap and publishable; it does not make it automatic.
The alternative (b) would move the trust from "the evaluator signed the plan it
ran" to "our Solidity agrees with our JavaScript", which is not obviously less
trust, only less visible.

The task is likewise not canonicalized on-chain, for a stronger reason: the task
contains the hidden reference trajectory, and the whole scoring model depends on
that reference never reaching the client. `taskHash` is an opaque commitment by
necessity, not by choice.
