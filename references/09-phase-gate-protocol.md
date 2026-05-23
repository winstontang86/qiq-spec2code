# Phase Gate 协议（统一 4 步法 + STOP 模板）

> 本文件是所有 Phase 完成动作的**唯一来源**。SKILL.md 与 `references/00~05` 的"Phase N 完成动作"统一指向本文件，禁止在多处复刻。

## 适用范围

- **强制 Gate**：Phase 0 / Phase 1 / Phase 2 / Phase 5。
- **非 Gate**：Phase 3 / Phase 4 是单 Task 内循环，不走本协议；本批 Task 全部 `passed` 后再进入 Phase 5 Gate。

## 四步法（必须全部执行，顺序不可乱）

1. **写产物**：把当前 Phase 应交付的产物文件全部落盘到 `.spec2code/`（详见各 Phase reference 的"Output"小节）。
2. **重写 PROGRESS**：按 [@templates/PROGRESS.md](../templates/PROGRESS.md) 重写 `.spec2code/PROGRESS.md`，把当前 Phase 状态置为 `done`，下一阶段置为 `pending（等待 approve）`，并保证 `tasks.json`（如已存在）状态完全一致。
3. **打印摘要**：在对话中向用户展示本阶段产物的核心摘要（路径 + 关键结论），便于快速 review。
4. **输出 STOP & CONFIRM 段**（见下方模板）并停下，**未收到 ✅ approve 之前禁止调用任何下一阶段的工具**。

## STOP & CONFIRM 模板（原文复用）

```
⏸ STOP & CONFIRM — Phase <N>
本阶段产物：
  - <path-1>
  - <path-2>
核心摘要：
  - <一句话结论 1>
  - <一句话结论 2>
请回复：
  ✅ approve              → 进入 Phase <N+1>
  🔧 revise: <反馈>       → 修订当前阶段产物
  ❌ reject               → 终止流水线
在收到 ✅ 之前不调用任何 Phase <N+1> 的工具。
```

> 加速模式同样必须执行本协议；加速模式只允许压缩 Phase 4 的校验维度，**不允许跳过任何 Gate**。

## 反作弊核对（Phase 5 Gate 专用，叠加在四步法之上）

Phase 5 完成动作除四步法外，必须额外通过以下核对（任一不通过即 `FAIL`）：

- [ ] grep 全仓 `// SPEC_QUESTION:` 必须为 0 条**未解决**项。
- [ ] `tasks.json` 中**不存在** `attempt >= 3 且 status != passed/waived` 的 Task。
- [ ] `.spec2code/PROGRESS.md` 与 `.spec2code/state/tasks.json` 状态完全一致（含 Phase 状态、Task 状态、attempt）。
- [ ] `.spec2code/SPEC_COVERAGE.md` 未覆盖项 = 0（或所有未覆盖均已显式登记豁免）。
- [ ] `TASKS.md` / `tasks.json` 内**无禁止字段**（`工作量 / 工时 / 估时 / 天数 / 人天 / story point / effort / estimateHours / manDays`）。

## 违规即回滚

任何 Phase 在未收到 ✅ approve 前调用了下一阶段的工具，视为违反工作流：

1. 立即停止下一阶段动作；
2. 回滚已写入但未经 approve 的产物（保留 backup 副本）；
3. 在对话中显式道歉并重新执行本 Phase 的第 4 步。
