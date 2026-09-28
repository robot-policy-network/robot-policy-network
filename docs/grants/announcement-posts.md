# Announcement Posts — Arc Builders Fund + Circle Developer Grants

Single-post versions. Use the English one as primary (Circle/Arc are US-based);
the Chinese one as a follow-up hours later.

**Status to state accurately:** both applications were *submitted*. Neither has
been accepted, awarded, or acknowledged beyond an automated confirmation.
Never write "we raised" / "we were funded" / "Circle invested."

**Always include:** the contract address and the repo. Reviewers verify, and
that is the point of the post.

_Added 2026-09-21._

---

## English (primary)

We submitted **StonkRobotics** to the **Arc Builders Fund** and the **Circle Developer Grants**.

We're building the missing primitive of the agentic economy: **how a machine gets paid for work you can actually verify.**

Every existing design collapses into one signature — the same key that says "this work is good" also says "pay me." A compromised evaluator pays itself. That's the structural flaw, and it's why "agents get paid" still hasn't happened.

Our answer is to **separate evidence from authority**.

`EvaluationEscrow`, deployed on Arc mainnet, releases USDC only when two independent signatures validate:
🔏 `EvaluationAttestation` — the evaluator signs *what was built and how well it executed*
✍️ `ReleaseAuthorization` — the payer signs *whether to pay*

Neither key can move money alone. Not a multisig. Not a timelock. A hard split of evaluation evidence from payment authority.

Scoring isn't an LLM deciding. It's a deterministic simulator **executing** agent-submitted action plans across seeded perturbations:
▸ A plan that doesn't run scores zero — seed gating is multiplicative, so "almost works" is worth nothing
▸ Winning plans can't be copied — every goal carries a distinct physical constant
▸ Keyword stuffing loses — answer length vs. score correlates **r = −0.395**
▸ The reference trajectory never leaves the server
▸ 85 Foundry tests; CI re-runs a full settlement on every push

This isn't a whitepaper. Since Arc mainnet opened:
🔹 **65,138** scored rounds
🔹 **217** wallet addresses
🔹 **67** real robot trajectory tasks, sliced from DROID
🔹 **5** consecutive days at 14k–22k rounds/day
🔹 **1 real USDC settlement executed on Arc mainnet** — 4 transactions, verifiable on the explorer

Contract: `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491`

We published the entire scored dataset with SHA-256 hashes and a `verify.sh`, so **every number in this post can be recomputed by anyone.** We published our own weaknesses too — if we claimed this was perfect, you'd find them anyway.

Arc's stated ambition is to be the economic OS for the internet, with agentic economic activity as its first priority. But at the center of that ambition sits a missing primitive: how does a machine get paid for work without a human trusting the machine's word?

We're building it in the open — data, contracts, spec, and our own red-team findings all public.

If you want to settle real work in USDC on Arc, or you want to build an agent that gets paid for what it actually does — come talk to us. DMs open.

$ARC #StonkRobotics #RobotPolicyNetwork #Arc #Circle #USDC #AgenticEconomy #AgenticCommerce #AI #AIAgents #AgenticAI #VLA #Robotics #EmbodiedAI #RobotLearning #Sim2Real #DataCuration #ZeroKnowledge #Cryptography #SmartContracts #Solidity #Ethereum #L2 #Stablecoins #Payments #DeFi #Onchain #Trust #VerifiableComputing #ProofOfWork #OpenSource #Founder #BuildersFund #CircleGrants #Web3

---

## 中文

我们把 **StonkRobotics** 投给了 **Arc Builders Fund** 和 **Circle Developer Grants**。

做的是 agent 经济里最缺的那块原语：**机器如何为一个你能验证的工作拿到钱。**

现有设计都塌缩成一把签名——说"这活干得好"和说"付钱"的是同一把钥匙。被攻破的评估者给自己付钱。这就是结构性缺陷，也是"agent 拿钱"至今没发生的原因。

我们的答案是**把证据和授权彻底分开**。

`EvaluationEscrow` 已在 Arc 主网部署，USDC 释放需要两个独立签名同时成立：
🔏 `EvaluationAttestation`——评估者签*工作是什么、执行得怎么样*
✍️ `ReleaseAuthorization`——付款人签*付不付*

**任何一把钥匙都无法单独动钱。** 不是多签，不是时间锁，是评估证据与付款授权的硬分离。

评分不是 LLM 拍脑袋，是确定性模拟器**实际执行** agent 提交的动作计划，跨种子扰动打分：跑不通 = 0 分（种子门控是乘法的，"差不多能跑"一文不值）；奖励方案抄不走（每个目标有独立物理常量）；灌水无效（长度与分数 **r = −0.395**）；参考轨迹永不下发；85 个 Foundry 测试，CI 每次 push 重跑完整结算。

这不是白皮书。Arc 主网开放以来：**65,138 次评分 · 217 个钱包 · 67 个真实机器人轨迹任务（DROID）· 连续 5 天每天 1.4–2.2 万次 · 1 笔真实 USDC 结算已在主网执行**（4 笔交易，链上可查）。

合约：`0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491`

全部评分数据带 SHA-256 和 `verify.sh` 已公开，**这条推文里每个数字你都能自己重算。** 我们也公开了自己的弱点——要是我们吹得完美，你也会自己找出来。

Arc 要做互联网的经济操作系统，第一优先级是 agentic economic activity。但这个雄心的正中心缺一个原语：**机器如何在不被人类信任的前提下，为工作拿到钱？**

全部公开构建——数据、合约、规范，连我们自己的红队发现都公开。想在 Arc 上用 USDC 结算真实工作，或者想做一个"干得好就拿钱"的 agent，来找我，DM 开放。

$ARC #StonkRobotics #RobotPolicyNetwork #Arc #Circle #USDC #AgenticEconomy #AI #AIAgents #VLA #Robotics #EmbodiedAI #Solidity #Stablecoins #Payments #DeFi #Onchain #BuildersFund #CircleGrants #Web3 #加密 #人工智能 #机器人 #区块链 #稳定币

---

## Numbers referenced (all recomputable)

| Figure | Value | Source |
|---|---|---|
| Settlement contract | `0x479FF86C25d813cD3FA076e2Fe6df2E3d2d77491` | `deployments/arc-mainnet-settlement.json` |
| Scored rounds | 65,138 | `docs/grants/traction-evidence/SUMMARY.json` |
| Wallet addresses | 217 | `participants.json` |
| Robot trajectory tasks | 67 | `SUMMARY.json` |
| Settlements executed | 1 (0.5 USDC, 4 tx) | `deployments/arc-mainnet-settlement.json` |
| Foundry tests | 85 | `forge test` |
| Length/score correlation | r = −0.395 | `traction-highlights.md` |

Recompute everything: `cd docs/grants/traction-evidence && bash verify.sh`

## Known limits of this post (state these if challenged)

- The executed settlement is **founder-funded** and the evaluator key is also the
  provider key — it demonstrates the process, not the security property.
- 217 addresses is a **wallet count**, not 217 people; the top of the table is
  scripted, and there is **no third-party USDC settlement** yet.
- "Submitted" is the only accurate status. No award, no acknowledgement.
