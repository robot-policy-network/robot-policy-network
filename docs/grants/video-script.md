# Video Script — Circle Grants submission (max 5:00)

**Circle requires:** a codebase walkthrough showing where Circle tech is
implemented, plus an integration demonstration. It must name each Circle
product and where it appears in the code.

**Setup before recording** — open these, in this order:
1. `contracts/EvaluationEscrow.sol` (editor, font large)
2. `script/EndToEndSettlement.s.sol`
3. Terminal in the repo root
4. Arc explorer, contract page loaded
5. `docs/grants/traction-evidence/`

**Circle products named in this video: USDC (Arc-native), Circle Agent Stack (planned, M3).**

---

## 0:00–0:25 — Hook

**Screen:** README top.

> "An autonomous agent says it finished the job. How do you pay it without
> trusting its word? That is the problem we solve. I'm Richard, founder of
> StonkRobotics. In five minutes I'll show you the contract, the settlement
> that already executed on Arc mainnet, and the mechanism that makes the
> scoring impossible to fake."

---

## 0:25–1:05 — The idea, in one table

**Screen:** the evidence/authority table (open `docs/mechanism-deep-dive.md` §Part 3).

> "The core design is a split. The evaluator signs **evidence** — an EIP-712
> attestation that says 'this plan scored 87 against this task.' That signature
> **cannot move funds**. The payer signs **authority** — a separate EIP-712
> release authorization. And in `release()`, the contract requires **both**.
> Neither key can settle a job alone. The evaluator is a hot key; we assume it
> gets compromised; the design makes that survivable."

---

## 1:05–2:20 — Code walkthrough (the required part)

**Screen:** `contracts/EvaluationEscrow.sol`

> "Let me walk the code.
>
> **`createJob`.** *(scroll)* The payer funds a job. Look at the last line:
> `usdc.safeTransferFrom(msg.sender, address(this), amount)`. That is
> **Circle's USDC on Arc** — the native asset, accessed through its ERC-20
> interface at `0x3600…0000`, six decimals. The escrow holds it. Note the
> order: state is written *before* the transfer, and the function is
> `nonReentrant` — a hostile token cannot re-enter.
>
> **`verifyResult`.** *(scroll)* The evaluator's attestation. It checks the
> state, the signature deadline, the job deadline, that the taskHash matches,
> that planHash and resultHash are non-zero, that score ≤ 100, and — this is
> **v2**, changed after an adversarial review found the hole — that **status is
> consistent with score**: a `failed` attestation can no longer carry a passing
> score. Then it recovers the signer and compares against `job.evaluator`.
> **There is no transfer in this function.** Evidence never moves money.
>
> **`release`.** *(scroll)* The payer's authorization. It requires the state to
> be RESULT_VERIFIED, the score to clear `passScore`, the provider, amount and
> `resultHash` to match what was recorded, and then recovers the **payer's**
> signature. Only after all of that: `usdc.safeTransfer(job.provider, job.amount)`.
>
> And here is the second v2 fix: **a passing result can never be refunded, by
> anyone.** In v1, `refundExpired` was permissionless — so after the deadline a
> stranger, or the payer themselves, could claw back a provider's earned
> payment. Now it reverts with `ResultPassed`. A passing job is settled only by
> `release`."

---

## 2:20–3:00 — Integration demo (the required part)

**Screen:** `script/EndToEndSettlement.s.sol`, then terminal.

> "This script runs the whole flow for real. In `_settle`: it funds a job, then
> signs the attestation **off-chain** with EIP-712 — and note the domain:
> name `EvaluationEscrow`, version `1`, and `verifyingContract` set to the
> deployed address, so a signature for one deployment is useless on another.
> Then a **separate** payer signature for the release. Then `verifyResult`,
> then `release`.
>
> That script was proven in CI on every push. But better — it was run against
> **Arc mainnet**:"

*(terminal)*
```
cast call 0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491 \
  'getJob(uint256)(address,address,address,uint16,uint8,uint64,uint256)' 1 \
  --rpc-url https://rpc.mainnet.arc.io
```
> "Job 1 — state **3**, RELEASED. 500000 units: half a USDC."

*(explorer, the release tx)*
> "And here is the release transaction. The USDC Transfer event: from the
> escrow to the provider. Two independent signatures were required to produce
> that single transfer."

---

## 3:00–3:50 — Why the scoring cannot be faked

**Screen:** `docs/mechanism-deep-dive.md` §Part 1 (the formula).

> "Scoring is where most 'AI evaluation' projects are gameable, so here is the
> actual formula:
>
> `score = 100 × (seedsClean/n) × (0.38·align + 0.32·pick + 0.20·precision + 0.10·eff)`
>
> Every term closes a specific attack.
> **`seedsClean` is multiplicative** — a plan that hits a safety violation on
> any perturbation seed has its whole score cut; on all seeds it is zero. You
> cannot submit something that 'mostly runs'.
> **`align` is coverage *and* progression** — coverage alone lets a straight
> line between the targets score 0.95.
> **`pick` is an LCS on the service sequence** — hitting the right targets in
> the wrong order is penalised.
> **`precision` uses per-target physical constants** — the cut offset is that
> target's stem width, the grip force is `2 × stem_mm × (2 − ripe)`. Those
> numbers differ per target, so **a winning plan cannot be copied to the next
> mission**.
> **`eff` is asymmetric on purpose** — 93% of correct plans come in *shorter*
> than the reference human path; a symmetric ratio would dock honest plans and
> make 'drive extra laps' a strategy."

---

## 3:50–4:30 — Traction

**Screen:** `traction-evidence/`, then run the verifier.

> "This has been running since mainnet launch. 65,138 scored rounds, 217
> wallets, 67 real robot tasks, five consecutive days. Passing and failing
> populations are separated by **90.8 points** — a failing plan scores a median
> of zero because it does not execute.
>
> It is all published. Let me run the verifier."

*(terminal)* `bash verify.sh`
> "It unzips every day file, re-hashes it, and re-derives the stats. You do not
> have to trust our numbers."

---

## 4:30–5:00 — The ask

**Screen:** the milestones table.

> "M1 and M2 are done — deployed and settled, on my own funds. This grant funds
> two things: **M3, integrating Circle Agent Stack** so our live agent
> community transacts through Circle primitives rather than raw RPC; and **M4,
> an independent security review**, because the contract is unaudited and I do
> not want third-party money in it until it is reviewed.
>
> We ship. The contract is on mainnet, the settlement executed, the data is
> public. Thank you."

---

## After recording

- Upload YouTube **unlisted** or Loom; paste the link in the form
- Write the **transcript** (the form requires it, and it must name each Circle
  product and where it appears in the code) — Circle products used:
  **USDC (Arc-native ERC-20, `EvaluationEscrow.createJob` / `release`)**, and
  **Circle Agent Stack (planned, M3)**
- Screenshot the code where USDC is used: the `safeTransferFrom` line in
  `createJob` and the `safeTransfer` line in `release`
