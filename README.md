# StonkRobotics Fleet Protocol

Open reference implementation for the StonkRobotics robot and AI-agent evaluation protocol.

This repository is the protocol codebase, not a grant attachment. The current public release focuses on the deployed smart-contract interface, Arc deployment evidence, and the boundaries of what is and is not verified.

## Current deployment

- Network: Arc mainnet
- Chain ID: `5042`
- Fleet contract: [`0x6a3B12532F8e562f99e3292380e7f69D32e10B32`](https://explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32)
- ARCROBO token: [`0x90554cEaf18BD5545F4be6520a3077D327727297`](https://explorer.arc.io/address/0x90554cEaf18BD5545F4be6520a3077D327727297)
- Public product: https://stonkrobotics.xyz/
- Agent workflow: https://stonkrobotics.xyz/skill/

The addresses and runtime-code checks are recorded in [`deployments/arc-mainnet.json`](deployments/arc-mainnet.json). The deployment manifest does not claim that this repository is a byte-for-byte reproduction of the deployed bytecode.

## Protocol capabilities

The Solidity contract includes an ERC-721 collection and a Proof-of-Intelligence path. The latter binds an evaluated result to an EIP-712 voucher containing a recipient, quantity, score, nonce, and deadline. The contract verifies the signer, rejects expired vouchers, prevents nonce reuse, and records the score on-chain.

The contract also contains collection-management modules such as whitelist minting, reveal controls, royalties, and owner-controlled configuration. Read the source and deployment state before relying on any module. A function existing in the source does not prove that it is enabled or economically funded on the live deployment.

## Architecture boundary

The live product demonstrates an agent challenge and on-chain verification flow. A general-purpose USDC job escrow and robot-policy marketplace is a future extension, not claimed as deployed by this repository.

```text
agent requests challenge
        ↓
agent submits mission plan
        ↓
evaluation returns a score
        ↓
EIP-712 voucher is signed
        ↓
Arc contract verifies and records the result
```

## Local development

This repository is intended for Foundry. Install dependencies into `lib/` before building, then run:

```bash
forge fmt --check
forge build
forge test -vvv
```

Never put private keys, API keys, signer secrets, challenge secrets, or production environment files in this repository. Mainnet deployment is intentionally not automated by CI.

## Security and limitations

- The contract has owner-controlled functions. Review the owner and live state before interacting.
- An on-chain address is not an endorsement by Arc or Circle.
- The token is separate from the agent evaluation flow and is not required to use the demo.
- Public code and a deployed address do not by themselves establish a claim about physical-asset ownership or performance.
- See [`docs/limitations.md`](docs/limitations.md) and [`docs/deployment.md`](docs/deployment.md).

## Project links

- Website: https://stonkrobotics.xyz/
- X: https://x.com/StonkRobotics
- Telegram: https://t.me/stonkrobotics

## License

MIT. See [`LICENSE`](LICENSE).
