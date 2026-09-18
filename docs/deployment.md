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
