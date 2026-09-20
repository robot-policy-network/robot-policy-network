# Arc Builders Fund — Investor Deck Outline (10–12 pages)

**Status: OUTLINE.** The Builders Fund page asks for an investor deck. Fill
each slide with founder-confirmed numbers only. Never present roadmap items
as current traction, and note that the program is a Circle Ventures internal
initiative — not a fund with a published commitment.

---

1. **Title** — StonkRobotics / Robot Policy Network: the evaluation and
   verification layer for agentic economic activity on Arc. Contact:
   Richard, ritsuyan4763@gmail.com.

2. **Problem** — Agent and robot work is becoming economically meaningful,
   but outcomes are unverifiable and unpayable: scores are opaque,
   non-reproducible, and unverified results can't safely trigger payment.

3. **Solution** — Separate evaluation evidence from payment authorization.
   Reproducible scoring → EIP-712 `EvaluationAttestation` (evidence) +
   payer-signed `ReleaseAuthorization` → USDC settlement only when both
   validate. Frozen v2 spec, 85 passing tests, live evaluation flow on Arc
   mainnet.

4. **Product demo** — Live today: challenge → mission plan → score →
   on-chain verification (`https://stonkrobotics.xyz/skill/`, contract
   `0x6a3B…10B32` on Arc, chain ID 5042). Screenshots + explorer links.

5. **Why Arc-only** — Arc-native USDC settlement, machine-speed finality,
   and an ecosystem built for agentic payments. Sole production deployment
   is Arc mainnet.

6. **Market** — Collection is funded and commoditized: Axis $12M (Hack VC),
   PrismaX $11M (a16z CSX), DROID/OXE's 1M+ open trajectories. Academia
   (SIEVE, arXiv 2607.06442) proves curation is the bottleneck: 50% selected
   data beats 100% raw. The curation+settlement intersection is the open
   layer. `<ADD TAM FIGURES WITH SOURCES BEFORE SUBMISSION>`

7. **Business model** — `<FOUNDER INPUT: e.g. per-verification fee,
   settlement fee on released milestones, curated-dataset licensing.
   Do not state current revenue unless real.>`

8. **Traction** — Live Arc mainnet deployment, deterministic simulator with
   82 DROID-anchored tasks, EIP-712 on-chain verification, frozen settlement
   spec + 85-test suite, MIT-licensed open protocol.
   `<ADD REAL USAGE NUMBERS ONLY IF FOUNDER CONFIRMS>`

9. **Competition / moat** — Axis/PrismaX = collection (no verification or
   settlement); RoboTrain = scoring but centralized 16-member grading, no
   crypto settlement; GAEA/Vana/Fraction AI = data DePIN, no
   trajectory-anchored deterministic evaluation. Our moat is the combination
   none of them has: reproducible evaluation anchored to real robot data +
   an on-chain evidence/authorization payment split.

10. **Roadmap** — Verification (live) → USDC settlement deployment
    (M1: 2026-10-11) → end-to-end settlement demo (M2: 2026-10-25) →
    Circle Agent Stack integration (M3: 2026-11-22) → external security
    review (M4: 2026-12-13) → audited marketplace (2027).

11. **Team** — Solo founder **Richard**, full-stack + smart contracts.
    `<OPTIONAL: 1–2 句真实背景，没有就保持简洁>`

12. **Ask** — **$25,000**（与 Circle Developer Grant 一致的预算框架；若 Builders Fund
    是投资形式则改为展示用款计划而非 grant 金额），use of funds:
    deployment + demo (48%), Circle integration (32%), security review (20%).
    What Arc core-team support would unblock: USDC settlement best
    practices, evaluator decentralization patterns, ecosystem intros to
    agent teams needing verifiable outcomes.
