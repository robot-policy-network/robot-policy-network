# Arc integration notes — findings from shipping a real settlement

**Date: 2026-09-20.** These are field notes from deploying and executing a
complete USDC settlement on Arc mainnet (chain 5042). They are published
because they cost us hours and will cost the next Arc builder the same hours.

---

## 1. `forge script --broadcast` cannot send a native-USDC `transferFrom`

**Symptom.** `createJob` (which calls `safeTransferFrom` on Arc's native USDC
at `0x3600000000000000000000000000000000000000`) fails inside `forge script`
with:

```
0x3600...0000::transferFrom(...)
  └─ 0xC6AD664a...::transferFrom(...)  [delegatecall]
      └─ 0x1800...0001::isBlocklisted(<recipient>)  [staticcall]
          └─ ← [OpcodeNotFound] EvmError: OpcodeNotFound
```

`--skip-simulation` does **not** help: forge still runs each transaction
through its local EVM (revm) to build the trace and decide what to broadcast.

**Why.** Arc's native USDC escrow calls a **system precompile** at
`0x1800…0001` for its blocklist check. That address carries one byte of
bytecode (`0xef`), which is an invalid instruction in the EVM. The **Arc node
intercepts calls to it natively** — so real transactions work — but a local
revm simulation has no such interception and executes the `0xef` byte, which
reverts.

**Consequence.** Any Arc project whose flow touches native USDC through a
contract (escrows, marketplaces, payment routers) will see forge refuse to
broadcast, with a confusing `OpcodeNotFound` deep inside the token call. It is
not your contract; it is the toolchain.

**Workarounds that work.**

1. **Broadcast the affected steps with `cast`** instead of `forge script`:
   `cast send <token> 'transferFrom(...)' ...` goes through the node's own
   execution path and succeeds. This is how our settlement proof was executed —
   see `deployments/arc-mainnet-settlement.json`.
2. **Deploy with `forge script` (fine) and transact with `cast`** — deployment
   and any read-only call are unaffected; only txs whose execution path enters
   `isBlocklisted` are.
3. If you need full scripting, drive the transactions from a JS client
   (`ethers`) against the RPC; it uses `eth_estimateGas` on the node, which
   also works.

**What does not work:** `--skip-simulation`, lowering `--gas-limit`, or
reordering calls. Verified experimentally, not assumed.

## 2. Read-only simulation of `transferFrom` is also unreliable

`eth_call` of `transferFrom` from an external client can revert with
`OpcodeNotFound` for the same reason, even though the equivalent real
transaction succeeds. **Do not conclude "USDC is broken on Arc" from a
simulation failure.** Confirm with a real (small) transaction before
redesigning anything — that is what we did.

Note also that a plain `transfer` (no allowance path) simulates and executes
fine, which is a useful way to isolate whether the precompile is the culprit.

## 3. Gas is native USDC, and it is cheap but not free

- Gas is paid in **native USDC** (18-decimal view of the same balance).
- Observed costs on 2026-09-20: a USDC `approve` ≈ 0.009 USDC; an ERC-20
  transfer ≈ 0.009 USDC; the full 4-transaction settlement (deploy + createJob
  + verifyResult + release) fit comfortably inside ~2 USDC total.
- A wallet needs native USDC (not the ERC-20 view) to pay gas. Funding a fresh
  key requires sending *native* value; an ERC-20 transfer alone will not make
  it able to transact.

## 4. EOF-style bytecode exists on Arc mainnet

`0x70997970C51812dc3A010C7d01b50e0d17dc79C8` returns `0xef0100…` as its
runtime code. Our deploy script's "evaluator must be an EOA" guard
(`evaluator.code.length == 0`) correctly refused it. If you generate
deterministic test addresses, check `code.length` before assuming they are
usable as EOAs — some well-known vanity/test addresses are already occupied.

## 5. What this means for the protocol

Nothing in the design changed. The settlement executed exactly as specified:
evidence (evaluator attestation) and authority (payer release) were separate
signatures, and USDC moved only when both validated. The lesson is purely about
tooling: on Arc, **trust the node's execution path over local simulation**.
