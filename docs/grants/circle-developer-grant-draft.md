# Circle Developer Grant — Long-Form Application Draft

**Status: DRAFT.** Every `<PLACEHOLDER>` must be replaced with founder-confirmed
information before submission. All claims must comply with
[`canonical-fact-sheet.md`](canonical-fact-sheet.md).

---

## One-line summary

StonkRobotics (Robot Policy Network) is an evaluation and verification layer
for autonomous agents and robots on Arc: it produces reproducible scores and
EIP-712 outcome vouchers for agent work, with milestone-based USDC settlement
as the next, specified-but-not-yet-deployed step.

## Problem

Autonomous agents and robot policies increasingly perform economically
meaningful work, but there is no trustworthy bridge between "the agent claims
it did the work" and "a payer should release funds." Scores are opaque,
non-reproducible, and — worse — often wired directly to payment, so an
unverified or manipulated result can move money.

## Product and current implementation

The live system separates **evaluation evidence** from **payment
authorization**:

1. An agent requests a challenge (live at `https://stonkrobotics.xyz/skill/`).
2. The agent submits a mission plan.
3. A deterministic evaluator produces a reproducible score.
4. The score is bound into an EIP-712 voucher (recipient, score, nonce,
   deadline).
5. The voucher is verified and the score recorded on Arc mainnet
   (chain ID `5042`, contract
   `0x6a3B12532F8e562f99e3292380e7f69D32e10B32`).

On top of this live flow, the v1 settlement protocol
(`docs/settlement-spec.md`, frozen at `SPEC_VERSION = 1`) defines two
independent EIP-712 artifacts:

- an `EvaluationAttestation` — evidence that a plan scored X against task T
  under evaluator E. It cannot move funds.
- a `ReleaseAuthorization` — the payer's explicit authorization to pay. It
  cannot move funds by itself either; settlement requires both.

The `EvaluationEscrow` reference implementation ships with 81 passing Foundry
tests covering signature validity, domain separation, deadlines, expiry, and
settlement paths. It is **specified and tested but not yet deployed** to Arc
mainnet.

## Why Arc and why Circle

- The project is Arc-native: its only production deployment is Arc mainnet,
  and the evaluation flow already records outcomes there.
- Arc-native USDC is the natural settlement asset for machine-speed,
  milestone-based agent payments.
- The evidence/authorization split is designed for exactly the kind of
  agentic economic activity Arc is built to host: agents produce verifiable
  outcomes; payers authorize USDC release against them.

## Agentic economic activity

Today: agents complete challenges and receive verifiable, on-chain-recorded
scores. Next: verified outcomes become the trigger condition for
milestone-based USDC funding and settlement, so agent work becomes payable
work with an auditable evidence trail.
## Technical architecture and security boundary

```text
agent → challenge → mission plan → deterministic score
      → EIP-712 EvaluationAttestation (evidence; cannot move funds)
payer → EIP-712 ReleaseAuthorization (authorization; insufficient alone)
      → EvaluationEscrow releases USDC only when both validate
```

- No independent security audit has been conducted.
- Owner-controlled functions and trust assumptions are documented in the
  repository (`SECURITY.md`, `docs/limitations.md`).
- The settlement contract is not deployed; only the evaluation/recording
  flow is live.

## Milestones

> Exact amounts, dates, and counts require founder confirmation.

1. **M1 — Deploy EvaluationEscrow to Arc testnet + mainnet** with the frozen
   v1 spec; publish deployment manifest and verification evidence.
   `<DATE / DURATION>`
2. **M2 — End-to-end settlement demo**: agent challenge → verified outcome →
   USDC release on Arc, with public transaction evidence. `<DATE / DURATION>`
3. **M3 — <CIRCLE PRODUCT INTEGRATION, e.g. Circle Agent Stack / Wallets /
   Contracts — must match the actual implementation plan before claiming>.**
   `<DATE / DURATION>`
4. **M4 — External security review** of the settlement contract.
   `<DATE / DURATION>`

## Budget / use of funds

> Choose one tier after founder confirms the ask.

| Tier | Amount | Allocation |
|---|---|---|
| A | `<AMOUNT>` | Engineering deployment + demo `<X%>`; security review `<X%>`; integration `<X%>` |
| B | `<AMOUNT>` | ... |
| C | `<AMOUNT>` | ... |

## Success metrics (KPI template)

- `<N>` verified agent outcomes recorded on Arc per month by `<DATE>`.
- `<N>` end-to-end USDC settlements executed by `<DATE>`.
- `<N>` unique paying counterparties by `<DATE>`.
- 100% of settlements backed by an on-chain verifiable attestation.

## Team and applicant information

- Applicant: `<PUBLIC NAME — confirm whether "Richard" is the public identity>`
- Entity: individual, DBA "StonkRobotics" `<CONFIRM; Legal Entity Name: N/A if no entity>`
- Email: `<CONTACT EMAIL>`
- Team: solo founder `<CONFIRM — do not add unconfirmed members>`

## Open-source / ecosystem contribution

The full protocol — contracts, frozen specification, tests, and deployment
evidence — is MIT-licensed at
`https://github.com/robot-policy-network/robot-policy-network`, including an
honest limitations document describing what is and is not verified.

## Risks and limitations

- Settlement contract is unaudited and undeployed; M1/M4 address this.
- Solo-founder execution risk.
- Evaluator decentralization is future work; the current evaluator is a
  single deterministic component.
- A general-purpose USDC escrow marketplace is roadmap, not a live claim.

## Public links and deployment evidence

- Website: `https://stonkrobotics.xyz/`
- Agent workflow: `https://stonkrobotics.xyz/skill/`
- Repository: `https://github.com/robot-policy-network/robot-policy-network`
- Arc mainnet contract: `https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32`
- Deployment manifest: `deployments/arc-mainnet.json` (read-only RPC evidence, checked 2026-09-18)
- Video / screenshots / deck: `<LINKS — only if they actually exist>`

