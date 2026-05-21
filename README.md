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
│   ├── 01-spec-generation.md                 # Phase 1 工作流·规格书 9 章节
│   ├── 02-task-breakdown.md                  # Phase 2 工作流·含禁用字段约束
│   ├── 03-task-implementation.md             # Phase 3 Implementer Agent
│   ├── 04-task-verification.md               # Phase 4 Verifier Agent·MATCH-ID 闭环
│   ├── 05-integration-check.md               # Phase 5 工作流·含反作弊门禁
│   ├── 06-coding-constraints-common.md       # 通用编码约束
│   ├── 07-coding-constraints-go.md           # Go 特化约束
│   └── 08-verification-dimensions.md         # 8 大校验维度 checklist
├── templates/
│   ├── PROGRESS.md                           # 运行时进度面板模板
│   ├── REPO_PROFILE.md                       # 仓库画像模板
│   ├── IMPLEMENTATION_SPEC.md                # 实现规格书模板（9 章节必填）
│   ├── SPEC_COVERAGE.md                      # 规格书覆盖率报告模板
│   ├── TASKS.md                              # 任务清单模板·禁用字段
│   ├── tasks.schema.json                     # 任务清单结构化 schema·严格校验
│   ├── TASK_CONTEXT.md                       # 单 Task 上下文模板
│   ├── IMPL_REPORT.md                        # 实现报告模板·MATCH 逐条响应
│   ├── VERIFY_REPORT.md                      # 校验报告模板·多轮对账
│   └── INTEGRATION_REPORT.md                 # 集成校验报告模板·含反作弊表
├── scripts/
│   └── build.sh                              # skill 打包脚本
├── LICENSE
└── README.md                                 # 仅承载 skill 元信息，不放跑批进度
```

## 运行时产物

skill 在被消费的项目仓库内固定使用 `.spec2code/` 目录存放运行时产物：

```
.spec2code/
├── PROGRESS.md                  # 唯一人读进度面板（由 tasks.json 派生）
├── REPO_PROFILE.md
├── IMPLEMENTATION_SPEC.md
├── SPEC_COVERAGE.md             # 方案 → 规格书覆盖率报告
├── TASKS.md
├── INTEGRATION_REPORT.md
├── state/
│   └── tasks.json               # 唯一进度真源（机读）
└── tasks/
    └── T-XXX/
        ├── context.md
        ├── impl_report.md
        └── verify_report.md
```

> 进度真源与人读面板严格分离：`tasks.json` 是机读唯一真源，`PROGRESS.md` 由每个 Phase 完成时**重写**。本仓库根 `README.md` 不放跑批进度，只承载 skill 元信息。

建议把 `.spec2code/` 加入项目的 `.gitignore`（除非你希望把规格书与报告一起进版本管理）。

## 触发词

- 技术方案落地 / 方案转代码 / spec to code
- 按方案编码 / 实现规格书生成
- RFC 落地 / 设计文档实现

## 强约束摘要

以下 4 项是硬阈，涵盖本 skill 最关键的行为约束；完整清单见 [SKILL.md](SKILL.md) 强约束区。

- ❌ **未拿到用户 `✅ approve` 之前不得跳阶段**：Phase 0 / 1 / 2 / 5 末尾都是 STOP 硬闸。
- ❌ **不擅自发挥**：不加规格书外的功能 / 字段 / 错误码；任务拆分中不得出现工作量 / 人天 / story point 等字段。
- ✅ **规格书骨架齐全**：含完整 DDL、Redis 键空间表、关键流程伪代码、边界异常表、配置参数表；`SPEC_COVERAGE.md` 未覆盖=0。
- ✅ **逐任务闭环**：`tasks.json` 严格按 schema 校验；Implementer / Verifier 分离，多轮以 `MATCH-T<task>-<seq>` 对账；重试 ≥3 仍不过必须停流上报；集成校验含反作弊门禁（SPEC_QUESTION=0 / PROGRESS·tasks.json 一致）。

## 当前覆盖范围

- 语言：**Go**（首期）；后续按需扩展 Python / TypeScript / Java
- 场景：互联网后台业务系统（与 `qiq-backend-tech-review` 同一定位）

## 与 `qiq-backend-tech-review` 的关系

| 阶段 | Skill | 职责 |
|---|---|---|
| 方案评审 | `qiq-backend-tech-review` | 8 维度评审 + 上线门禁 |
| 方案落地 | **`qiq-spec2code`** | 规格书 + 任务 + 实现 + 校验 |

两者构成"评审 → 落地"的完整闭环。

## 打包发布

把 skill 打包为可分发的 zip：

```bash
# 默认：版本号取自 git describe（回落到日期戳）
bash scripts/build.sh

# 显式指定版本号
VERSION=v0.1.0 bash scripts/build.sh

# 仅校验产物清单与内部链接，不实际打包
bash scripts/build.sh --no-zip
```

构建产物输出到 `dist/`：

```
dist/
└── qiq-spec2code-<version>.zip
    └── qiq-spec2code/
        ├── SKILL.md
        ├── README.md
        ├── LICENSE
        ├── references/
        └── templates/
```

每次构建都会清理 `dist/` 并重新生成；如需保留多版本产物请构建后立即归档。

构建过程会做以下校验：
- `SKILL.md` 必须存在 `name:` / `description:` frontmatter 字段
- 所有 markdown 内部链接（指向 `.md` / `.json`）目标文件必须存在（仅 WARN，不阻塞）
- `dist/` 已在 `.gitignore` 中忽略

## License

见 `LICENSE`。
