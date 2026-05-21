---
name: qiq-spec2code
description: 把已评审通过的技术方案文档转换为可直接落地的代码实现的工作流。覆盖仓库扫描、实现规格书生成、任务拆分、逐任务实现、逐任务校验、集成校验 6 个阶段，强制每个任务自包含、可验证、与规格书逐字段比对。触发：技术方案落地 / 方案转代码 / spec to code / 按方案编码 / 实现规格书生成 / RFC 落地 / 设计文档实现。
description_zh: 技术方案到代码实现的工作流
description_en: Spec-to-code implementation workflow
disable: false
agent_created: true
version: 0.2.0
---

# qiq-spec2code — 技术方案到代码实现的工程化工作流

## When to use

满足任一条件就启用：

- 用户拿到一份**已评审通过**的技术方案/设计文档/RFC，希望"按方案实现代码"。
- 用户提到关键词：**技术方案落地 / 方案转代码 / spec to code / 按方案编码 / 实现规格书 / RFC 落地 / 设计文档实现**。
- 用户希望对一份较大的方案做**有序、可追溯、可校验**的编码落地，而不是"放飞式"一把梭。

不适用：

- 方案尚未评审通过/还在讨论中——先用 `qiq-backend-tech-review` 做评审。
- 单点小改动（如修一个 bug、加一个字段）——直接改即可。
- 纯前端 UI 实现、纯算法实现——本 skill 的约束清单不匹配。

> 推荐组合：`qiq-backend-tech-review`（评审）→ **`qiq-spec2code`（落地）**。

## 核心原则

1. **规格书是唯一真理**：方案是设计语言，代码是实现语言，规格书是**两者之间无歧义的中间表示**；编码阶段只看规格书，不回头翻原始方案。
2. **任务自包含**：每个 Task 携带实现所需的全部上下文（规格书片段、约束、依赖接口签名、已完成代码），不依赖 AI"记得之前对话"。
3. **逐任务闭环**：实现完立即校验，最多重试 3 次仍不通过则停止流水线、上报。
4. **不擅自发挥**：禁止在规格书之外加功能、改命名、改类型、改错误码；偏差必须显式记录。
5. **复用胜过新建**：仓库已有的能力、分层、选型一律沿用 `REPO_PROFILE.md` §5.5 风格基线；未提供的项才由规格书显式声明。**不要平地起高楼**。
6. **可恢复**：所有中间产物落盘到 `.spec2code/`，支持断点续传。

## 执行模式（先确认模式再开始）

启动时必须先与用户对齐执行模式：

### 完整模式（默认）
- 顺序执行 Phase 0 → Phase 5 全流程。
- 每个 Task 实现完必须经过校验 Agent 校验，校验通过才能进入下一 Task。
- 适合：中大型方案落地、首次为该项目实现核心功能、涉及资金/核心链路。

### 加速模式
- 用户明确说"先快速实现一版/不用每步校验/我自己 review"时启用。
- Phase 4 校验压缩为 4 个核心维度（结构 / 数据结构 / 接口 / 流程），可跳过维度 5/6/7/8。
- Phase 5 集成校验仍必须执行。
- **加速模式不允许跳过 Phase 0 / 1 / 2 / 5 末尾的 STOP & CONFIRM 闸**；只允许压缩 Phase 4 校验维度。
- 适合：原型验证、内部工具、用户具备很强的人工 review 能力。

### 增量续传模式
- 当 `.spec2code/state/tasks.json` 已存在时自动启用。
- 跳过 Phase 0~2，直接从未完成的 Task 继续。
- 用户也可显式要求"接着上次的继续"。

> 用户没明确说时默认用"完整模式"，并把模式选择告诉用户、允许切换。

## Workflow

### Phase 0 — 仓库现状扫描（强制，不可跳过）

**禁止跳过此步直接生成规格书**。如果不知道仓库已经有什么，规格书就会和现实脱节，编码阶段必然返工。

按 [@references/00-repo-profile.md](references/00-repo-profile.md) 执行，产出 [@templates/REPO_PROFILE.md](templates/REPO_PROFILE.md) 的填充版到 `.spec2code/REPO_PROFILE.md`。

至少识别：

- **语言与版本**：从 `go.mod` / `package.json` / `pyproject.toml` 等抽取。
- **依赖管理与构建**：`go mod` / `npm` / `pip`，构建命令、入口文件。
- **目录分层**：是否 DDD / Clean Arch / MVC，已有 `cmd/` `internal/` `pkg/` `api/` 的具体职责。
- **核心依赖框架**：HTTP 框架、ORM、缓存客户端、RPC 框架、日志库、配置库、测试框架。
- **已有公共能力**：错误处理工具、日志中间件、context 包装、trace 注入、限流、鉴权、幂等工具。
- **命名与风格约定**：包名、文件名、错误码、API 路径、错误返回风格。
- **风格基线表**（强制）：把所有维度的现状汇总到 `REPO_PROFILE.md` §5.5，作为 Phase 1 编码约束的唯一引用源。
- **nilaway 工具状态**：识别仓库是否已安装 nilaway；未安装时提示用户 `go install go.uber.org/nilaway/cmd/nilaway@latest`，用户拒绝则在画像中登记降级。
- **空仓库特判**：若仓库基本为空（如只有 LICENSE / README），明确标注为"绿地项目"，后续 Phase 1 需从 0 设计目录结构。

把扫描结果摘要（含风格基线表、nilaway 状态）告诉用户，**让用户确认或纠正**后才能进入 Phase 1。

#### Phase 0 完成动作（必须全部执行）

1. 写入 `.spec2code/REPO_PROFILE.md`。
2. 重写 `.spec2code/PROGRESS.md`（按 [@templates/PROGRESS.md](templates/PROGRESS.md) 模板），把 Phase 0 状态置为 `done`，下一阶段 `Phase 1` 状态置为 `pending（等待 approve）`。
3. 在对话中输出统一 STOP 段：

```
⏸ STOP & CONFIRM
本阶段产物：.spec2code/REPO_PROFILE.md
请回复：
  ✅ approve              → 进入 Phase 1
  🔧 revise: <反馈>       → 修订仓库画像
  ❌ reject               → 终止流水线
在收到 ✅ 之前不调用任何 Phase 1 的工具。
```

### Phase 1 — 方案 → 实现规格书

按 [@references/01-spec-generation.md](references/01-spec-generation.md) 执行，产出 [@templates/IMPLEMENTATION_SPEC.md](templates/IMPLEMENTATION_SPEC.md) 的填充版到 `.spec2code/IMPLEMENTATION_SPEC.md`。

规格书必须包含 9 个章节，**任一章节缺失 / 表格为空即不合格**：

1. 项目结构定义 + **改动文件清单表**（路径 / ➕新增·✏修改 / 一句话职责）
2. **数据存储详设**：完整 DDL（CREATE TABLE+索引+约束）+ Redis 键空间表（key/type/TTL/读写者）+ 一致性约定 + DDL 演进策略
3. 核心数据结构（Go struct + tag + 验证规则 + 默认值）
4. 接口契约（字段级 + 错误码全集 + 幂等键 + 鉴权）
5. 核心流程伪代码（≥3 段；每段含步骤、异常分支、事务边界、回滚、并发约束）
6. **边界与异常路径表**（触发条件 / 检测方式 / 处理动作 / 降级模式 / SLO 影响 / 对应方案章节）
7. 模块依赖关系图 + 实现层次顺序
8. **配置与运行参数**（config schema + 默认值 + 必填项 + 监控指标列表）
9. 编码约束清单（沿用 [@references/06-coding-constraints-common.md](references/06-coding-constraints-common.md) + [@references/07-coding-constraints-go.md](references/07-coding-constraints-go.md) + 风格沿用 `REPO_PROFILE.md` §5.5）

同时产出**规格书覆盖率报告** [@templates/SPEC_COVERAGE.md](templates/SPEC_COVERAGE.md) 到 `.spec2code/SPEC_COVERAGE.md`：列出方案 §X → 规格书 §Y 的映射。**覆盖率不到 100% 不允许进入 Phase 2**。

#### Phase 1 完成动作（必须全部执行）

1. 写入 `.spec2code/IMPLEMENTATION_SPEC.md` 与 `.spec2code/SPEC_COVERAGE.md`。
2. 重写 `.spec2code/PROGRESS.md`，Phase 1 → `done`，Phase 2 → `pending（等待 approve）`。
3. 在对话中输出统一 STOP 段（产物路径替换为本阶段两个文件）。
4. **在收到用户 ✅ 之前，禁止调用任何 Phase 2 的工具**。

> 规格书是后续所有阶段的"金本位"；任何后续偏离都必须以规格书修订的形式落地，不能口头修改。

### Phase 2 — 任务拆分与排序

按 [@references/02-task-breakdown.md](references/02-task-breakdown.md) 执行，产出：

- 人读载体：`.spec2code/TASKS.md`（基于 [@templates/TASKS.md](templates/TASKS.md)）
- 机读载体：`.spec2code/state/tasks.json`（符合 [@templates/tasks.schema.json](templates/tasks.schema.json)）

拆分硬性要求：

- 单 Task 代码量 **200~500 行**（含测试）。预估超 500 行必须继续拆。
- 每个 Task 必须有：唯一 ID、目标、产出文件清单、依赖任务 ID、验收标准、所需规格书章节引用、预估代码量。
- **禁止字段**：`工作量 / 工时 / 估时 / X 天 / X 人天 / story point / effort / estimateHours / manDays`（粒度只用代码量与依赖深度衡量）。
- 按"批次（Batch）"组织，同一 Batch 内任务彼此无依赖，可并行；跨 Batch 严格串行。
- 实现顺序遵循依赖层次：**领域实体 → 仓储接口 → 基础设施实现 → 应用服务 → 接入层**。
- **双产物缺一即不合格**：`.spec2code/TASKS.md`（人读）+ `.spec2code/state/tasks.json`（机读）。两者 Task ID 集合必须完全一致。

#### Phase 2 完成动作（必须全部执行）

1. 写入 `.spec2code/TASKS.md` 与 `.spec2code/state/tasks.json`。
2. 校验：`tasks.json` 通过 [@templates/tasks.schema.json](templates/tasks.schema.json)；TASKS.md 与 tasks.json 的 ID 集合一致；两份文件均不含"禁止字段"。
3. 重写 `.spec2code/PROGRESS.md`，Phase 2 → `done`，Phase 3 → `pending（等待 approve）`。
4. 在对话中输出统一 STOP 段。
5. **在收到用户 ✅ 之前，禁止调用任何 Phase 3 的工具**。

### Phase 3 ↔ Phase 4 — 单 Task 实现/校验闭环

对 `tasks.json` 中每个状态为 `pending` 的 Task，按依赖顺序执行下面的循环。

```
┌──────────────────────────────────────────┐
│ 1. Coordinator 装配 TASK_CONTEXT.md       │
│    （任务描述+规格书片段+约束+依赖签名+    │
│     已完成代码）→ 写入 .spec2code/tasks/  │
│     T-XXX/context.md                     │
│                                          │
│ 2. 调用 Implementer（Phase 3 角色）        │
│    见 references/03-task-implementation  │
│    → 输出代码 + IMPL_REPORT.md            │
│                                          │
│ 3. 调用 Verifier（Phase 4 角色）           │
│    见 references/04-task-verification    │
│    → 输出 VERIFY_REPORT.md（结论）         │
│                                          │
│ 4. 判定                                   │
│   ├ ✅ Pass / ⚠️ Pass-with-issues          │
│   │   → 标记 passed，进入下一个 Task      │
│   └ ❌ Fail（Block）                       │
│       → Coordinator 把 VERIFY_REPORT 中   │
│         所有 MATCH-T<id>-<seq> 问题作为   │
│         追加上下文回喂给 Implementer，    │
│         attempt++，回到第 2 步循环        │
│                                          │
│ 5. 每个 Task 一轮结束后立即同步       │
│    tasks.json + PROGRESS.md 两份状态     │
└──────────────────────────────────────────┘

循环结束当且仅当（满足任一）：
  a) verify_report 结论 ∈ { ✅ Pass, ⚠️ Pass with non-blocking issues }
  b) attempt = 3 且仍 Fail → 立即停止流水线，将 Task 状态置为 `failed`，
     PROGRESS.md 标注 `blocked: T-XXX`，并在对话中向用户报告
```

详见：

- [@references/03-task-implementation.md](references/03-task-implementation.md)（Implementer Agent 的 Role / 输入 / 输出 / Anti-patterns）
- [@references/04-task-verification.md](references/04-task-verification.md)（Verifier Agent 的 Role / 8 大校验维度 / 输出 / Rules）
- [@references/08-verification-dimensions.md](references/08-verification-dimensions.md)（8 大校验维度的逐项 checklist）

> **关键约束**：Implementer 只能看 `TASK_CONTEXT.md`，不能去翻原始方案；Verifier 只能以规格书为标准，不做风格审查。两个角色严格分离，避免"自审自查"。

### Phase 5 — 集成校验

所有 Task 状态变为 `passed` 后执行，按 [@references/05-integration-check.md](references/05-integration-check.md) 执行，产出 `.spec2code/INTEGRATION_REPORT.md`（基于 [@templates/INTEGRATION_REPORT.md](templates/INTEGRATION_REPORT.md)）。

至少包含：

1. **构建/类型检查**：`go build ./...` / `go vet ./...` 必须通过。
2. **nil 安全检查**（强制）：`nilaway ./...` 必须零报告；未安装时按降级流程登记。
3. **测试执行**：`go test ./...` 必须通过；覆盖率不强制门槛但需如实记录。
4. **接口衔接抽样**：从入口到落库选 2~3 条核心链路，逐层 grep 验证传参与错误码贯通。
5. **配置完整性**：所有引用的配置 key 必须在 `configs/*` 中定义。
6. **trace_id / context 全链路**：抽样核对。
7. **风格基线一致性**：对照 `REPO_PROFILE.md` §5.5 核对各 Task 命名/日志/错误处理是否沿用基线。
8. **遗漏回扫**：拉出原始技术方案功能列表与非功能需求列表，逐条核对是否落在某个 Task 中。
9. **结论**：`PASS` / `PASS_WITH_WAIVER` / `FAIL`。

集成校验未通过不允许标记本次落地完成。

#### Phase 5 完成动作（必须全部执行）

1. 写入 `.spec2code/INTEGRATION_REPORT.md`。
2. 反作弊核对（详见 [@references/05-integration-check.md](references/05-integration-check.md) §10）：
   - grep 全仓 `// SPEC_QUESTION:` 必须为 0 条未解决；
   - `tasks.json` 不得存在 `attempt >= 3 且 status != passed/waived` 的项；
   - `PROGRESS.md` 与 `tasks.json` 状态完全一致；
   - `SPEC_COVERAGE.md` 无未覆盖项。
3. 重写 `.spec2code/PROGRESS.md`，Phase 5 → `done` / `blocked`。
4. 在对话中输出统一 STOP 段，让用户最终确认是否上线。

## 状态与产物目录约定

所有中间产物固定写入仓库根目录下的 `.spec2code/`：

```
.spec2code/
├── PROGRESS.md                  # **进度面板（人读单一视图，由 tasks.json 派生）**
├── REPO_PROFILE.md              # Phase 0 产物
├── IMPLEMENTATION_SPEC.md       # Phase 1 产物
├── SPEC_COVERAGE.md             # Phase 1 副产物（方案 → 规格书覆盖映射）
├── TASKS.md                     # Phase 2 人读产物
├── INTEGRATION_REPORT.md        # Phase 5 产物
├── state/
│   └── tasks.json               # **进度真源（机读，唯一）**
└── tasks/
    └── T-XXX/                   # 每个 Task 一个目录
        ├── context.md           # 输入给 Implementer 的上下文
        ├── impl_report.md       # Implementer 的实现报告
        └── verify_report.md     # Verifier 的校验报告
```

### 进度真源约定（强制）

- `.spec2code/state/tasks.json` 是**唯一**的进度真源（机读）。
- `.spec2code/PROGRESS.md` 是**唯一**的人读进度面板，必须由 `tasks.json` + Phase 状态派生重写，禁止手工与 tasks.json 同时维护。
- 仓库根目录 `README.md` 只承载 skill 元信息，**不放跑批进度**，禁止出现 "Phase X [✅] / [ ]" 这类勾选。
- 每个 Phase 完成时必须按本节列出的"Phase N 完成动作"4 步法重写 PROGRESS.md 并贴到对话中。

`.spec2code/` 建议加入 `.gitignore`（除非用户希望把规格书和报告一起提交）。

## 强约束（违反即不合格）

### 顶层硬规则（最优先，违反即立即回滚并道歉）

- ❌ 在 Phase N 完成后未拿到用户 `✅ approve` 之前，调用任何 Phase N+1 的工具 → 视为违反工作流，必须立刻回滚已做的下一阶段动作并道歉。
- ❌ 把"我会假设你同意，继续往下做" / "先一气呵成做完" 作为默认行为 → 禁止。
- ❌ 长对话中以"加速完成"为由绕过 Phase 0/1/2/5 的 STOP & CONFIRM 闸 → 禁止；用户即使说"继续"也必须先把当前阶段产物贴出来确认。

### 通用强约束

- ❌ 不擅自添加规格书外的功能、字段、参数、错误码、接口。
- ❌ 不擅自修改规格书中的命名、类型、默认值。
- ❌ 不擅自做"性能优化"或"代码美化"，除非规格书明确要求。
- ❌ Implementer 不允许直接读原始方案文档；只能看 `TASK_CONTEXT.md`。
- ❌ Verifier 不做风格审查，只做规格符合性校验。
- ❌ 单 Task 实现重试 ≥ 3 次仍不通过，必须停止流水线并上报，不允许"放过去"。
- ❌ Phase 0/1/2/5 的产物未经过用户 review，不允许进入下一 Phase。
- ❌ 风格类决策（日志/HTTP/ORM/测试/命名）凭空声明 —— 必须沿用 `REPO_PROFILE.md` §5.5 风格基线。
- ✅ **Phase 5 集成校验必须运行 `nilaway ./...` 且零报告**（仓库未安装时按降级流程登记）。
- ✅ 实现中如确有疑问，必须在代码中加 `// SPEC_QUESTION: ...` 注释，并在 `IMPL_REPORT.md` 的"规格书偏差"章节显式记录。
- ✅ 所有外部 I/O 必须传 `context.Context` 并设置超时（DB 默认 3s、RPC 默认 1s，规格书可覆盖）。
- ✅ 所有错误必须保留错误链（`%w`），不允许吞错。

## Pitfalls

- **跳过 Phase 0 直接生成规格书** → 规格书定义的目录/依赖/命名与现仓库脱节，所有 Task 返工。
- **Task 拆得过粗（>500 行）** → AI 上下文撑爆 + 实现质量骤降。宁可拆细。
- **Task 拆得过碎（<50 行）** → 任务数爆炸 + 上下文切换成本压过收益。
- **Implementer 自校验当作通过** → AI 自检常常"自我感觉良好"；必须走 Verifier 他校验。
- **校验放水** → 一个 Block 被放过，后续依赖该模块的 Task 连环出错。
- **不记录偏差** → 后期出问题找不到根因。所有偏差必须留痕。
- **跨 Task 共享内存状态** → Implementer 不能依赖"上个 Task 我跟你说过那件事"；每个 Task 必须自包含。

## Verification

跑完后自检以下条目，全部满足才算合格交付：

- [ ] 已声明执行模式（完整 / 加速 / 增量续传）。
- [ ] Phase 0 已产出 `REPO_PROFILE.md` 并经用户 `✅ approve`。
- [ ] Phase 1 已产出 `IMPLEMENTATION_SPEC.md`（9 章节齐全）+ `SPEC_COVERAGE.md`（覆盖率 100%），并经用户 `✅ approve`。
- [ ] Phase 2 已产出 `TASKS.md` + `tasks.json`，两者 ID 集合一致，无禁止字段（工作量/工时/天数/人天/story point/effort 等），每个 Task 满足 200~500 行预估，并经用户 `✅ approve`。
- [ ] 每个 Task 都有独立的 `context.md` / `impl_report.md` / `verify_report.md` 三件套。
- [ ] 每个 Task 的代码与规格书做过逐字段、逐步骤比对。
- [ ] 所有偏差均已记录到 `IMPL_REPORT.md` 的"规格书偏差"章节。
- [ ] 没有任何 Task 处于 `attempt ≥ 3 且未通过` 的状态。
- [ ] Phase 5 集成校验已执行，构建、测试与 `nilaway ./...` 均通过（或登记降级）。
- [ ] Phase 5 已对照 `REPO_PROFILE.md` §5.5 核对风格基线一致性。
- [ ] Phase 5 已完成反作弊：grep `// SPEC_QUESTION:` 0 条未解决；`tasks.json` 无 `attempt≥3 且 !passed/waived`；`PROGRESS.md`/`tasks.json` 状态完全一致；`SPEC_COVERAGE.md` 无未覆盖项。
- [ ] 已对原始方案的功能/非功能需求做遗漏回扫，结论已落在 `INTEGRATION_REPORT.md`。
- [ ] `.spec2code/state/tasks.json` 中所有 Task 状态为 `passed` 或显式 `waived`（含豁免理由）。
- [ ] `.spec2code/PROGRESS.md` 与 `.spec2code/state/tasks.json` 状态完全一致。
- [ ] Phase 5 集成校验报告已给用户 review，且已收到用户对是否上线的最终 `✅ approve`。
