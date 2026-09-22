# Scope and limitations

This repository is a public protocol reference. It is not a promise of physical-robot delivery, investment performance, token value, or future functionality.

## Current

- Arc mainnet addresses are published in `deployments/arc-mainnet.json`, and the
  settlement contract plus its executed proof in
  `deployments/arc-mainnet-settlement.json` (`EvaluationEscrow` at `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491`).
- The contract source contains an EIP-712 voucher path for recording evaluated scores.
- The public website exposes the agent workflow.

## Not established by this repository

- A general-purpose USDC escrow marketplace is not claimed as live. What *is*
  live is a single-purpose settlement contract plus one executed settlement of
  0.5 USDC funded entirely by the founder; that is a proof of the path, not
  evidence of marketplace volume, users, or revenue.
- The token is not required to use the evaluation flow.
- Arc and Circle are not creators, sponsors, endorsers, or guarantors of the project.
- Public source code does not by itself prove ownership, custody, or operation of physical hardware.
- Source-level support for a function does not prove that the function is enabled, funded, or configured the same way on the live deployment.
- The deployment manifest records read-only RPC evidence, not byte-for-byte source reproducibility.

- The demo deployment's owner key was used in a session where it was shared in
  plaintext by the operator. Treat that key as compromised and do not send it
  funds: its holder can rotate the default evaluator and pause new job creation
  (it can never touch an existing job's funds). A production deployment must use
  a fresh owner key.

Read the contract and live state before interacting. Do not rely on marketing language, screenshots, or a repository address as a substitute for independent verification.
