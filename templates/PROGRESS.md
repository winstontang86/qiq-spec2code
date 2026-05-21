# 进度面板（PROGRESS）

> 由各 Phase 完成动作时**重写**。本文件是 spec2code 的**唯一人读进度视图**，由 `.spec2code/state/tasks.json` + 各 Phase 产物状态派生。**禁止与 `tasks.json` 同时手工维护**——状态以 `tasks.json` 为准。

- 更新时间：{{datetime}}
- 执行模式：☐ 完整 ☐ 加速 ☐ 增量续传
- 当前活跃 Phase：{{Phase X}}
- 当前阻塞项：{{无 / blocked: T-XXX，原因 ...}}

---

## 1. Phase 进度

| Phase | 名称 | 状态 | 产物 | 备注 |
|---|---|---|---|---|
| 0 | 仓库现状扫描 | {{pending / in_progress / done / blocked}} | `.spec2code/REPO_PROFILE.md` | {{...}} |
| 1 | 实现规格书生成 | {{...}} | `.spec2code/IMPLEMENTATION_SPEC.md` + `.spec2code/SPEC_COVERAGE.md` | {{覆盖率 X/Y}} |
| 2 | 任务拆分与排序 | {{...}} | `.spec2code/TASKS.md` + `.spec2code/state/tasks.json` | {{Task 总数 / Batch 数}} |
| 3 | 逐任务实现 | {{...}} | `.spec2code/tasks/T-XXX/impl_report.md` | {{已完成 X/N}} |
| 4 | 逐任务校验 | {{...}} | `.spec2code/tasks/T-XXX/verify_report.md` | {{passed X / failed Y}} |
| 5 | 集成校验 | {{...}} | `.spec2code/INTEGRATION_REPORT.md` | {{PASS / PASS_WITH_WAIVER / FAIL}} |

> 状态枚举：`pending` / `in_progress` / `done` / `blocked` / `waived`。

---

## 2. Task 进度（来自 tasks.json）

| Task ID | 名称 | Batch | 状态 | Attempt | 关联报告 |
|---|---|---|---|---|---|
| T-001 | {{...}} | 1 | {{...}} | {{0/1/2/3}} | `.spec2code/tasks/T-001/` |
| T-002 | {{...}} | 1 | {{...}} | {{...}} | `.spec2code/tasks/T-002/` |
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

**汇总**：

- 总数 N，passed X，failed Y，pending Z，waived W
- 阻塞项：{{无 / T-XXX：attempt 已达 3 仍未通过}}

---

## 3. 下一步动作

- [ ] {{当前需要执行的下一步，例如"等待用户对 IMPLEMENTATION_SPEC.md 的 approve"}}
- [ ] {{...}}

是否需要用户确认：☐ 是 ☐ 否
等待用户回复：☐ approve ☐ revise: <反馈> ☐ reject

---

## 4. 历史变更

| 时间 | 事件 | Phase |
|---|---|---|
| {{datetime}} | Phase 0 done | 0 |
| {{datetime}} | Phase 1 done，覆盖率 32/32 | 1 |
| {{...}} | {{...}} | {{...}} |

---

## ⏸ 等待用户确认

> 当本面板 §3 中"是否需要用户确认 = 是"时，**禁止**执行下一 Phase 的任何工具。请回复：
>
> - ✅ approve              → 进入下一 Phase
> - 🔧 revise: <反馈>       → 修订当前 Phase 产物
> - ❌ reject               → 终止流水线
