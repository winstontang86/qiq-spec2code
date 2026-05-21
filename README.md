# qiq-spec2code

把已评审通过的技术方案文档转换为可直接落地的代码实现的工作流 skill。

## 定位

`qiq-spec2code` 是一个 **agent skill**，用于在拿到一份评审通过的技术方案/RFC/设计文档之后，按工程化方式驱动 AI 落地代码：

```
技术方案 ──[ qiq-backend-tech-review 评审 ]──→ 评审通过的方案
              │
              ▼
          [ qiq-spec2code 落地 ]
              │
              ▼
            代码
```

## 6 阶段流程

1. **Phase 0 — 仓库现状扫描**：盘清家底，识别语言、依赖、分层、命名风格、公共能力。
2. **Phase 1 — 实现规格书生成**：把方案翻译为字段级、错误码级、流程级精确的规格书。
3. **Phase 2 — 任务拆分与排序**：拆为 200~500 行可独立实现/校验的最小任务单元。
4. **Phase 3 — 逐任务实现**：Implementer Agent 严格按规格书编码。
5. **Phase 4 — 逐任务校验**：Verifier Agent 按 8 大维度做规格符合性校验。
6. **Phase 5 — 集成校验**：构建/测试/接口衔接/全链路 trace/遗漏回扫。

## 目录结构

```
qiq-spec2code/
├── SKILL.md                                  # skill 主入口
├── references/
│   ├── 00-repo-profile.md                    # Phase 0 工作流
│   ├── 01-spec-generation.md                 # Phase 1 工作流
│   ├── 02-task-breakdown.md                  # Phase 2 工作流
│   ├── 03-task-implementation.md             # Phase 3 Implementer Agent
│   ├── 04-task-verification.md               # Phase 4 Verifier Agent
│   ├── 05-integration-check.md               # Phase 5 工作流
│   ├── 06-coding-constraints-common.md       # 通用编码约束
│   ├── 07-coding-constraints-go.md           # Go 特化约束
│   └── 08-verification-dimensions.md         # 8 大校验维度 checklist
├── templates/
│   ├── REPO_PROFILE.md                       # 仓库画像模板
│   ├── IMPLEMENTATION_SPEC.md                # 实现规格书模板
│   ├── TASKS.md                              # 任务清单模板
│   ├── tasks.schema.json                     # 任务清单结构化 schema
│   ├── TASK_CONTEXT.md                       # 单 Task 上下文模板
│   ├── IMPL_REPORT.md                        # 实现报告模板
│   ├── VERIFY_REPORT.md                      # 校验报告模板
│   └── INTEGRATION_REPORT.md                 # 集成校验报告模板
├── LICENSE
└── README.md
```

## 运行时产物

skill 在被消费的项目仓库内固定使用 `.spec2code/` 目录存放运行时产物：

```
.spec2code/
├── REPO_PROFILE.md
├── IMPLEMENTATION_SPEC.md
├── TASKS.md
├── INTEGRATION_REPORT.md
├── state/
│   └── tasks.json
└── tasks/
    └── T-XXX/
        ├── context.md
        ├── impl_report.md
        └── verify_report.md
```

建议把 `.spec2code/` 加入项目的 `.gitignore`（除非你希望规格书与报告一起进版本管理）。

## 触发词

- 技术方案落地 / 方案转代码 / spec to code
- 按方案编码 / 实现规格书生成
- RFC 落地 / 设计文档实现

## 强约束摘要

- 不擅自添加规格书外的功能/字段/错误码
- 不擅自修改规格书定义的命名/类型/默认值
- 单 Task 重试 ≥ 3 次仍不通过必须停止流水线、上报
- Implementer 与 Verifier 严格分离
- 所有偏差必须显式记录

## 当前覆盖范围

- 语言：**Go**（首期）；后续按需扩展 Python / TypeScript / Java
- 场景：互联网后台业务系统（与 `qiq-backend-tech-review` 同一定位）

## 与 `qiq-backend-tech-review` 的关系

| 阶段 | Skill | 职责 |
|---|---|---|
| 方案评审 | `qiq-backend-tech-review` | 8 维度评审 + 上线门禁 |
| 方案落地 | **`qiq-spec2code`** | 规格书 + 任务 + 实现 + 校验 |

两者构成"评审 → 落地"的完整闭环。

## License

见 `LICENSE`。
