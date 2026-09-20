# Changelog

## v2 — 2026-09-20 (pre-deployment)

Semantic corrections found by an adversarial review. No hash preimage and no
typehash changed; the EIP-712 domain (`EvaluationEscrow` / `1`) is unchanged and
is decoupled from `SPEC_VERSION` (see `docs/settlement-spec.md` changelog).

### Changed

- `EvaluationEscrow.verifyResult` now enforces `status ≡ (score ≥ passScore)`
  and reverts `StatusMismatch`. Under v1 an evaluator could sign `status =
  failed` with a passing score and `release` — which checked only the score —
  would have paid it, contradicting the spec's own §7 promise.
- `EvaluationEscrow.refundExpired` reverts `ResultPassed` on a verified passing
  result. Under v1 the permissionless refund could claw back a provider's
  earned payment after the deadline and race the payer's own `release`.
- Spec updated to match: state diagram, §6 failure table, §7 security boundary,
  and the §4.2 `status` field description.

### Added

- `references/canonical.js` — the canonicalizer the spec had referenced but
  never published. Implements §3 exactly; pinned by
  `references/canonical.test.mjs` (zero dependencies) and exercised in CI.
- `script/DeployEvaluationEscrow.s.sol` — deploy path with unsafe-input guards,
  proven by an anvil smoke test in CI.
- Error codes: `StatusMismatch`, `ResultPassed`.
- Contract constant `SPEC_VERSION = "2"`.

## Unreleased (v1-era)

- Established a clean public protocol reference for Arc deployment evidence.
- Separated current contract capabilities from future USDC settlement work.
