# Deployment verification

The live project uses Arc mainnet, chain ID `5042`, and RPC `https://rpc.mainnet.arc.io`.

## Public addresses

| Component | Address | Evidence |
|---|---|---|
| Fleet contract | `0x6a3B12532F8e562f99e3292380e7f69D32e10B32` | [Arc explorer](https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32) |
| ARCROBO token | `0x90554cEaf18BD5545F4be6520a3077D327727297` | [Arc explorer](https://explorer.arc.io/address/0x90554cEaf18BD5545F4be6520a3077D327727297) |
| ARCROBO/USDC pool | `0xd3e373b283a28407d40fc2791d759a4bb75c25d277f3bcf9863fc6a2af2afe35` | [Arc explorer](https://explorer.arc.io/address/0xd3e373b283a28407d40fc2791d759a4bb75c25d277f3bcf9863fc6a2af2afe35) |

## Verification scope

On 2026-09-18, read-only RPC checks confirmed chain ID `0x13b2` (`5042`) and non-empty runtime code at the fleet and ARCROBO addresses. This repository does not claim that the current source reproduces the deployed bytecode, because compiler metadata, constructor arguments, deployment transaction, and explorer verification have not been independently reconstructed here.

The repository therefore separates:

- address/code-existence evidence;
- source code reference;
- live product links;
- claims that require further verification.

## Native USDC

The project references Arc native USDC at:

```text
0x3600000000000000000000000000000000000000
```

Always verify the current network and asset configuration before signing a transaction.

## Deploying `EvaluationEscrow` (not yet deployed)

`EvaluationEscrow` holds USDC for a job and releases it only when an
evaluator-signed attestation **and** a payer-signed release authorization both
validate. It is specified and tested (85 Foundry tests) but **not deployed** —
see [`settlement-spec.md`](settlement-spec.md) and [`limitations.md`](limitations.md).

The deployment is scripted in
[`script/DeployEvaluationEscrow.s.sol`](../script/DeployEvaluationEscrow.s.sol).

```bash
# dry run against Arc mainnet (simulates only)
EVALUATOR_ADDRESS=0x<evaluator-hot-key> \
  forge script script/DeployEvaluationEscrow.s.sol --rpc-url arc

# broadcast
EVALUATOR_ADDRESS=0x<evaluator-hot-key> \
  forge script script/DeployEvaluationEscrow.s.sol --rpc-url arc --broadcast
```

The script refuses to proceed unless:

- `EVALUATOR_ADDRESS` is a non-zero **EOA** (a hot key, not a contract);
- the evaluator address differs from the deployer/owner address, because the
  spec requires the evaluator key and the payer key to be distinct roles
  (`ALLOW_SAME_OWNER_AND_EVALUATOR=1` overrides this for local dry runs only);
- `USDC_ADDRESS` has runtime code, on every chain except when running a local
  anvil smoke test (`ALLOW_USDC_WITHOUT_CODE=1`).

On Arc mainnet (`5042`) `USDC_ADDRESS` defaults to the verified native-USDC
ERC-20 interface above. On any other chain it must be supplied explicitly, so a
deployment cannot silently settle in the wrong asset.

### Local smoke test (how this script was verified)

```bash
anvil &
DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
EVALUATOR_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
USDC_ADDRESS=0x3600000000000000000000000000000000000000 \
ALLOW_USDC_WITHOUT_CODE=1 \
  forge script script/DeployEvaluationEscrow.s.sol \
    --rpc-url http://127.0.0.1:8545 --broadcast
```

Expected: the contract deploys, `owner()` returns the deployer, `evaluator()`
returns the supplied hot key, `usdc()` returns the supplied token, and
`nextJobId()` is `1`. Passing the deployer address as `EVALUATOR_ADDRESS`
reverts with `Deploy: evaluator must differ from owner`.

### After deploying — the two things that must stay in sync

1. Record the new address in `deployments/<network>.json` with the block number
   and the deployment transaction hash, so the deployment itself is verifiable
   (the existing Arc manifest deliberately records only read-only RPC evidence).
2. Set the off-chain signer's EIP-712 domain to `name = "EvaluationEscrow"`,
   `version = "1"`, `chainId = <network>`, `verifyingContract = <new address>`.
   Both halves of the protocol must use the identical domain or every signature
   fails. The domain is distinct from `UnitreeG1Fleet`'s on purpose, so no
   voucher from the mint flow can ever be replayed into settlement.
