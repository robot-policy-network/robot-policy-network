# Changelog

## v2.1 — 2026-09-20: first mainnet settlement executed

`EvaluationEscrow` is deployed on Arc mainnet and a **complete settlement has
executed against it** — the first time USDC has moved through this protocol.

- Contract: `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491` (chain 5042, SPEC_VERSION 2)
- `createJob` escrowed 0.5 USDC: `0x087d419b4914509aabfd8bd5c9bdb28bc49a195a27f83f1c99984a74bd89a961`
- `verifyResult` recorded the evaluator's attestation: `0xad894353ba6f14bae0f51158ee0ee15327dca5e6934499ecac53cdf0f86f14e8`
- `release` moved the USDC after the payer's separate authorization validated: `0x4a8ccd2d47d83c98eff02244f016f926f0565046de4b013d89f21c149cbd0c71`
- Result: job state `3` (RELEASED), provider balance 0 → 500000 (0.5 USDC)

Full evidence: `deployments/arc-mainnet-settlement.json`. This is a
founder-funded proof of the path — not volume, revenue, or third-party
adoption, and the demo owner key must be rotated before production use.

### Added

- `docs/arc-integration-notes.md` — field notes for Arc builders: forge's local
  simulation cannot execute Arc's native-USDC blocklist precompile
  (`0x1800…0001`), so `forge script --broadcast` refuses transferFrom-based
  flows while `cast send` works; gas is native USDC; EOF bytecode already
  exists at well-known test addresses.
- `script/EndToEndSettlement.s.sol` — the complete settlement as a runnable
  script (proven on anvil; CI runs it on every push).

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
