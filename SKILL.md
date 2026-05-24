---
name: qiq-spec2code
description: 把已评审通过的技术方案文档转换为可直接落地的代码实现的工作流。覆盖仓库扫描、实现规格书生成、任务拆分、逐任务实现、逐任务校验、集成校验 6 个阶段，强制每个任务自包含、可验证、与规格书逐字段比对。触发：技术方案落地 / 方案转代码 / spec to code / 按方案编码 / 实现规格书生成 / RFC 落地 / 设计文档实现。
version: 0.3.0
---

# qiq-spec2code — 技术方案到代码实现的工程化工作流

## When to use

满足任一条件就启用：

- 用户拿到一份**已评审通过**的技术方案 / 设计文档 / RFC，希望"按方案实现代码"。
- 用户提到关键词：**技术方案落地 / 方案转代码 / spec to code / 按方案编码 / 实现规格书 / RFC 落地 / 设计文档实现**。
- 用户希望对一份较大的方案做**有序、可追溯、可校验**的编码落地，而不是"放飞式"一把梭。

不适用：

- 方案尚未评审通过 / 还在讨论中 → 先用 `qiq-backend-tech-review` 做评审。
- 单点小改动（修 bug、加字段）→ 直接改即可。
- 纯前端 UI / 纯算法实现 → 本 skill 的约束清单不匹配。

> 推荐组合：`qiq-backend-tech-review`（评审）→ **`qiq-spec2code`（落地）**。

## 核心原则

1. **规格书是唯一真理**：方案是设计语言，代码是实现语言，规格书是两者之间无歧义的中间表示；编码阶段只看规格书，不回头翻原始方案。
2. **任务自包含**：每个 Task 携带实现所需的全部上下文（规格书片段、约束、依赖签名、已完成代码），不依赖 AI"记得之前对话"。
3. **逐任务闭环**：实现完立即校验，最多重试 3 次仍不通过则停止流水线、上报。
4. **不擅自发挥**：禁止在规格书之外加功能、改命名、改类型、改错误码；偏差必须显式记录。
5. **复用胜过新建**：仓库已有的能力、分层、选型一律沿用 `REPO_PROFILE.md` §5.5 风格基线；未提供的项才由规格书显式声明。**不要平地起高楼**。
6. **可恢复**：所有中间产物落盘到**工作仓库根目录**下的 `.spec2code/`，支持断点续传（"工作仓库"= 用户实际要落地代码的代码仓库，详见 §状态与产物目录约定）。

## 执行模式（先确认模式再开始）

启动时必须先与用户对齐执行模式：

| 模式 | 适用场景 | 与 Phase Gate 的关系 |
|---|---|---|
| **完整模式（默认）** | 中大型方案、首次实现核心功能、涉及资金/核心链路 | 顺序执行 Phase 0→5；每个 Task 必须 Verifier 校验通过 |
| **加速模式** | 原型验证、内部工具、用户具备较强人工 review 能力 | Phase 4 校验压缩为 4 个核心维度（结构/数据结构/接口/流程）；**Phase 0/1/2/5 的 Gate 不允许跳过** |
| **增量续传模式** | `.spec2code/state/tasks.json` 已存在，或用户要求"接着上次的继续" | 跳过 Phase 0~2，直接从未完成 Task 继续 |

> 用户没明确说时默认用"完整模式"，并把模式选择告诉用户、允许切换。

## 渐进披露阅读索引（按需加载）

主入口只放骨架，**细节按 Phase 加载对应 reference**，不要一次性灌进上下文：

| 角色 / 阶段 | 必读 reference | 必读 template |
|---|---|---|
| Phase 0 仓库画像 | `references/00-repo-profile.md` | `templates/REPO_PROFILE.md` |
| Phase 1 规格书生成 | `references/01-spec-generation.md` + `references/06-coding-constraints-common.md` + `references/07-coding-constraints-go.md` | `templates/IMPLEMENTATION_SPEC.md`, `templates/SPEC_COVERAGE.md` |
| Phase 2 任务拆分 | `references/02-task-breakdown.md` | `templates/TASKS.md`, `templates/tasks.schema.json` |
| Phase 3 Implementer | `references/03-task-implementation.md` + `references/06` + `references/07` | `templates/TASK_CONTEXT.md`, `templates/IMPL_REPORT.md` |
| Phase 4 Verifier | `references/04-task-verification.md` + `references/08-verification-dimensions.md` | `templates/VERIFY_REPORT.md` |
| Phase 5 集成校验 | `references/05-integration-check.md` | `templates/INTEGRATION_REPORT.md` |
| 所有 Gate（0/1/2/5） | `references/09-phase-gate-protocol.md` | `templates/PROGRESS.md` |

## Workflow

### Phase 0 — 仓库现状扫描（强制）

按 [@references/00-repo-profile.md](references/00-repo-profile.md) 执行，产出 `.spec2code/REPO_PROFILE.md`（基于 [@templates/REPO_PROFILE.md](templates/REPO_PROFILE.md)）。

关键产出：**§5.5 风格基线表**——后续所有 Phase 的"风格沿用"唯一引用源；以及 nilaway 工具状态（未安装即提示安装或登记降级）。

绿地项目（仓库基本只有 LICENSE / README）必须显式标注，由 Phase 1 从零设计目录。

完成动作：按 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) 执行 Gate。

### Phase 1 — 方案 → 实现规格书

按 [@references/01-spec-generation.md](references/01-spec-generation.md) 执行，产出：

- `.spec2code/IMPLEMENTATION_SPEC.md`（基于 [@templates/IMPLEMENTATION_SPEC.md](templates/IMPLEMENTATION_SPEC.md)）：必须含 **9 个章节**，任一缺失或表格为空即不合格。
- `.spec2code/SPEC_COVERAGE.md`（基于 [@templates/SPEC_COVERAGE.md](templates/SPEC_COVERAGE.md)）：方案 §X → 规格书 §Y 映射，**未覆盖项 = 0** 才允许进入 Phase 2。

§9 编码约束的来源：

- **核心条款** → 摘自 [@references/06-coding-constraints-common.md](references/06-coding-constraints-common.md) + [@references/07-coding-constraints-go.md](references/07-coding-constraints-go.md)。
- **风格类条款**（日志、HTTP、ORM、测试库、命名）→ **必须沿用 `REPO_PROFILE.md` §5.5**，禁止凭空声明。

完成动作：按 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) 执行 Gate。

> 规格书是后续所有阶段的"金本位"；任何后续偏离都必须以规格书修订的形式落地，不能口头修改。

### Phase 2 — 任务拆分与排序

按 [@references/02-task-breakdown.md](references/02-task-breakdown.md) 执行，产出双载体：

- 人读：`.spec2code/TASKS.md`（基于 [@templates/TASKS.md](templates/TASKS.md)）
- 机读：`.spec2code/state/tasks.json`（符合 [@templates/tasks.schema.json](templates/tasks.schema.json)）

硬性要求：

- 单 Task 代码量预估 **200~500 行**（含测试）；超 500 行必须继续拆。
- 每个 Task 必含：唯一 ID、目标、产出文件清单、依赖任务 ID、验收标准、规格书章节引用、预估代码量。
- **禁止字段**：`工作量 / 工时 / 估时 / X 天 / X 人天 / story point / effort / estimateHours / manDays`（粒度只用代码量与依赖深度衡量）。
- 按"批次（Batch）"组织：同 Batch 内可并行，跨 Batch 严格串行。
- 实现顺序遵循依赖层次：领域实体 → 仓储接口 → 基础设施实现 → 应用服务 → 接入层。
- 双产物 ID 集合必须完全一致；`tasks.json` 必须通过 schema 校验（`additionalProperties:false`）。

完成动作：按 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) 执行 Gate。

### Phase 3 ↔ Phase 4 — 单 Task 实现 / 校验闭环

对 `tasks.json` 中每个状态为 `pending` 的 Task，按依赖顺序执行下面循环（**不走 Phase Gate**，每个 Task 一轮内部闭环）：

```
┌──────────────────────────────────────────────────┐
│ 1. Coordinator 装配 TASK_CONTEXT.md                │
│    （任务描述+规格书片段+约束+依赖签名+已完成代码）  │
│    → .spec2code/tasks/T-XXX/context.md             │
│                                                    │
│ 2. 调用 Implementer（references/03）               │
│    → 代码 + .spec2code/tasks/T-XXX/impl_report.md  │
│                                                    │
│ 3. 调用 Verifier（references/04 + 08）             │
│    → .spec2code/tasks/T-XXX/verify_report.md       │
│                                                    │
│ 4. 判定                                            │
│    ├ ✅ Pass / ⚠️ Pass-with-issues                  │
│    │   → 标记 passed，进入下一 Task                │
│    └ ❌ Fail (Block)                                │
│        → 把 VERIFY_REPORT 中所有 MATCH-T<id>-<seq> │
│          回喂给 Implementer，attempt++，回到第 2 步 │
│                                                    │
│ 5. 每轮结束立即同步 tasks.json + PROGRESS.md       │
└──────────────────────────────────────────────────┘

终止条件（满足任一）：
  a) verify_report 结论 ∈ { ✅ Pass, ⚠️ Pass with non-blocking issues }
  b) attempt = 3 且仍 Fail → 立即停止流水线，
     Task 状态置 `failed`，PROGRESS.md 标注 `blocked: T-XXX`，
     向用户报告
```

> **角色严格分离**：Implementer 只能看 `TASK_CONTEXT.md`，**不读原始方案**；Verifier 只以规格书为标准，不做风格审查。两者使用不同会话/视角，避免"自审自查"。

### Phase 5 — 集成校验（**本地范围**）

所有 Task 状态变为 `passed` 后执行，按 [@references/05-integration-check.md](references/05-integration-check.md) 执行，产出 `.spec2code/INTEGRATION_REPORT.md`（基于 [@templates/INTEGRATION_REPORT.md](templates/INTEGRATION_REPORT.md)）。

**范围（强制）**：本阶段只做**本地可独立完成**的校验，不依赖任何线上 / 集成环境。

- ✅ **本地强制项**：构建/类型 → **nilaway 增量门禁**（仅对增量代码强制；存量遗留登记不处理）→ `go test`（默认 build tag 全通过；外部依赖类测试若跳过需登记原因）→ 静态接口衔接抽样（grep）→ 配置完整 → trace/context 静态抽样 → 风格基线一致性 → 遗漏回扫 → 反作弊与状态一致性。
- ❌ **不在本 skill 范围**：起服务到"等待请求"的 dry-run 启动校验、灰度/降级/报警端到端验证、K8s rollback 真实演练、连真实下游的 e2e 烟测——交由独立的发布/SRE 流程处理；本阶段对这些项**不出"通过"结论**，只在报告中静态登记代码/配置层面是否落地。

完成动作：按 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) 执行 Gate（含 Phase 5 专用的反作弊核对）。本 Gate 的 ✅ approve 含义是"本地校验门禁放行"，不等同于"上线放行"。

## 状态与产物目录约定

**位置锚点（强制）**：本 skill 的所有读写操作都以**用户的工作仓库根目录**（即调用 skill 时 shell 的 `pwd`，亦即用户实际要落地代码的代码仓库）为基准。具体含义：

- 所有 `.spec2code/...` 路径一律相对于工作仓库根目录，**禁止**写到 skill 自身目录、临时目录或上级目录。
- Phase 0 扫描的"仓库"= 工作仓库根目录；Phase 3 的代码改动也只发生在该仓库内。
- 启动时若发现工作目录不像代码仓库（无 `.git/` 且无任何源码 / 构建文件），先与用户确认是否走错目录，确认后再继续。
- 多仓场景：一次会话只服务一个工作仓库；若需要跨仓，分别启动 skill。

所有中间产物固定写入**工作仓库根目录下的 `.spec2code/`**：

```
.spec2code/
├── PROGRESS.md                  # 进度面板（人读单一视图，由 tasks.json 派生）
├── REPO_PROFILE.md              # Phase 0 产物
├── IMPLEMENTATION_SPEC.md       # Phase 1 产物
├── SPEC_COVERAGE.md             # Phase 1 副产物（方案 → 规格书覆盖映射）
├── TASKS.md                     # Phase 2 人读产物
├── INTEGRATION_REPORT.md        # Phase 5 产物
├── state/
│   └── tasks.json               # 进度真源（机读，唯一）
└── tasks/
    └── T-XXX/                   # 每个 Task 一个目录
        ├── context.md
        ├── impl_report.md
        └── verify_report.md
```

### 进度真源约定（强制）

- `.spec2code/state/tasks.json` 是**唯一**的进度真源（机读）。
- `.spec2code/PROGRESS.md` 是**唯一**的人读进度面板，必须由 `tasks.json` + Phase 状态派生重写，禁止手工与 tasks.json 同时维护。
- 仓库根 `README.md` 只承载 skill 元信息，**不放跑批进度**。
- 每个 Phase 完成时按 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) 重写 PROGRESS.md。

`.spec2code/` 建议加入 `.gitignore`（除非用户希望把规格书与报告一起提交）。

## 红线（Hard Rules — 违反即立即回滚并道歉）

- ❌ **越过 Gate**：在 Phase N 完成后未拿到用户 `✅ approve` 之前，调用任何 Phase N+1 的工具。
- ❌ **默认放行**：把"我假设你同意，继续往下做" / "先一气呵成做完"作为默认行为。
- ❌ **以加速为由绕过 Gate**：长对话中以"加速完成"为由跳过 Phase 0/1/2/5 的 STOP & CONFIRM；用户即使说"继续"也必须先把当前阶段产物贴出来确认。
- ❌ **越权读方案**：Implementer 在编码阶段读原始方案文档（只能看 `TASK_CONTEXT.md`）；除 Phase 5 遗漏回扫外的所有阶段同样禁止。
- ❌ **校验放水**：单 Task 实现重试 ≥ 3 次仍不通过，把状态改为 `passed/waived` 而不停流水线。
- ❌ **规格书外发挥**：擅自添加规格书外的功能/字段/参数/错误码；擅自修改规格书的命名/类型/默认值；擅自做"性能优化"或"代码美化"。
- ❌ **风格凭空声明**：风格类决策（日志/HTTP/ORM/测试/命名）不沿用 `REPO_PROFILE.md` §5.5。

## 软约束（违反需显式记录，详见对应 reference）

下列约束在编码 Phase 由 Implementer / Verifier 执行；本主入口仅做指针，**条款细则与默认值见对应 reference**，避免与之漂移：

- 类型与单位、超时与外部调用、幂等与并发、错误处理 → [@references/06-coding-constraints-common.md](references/06-coding-constraints-common.md)
- Go 特化（context、错误链、nil 安全 G4、数据库底线、测试） → [@references/07-coding-constraints-go.md](references/07-coding-constraints-go.md)
- 8 大校验维度 → [@references/08-verification-dimensions.md](references/08-verification-dimensions.md)
- Phase 5 nilaway 增量门禁（仅对增量代码强制，存量遗留登记不处理）与降级流程 → [@references/05-integration-check.md](references/05-integration-check.md) §1.5

实现中如确有疑问，必须在代码中加 `// SPEC_QUESTION: ...` 注释，并在 `IMPL_REPORT.md` "规格书偏差"章节显式记录；Phase 5 反作弊核对会 grep 该注释，未解决项必须为 0。

## Pitfalls

- **跳过 Phase 0 直接生成规格书** → 规格书定义的目录/依赖/命名与现仓库脱节，所有 Task 返工。
- **Task 拆得过粗（>500 行）** → AI 上下文撑爆 + 实现质量骤降。宁可拆细。
- **Task 拆得过碎（<50 行）** → 任务数爆炸 + 上下文切换成本压过收益。
- **Implementer 自校验当作通过** → AI 自检常常"自我感觉良好"；必须走 Verifier 他校验。
- **校验放水** → 一个 Block 被放过，后续依赖该模块的 Task 连环出错。
- **不记录偏差** → 后期出问题找不到根因。所有偏差必须留痕。
- **跨 Task 共享内存状态** → Implementer 不能依赖"上个 Task 我跟你说过那件事"；每个 Task 必须自包含。

## Verification（按章节核对，不再逐条复述）

跑完后按以下 8 条章节级核对，全部 ✅ 才算合格交付（细则下沉到对应 reference）：

- [ ] **执行模式**已声明（完整 / 加速 / 增量续传）。
- [ ] **Phase 0** 产物 `REPO_PROFILE.md` 已 approve；§5.5 风格基线表完整；nilaway 状态已登记。
- [ ] **Phase 1** 产物 `IMPLEMENTATION_SPEC.md`（9 章节齐全）+ `SPEC_COVERAGE.md`（覆盖率 100%）已 approve；§9 风格条款全部沿用 §5.5。
- [ ] **Phase 2** 产物 `TASKS.md` + `tasks.json` 已 approve；ID 集合一致；通过 `tasks.schema.json`；无禁止字段；满足 200~500 行预估。
- [ ] **Phase 3/4** 每个 Task 都有完整三件套（`context.md` / `impl_report.md` / `verify_report.md`），无 `attempt ≥ 3 且未通过`，所有偏差落在 `impl_report.md`。
- [ ] **Phase 5** `INTEGRATION_REPORT.md` 已产出；`go build` / `go vet` / `go test`（默认 build tag）全通过；`nilaway ./...` 已运行且**增量报告（`nilaway.incr.txt`）为零**（存量遗留可保留并登记）；遗漏回扫已对照原始方案；线上动作类需求仅静态登记，不出"通过"结论。
- [ ] **反作弊核对**（详见 [@references/09-phase-gate-protocol.md](references/09-phase-gate-protocol.md) §反作弊）全部通过。
- [ ] **最终 Gate**：Phase 5 报告已给用户 review 并收到 `✅ approve`（含义为"本地校验门禁放行"，是否上线由独立发布/SRE 流程裁定）。
