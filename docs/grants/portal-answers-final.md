# Portal answers — FINAL v2 (deepened, character-verified)

Every field is inside its limit and uses the space for mechanism-level detail.
Copy each block verbatim into the corresponding portal field.

---

## Project Name  [36/80]

```
StonkRobotics (Robot Policy Network)
```

## One-liner  [194/200]

```
Evaluation and settlement layer for machine work on Arc: agents do verifiable work, get paid in USDC, and scoring evidence stays separate from payment authority so no scoring key can move money.
```

## What problem are you solving, why does it matter, what has kept it unsolved  [703/750]

```
Arc's first priority is agentic economic activity; the primitive it needs does not exist: paying a machine for work without trusting the machine's word. Agent-payment tools automate the wallet, not the trust: a human still decides. Escrow and oracle designs bind payment to a reported score, so a manipulated result moves money. Human review does not scale. The barrier: evaluation and payment authorization are the same signature, so whoever can produce a score can also spend, and a compromised evaluator pays itself. Robotics mirrors this: trajectories are abundant (DROID 76k+, Open X-Embodiment 1M+), but nothing determines which agent outputs are worth paying for, and therefore worth training on.
```

## What is your solution  [745/750]

```
Live on Arc mainnet: the evaluator signs an EIP-712 EvaluationAttestation of the score; it cannot move funds. The payer signs a ReleaseAuthorization, insufficient alone. release() needs both, so a compromised evaluator can forge results but not pay itself. Scoring is execution-anchored: agents submit structured plans for tasks sliced from real DROID trajectories; a pure-function simulator executes each across perturbation seeds. Score = 100 x (seedsClean/n) x (0.38*align + 0.32*pick + 0.20*precision + 0.10*eff). The seed gate is multiplicative: failing any seed is worth nothing; align is coverage plus progression; pick is an LCS on service order; precision uses per-target constants; eff is asymmetric, so padding distance earns nothing.
```

## Team track record of acquiring the users your solution requires  [499/500]

```
Live since Arc mainnet launch: 65,138 scored rounds from 217 wallets across 67 real robot tasks in five days, median 121 wallets per active hourly window. 82% of wallets returned on 4+ days and 91.2% submit near-unique plans, with median 297 rounds per address: a retained community, not a spike. The settlement contract is on Arc mainnet and one settlement executed end to end. Founder shipped AI2Human Network, the same architecture for human execution, live on Base; 2nd prize, X Layer hackathon.
```

## Where can we verify your traction  [294/300]

```
Settlement proof: repo deployments/arc-mainnet-settlement.json (all tx hashes)
Settlement contract: explorer.arc.io/address/0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491
Evaluation contract: explorer.arc.io/address/0x6a3B12532F8e562f99e3292380e7f69D32e10B32
Dataset: docs/grants/traction-evidence/
```

## Audit findings summary  [495/500]

```
No independent audit has been conducted. Interim assurance: 85 Foundry tests covering signatures, domain separation, deadlines, expiry, replay, both v2 fixes and every settlement path; CI runs a full settlement on every push; one settlement executed on Arc mainnet. Published limitation: planHash is not recomputed on-chain, so a payer skipping off-chain recomputation trusts the evaluator bound the right plan. Review funding is requested as M3; until it publishes, only founder-funded escrows.
```

---

# Technical Roadmap: Grant milestones

**Required format:** `what will exist at completion | Circle product involved | target date | success metric`

**Paste this block into the 1250-char field** [1233/1250]:

```
Agents in the live arena hold and move USDC through Circle Agent Stack primitives instead of direct contract calls | Circle Agent Stack | 2026-11-22 | 25+ real USDC settlements routed through Agent Stack by 2027-01-31, integration open-sourced, evaluator/payer key split unchanged
EvaluationEscrow redeployed under a production owner key, with setEvaluator exercised on a live job | USDC | 2026-12-06 | new address and manifest published; rotation performed on-chain; zero downtime; a reviewer verifies owner powers affect only future jobs, never an existing job's funds
Independent security review of EvaluationEscrow, full report published, all critical/high fixed and retested before any third-party funds are accepted | USDC | 2026-12-20 | report public in the repo; findings fixed with retests; the funding gate holds until publication, so no external deposit ever lands on an unreviewed contract
Public simulator, task manifest carrying keccak256(referenceTrajectory) not the trajectory, and a runner that recomputes scores from published inputs | USDC | 2027-01-10 | executability recomputable by any third party; planHash and resultHash re-derived by a harness; CI pins vectors; a disputed score becomes an auditable artifact
```

## Milestone names (if the form takes name + details separately)

### M1 — Circle Agent Stack integration

**Name** [195/1024]
```
Circle Agent Stack integrated into the live agent workflow: agents hold and move USDC through Circle-native primitives instead of raw RPC calls, in the arena already running 65,138 scored rounds.
```

**Details** [899/2048]
```
Today the live arena's agents settle through direct contract calls. This milestone replaces that path with Circle Agent Stack primitives, so the 217-wallet community transacts through Circle infrastructure end to end: challenge, score, agent-side payment capability, settlement. The evaluator key remains separate from the payer key and release() still requires both signatures, so the integration cannot weaken the evidence/authority split. Delivered as a documented, open-source integration in the public repository, wired into the existing agent skill and exercised by live traffic rather than a greenfield build. The protocol's whole claim is that a machine can be paid for verifiable work; doing that through Circle's own agent-payment surface turns this into a reusable Arc pattern rather than a bespoke settlement path, and gives Circle a working reference at a scale that is already running.
```

### M2 — Production settlement instance

**Name** [143/1024]
```
Production settlement instance: EvaluationEscrow redeployed under a production owner key, with live evaluator rotation exercised on a real job.
```

**Details** [774/2048]
```
The current mainnet deployment is a founder-funded demo whose owner key was handled in a development session and must be treated as compromised. This milestone deploys a clean instance with a production-grade owner key, publishes the new address and deployment manifest, and exercises setEvaluator against a live job to demonstrate the rotation guarantee: rotating the default evaluator can never affect a job that already exists, because each job captures its evaluator at creation. Deliverable: a production instance with a published owner and evaluator policy, plus an on-chain rotation, so a reviewer can verify that owner powers are bounded to future jobs and can never redirect an existing job's funds. The demo instance is retired and its limitations stay documented.
```

### M3 — Independent security review

**Name** [146/1024]
```
Independent security review of EvaluationEscrow, findings published, all critical and high issues fixed before any third-party funds are accepted.
```

**Details** [705/2048]
```
The contract has no independent audit today. Interim assurance is 85 Foundry tests covering signature validity, domain separation, deadlines, expiry, replay, both v2 semantic fixes and every settlement path, plus CI that deploys the contract and runs a complete settlement on every push. That is not a substitute for review of a contract that will hold other people's USDC. This milestone funds a scoped review (contest or boutique reviewer) sized to a roughly 300-line contract, publishes the full report, and fixes every critical and high finding before the contract accepts a single external deposit. The funding gate we already publish stays in force until this completes: only founder-funded escrows.
```

### M4 — Third-party-reproducible evaluation

**Name** [155/1024]
```
Third-party-reproducible evaluation: publish the simulator, task manifest and runner so executability scores can be recomputed from published inputs alone.
```

**Details** [852/2048]
```
Today a third party can verify our hash commitments and on-chain records but cannot independently recompute an alignment score, because the reference trajectory is held server-side and the simulator is unreleased. That trade bought un-gameability at the cost of verifiability, and we document it as an accepted limitation. This milestone closes it without publishing the references: ship the simulator and scorer; publish a task manifest carrying the world state, perturbation seeds and keccak256(referenceTrajectory) rather than the trajectory; publish a runner that reproduces the executability score and the derived planHash and resultHash. CI pins example vectors so drift fails the build. A reviewer can then recompute executability exactly, prove the scorer used the reference it always used, and turn a disputed score into an auditable artifact.
```

