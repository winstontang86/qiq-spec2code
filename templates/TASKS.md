# 任务清单（TASKS）

> 由 Phase 2 产出。每个 Task 必须满足 200~500 行预估、单一职责、边界明确、依赖最小、可独立测试。
>
> **禁止字段**（任一命中即不合格）：`工作量` / `工时` / `估时` / `X 天` / `X 人天` / `story point` / `effort` / `estimateHours` / `manDays`。粒度度量只用"代码量预估 + 依赖深度"。

- 来源规格书：`.qiqskills/spec2code/IMPLEMENTATION_SPEC.md`
- 产出时间：{{datetime}}
- Task 总数：{{N}}，Batch 总数：{{M}}

---

## Batch 1：基础脚手架（无依赖，可并行）

### T-001：项目脚手架搭建

- **目标**：创建项目目录结构、初始化 `go.mod`、配置文件模板
- **产出文件**：
  - `go.mod`
  - `cmd/server/main.go`（空 main，仅验证编译通过）
  - `configs/config.yaml`（配置模板）
  - `internal/` 目录结构（空 package 占位）
- **依赖**：无
- **验收标准**：
  - [ ] `go build ./...` 通过
  - [ ] 目录结构符合规格书 §1
- **预估代码量**：~50 行
- **上下文需求**：规格书 §1（项目结构定义）

### T-002：领域实体定义 - {{Entity}}

- **目标**：定义 `{{Entity}}` 结构体、状态枚举、状态转换方法
- **产出文件**：
  - `internal/domain/entity/{{entity}}.go`
  - `internal/domain/entity/{{entity}}_test.go`
- **依赖**：T-001
- **验收标准**：
  - [ ] 字段与规格书 §3 完全一致
  - [ ] 状态枚举值与规格书一致
  - [ ] 状态转换方法覆盖所有合法转换
  - [ ] 非法转换返回 `ErrInvalidStatusTransition`
  - [ ] 单元测试覆盖所有状态转换场景
- **预估代码量**：~150 行（含测试）
- **上下文需求**：规格书 §3.{{Entity}}

> 重复以上结构填充。

---

## Batch 2：仓储接口（依赖 Batch 1）

### T-00X：Repository 接口定义

- **目标**：定义 `{{X}}Repository` 接口
- **产出文件**：
  - `internal/domain/repository/{{x}}_repository.go`
- **依赖**：T-002（实体）
- **验收标准**：
  - [ ] 接口方法覆盖规格书涉及的所有数据操作
  - [ ] 第一个参数 `ctx context.Context`
  - [ ] 最后返回值 `error`
- **预估代码量**：~60 行
- **上下文需求**：规格书 §3（数据结构）、§5（伪代码中涉及的数据操作）

---

## Batch 3：基础设施实现（依赖 Batch 2）

> 包括建表 SQL、Repository MySQL 实现、Redis 封装、RPC client 等。

### T-00X：建表 SQL

- **目标**：编写建表 SQL
- **产出文件**：`scripts/sql/00X_create_{{table}}.sql`
- **依赖**：T-002
- **验收标准**：
  - [ ] 字段类型、索引与规格书 §2.1 DDL 一致
  - [ ] SQL 在 MySQL 8.0 可执行
- **预估代码量**：~50 行
- **上下文需求**：规格书 §2.1 DDL、§3.{{Entity}}

### T-00X：{{X}}Repository MySQL 实现

- **目标**：实现 `{{X}}Repository` 接口（MySQL）
- **产出文件**：
  - `internal/infrastructure/persistence/{{x}}_repository_mysql.go`
  - `internal/infrastructure/persistence/{{x}}_repository_mysql_test.go`
- **依赖**：T-00X（接口）、T-00X（建表 SQL）
- **验收标准**：
  - [ ] 实现接口的所有方法
  - [ ] Update 使用乐观锁
  - [ ] 操作设置 3 秒超时
  - [ ] 集成测试通过
- **预估代码量**：~200 行（含测试）
- **上下文需求**：规格书 §2.1 DDL、§3 实体、§9 编码约束

---

## Batch 4：应用服务层（依赖 Batch 3）

### T-00X：{{Service}}.{{Method}} 应用服务

- **目标**：实现 `{{Method}}` 业务流程
- **产出文件**：
  - `internal/application/{{service}}.go`（{{Method}} 方法）
  - `internal/application/{{service}}_test.go`
- **依赖**：T-00X（仓储实现）、T-00X（缓存）、T-00X（RPC client）
- **验收标准**：
  - [ ] 流程步骤与规格书 §5 伪代码完全一致
  - [ ] 幂等检查逻辑正确
  - [ ] 异常分支处理与规格书 §5 / §6 边界表一致
  - [ ] 数据库事务保证原子性
  - [ ] 单元测试使用 mock 替代外部依赖
  - [ ] 测试覆盖：正常流程 + 所有异常分支
- **预估代码量**：~300 行（含测试）
- **上下文需求**：规格书 §3、§4、§5、§6、§9

---

## Batch 5：接入层（依赖 Batch 4）

### T-00X：{{Method}} HTTP Handler

- **目标**：实现 HTTP handler，编排路由、参数校验、调用应用服务、错误码映射
- **产出文件**：
  - `internal/interfaces/http/{{handler}}.go`
  - `internal/interfaces/http/{{handler}}_test.go`
- **依赖**：T-00X（应用服务）
- **验收标准**：
  - [ ] 路径、方法与规格书 §4 一致
  - [ ] 请求体校验规则与规格书一致
  - [ ] 错误码映射与规格书一致
  - [ ] HTTP handler 不直接调 DB/RPC
  - [ ] 集成测试覆盖正常 + 各错误码
- **预估代码量**：~200 行（含测试）
- **上下文需求**：规格书 §4、§9

---

## 任务依赖关系图

```
T-001 ──→ T-002 ──→ T-004 ──→ T-006 ──→ T-009 ──→ T-010
      ──→ T-003 ──↗        ──→ T-007 ──↗
                           ──→ T-008 ──↗
      ──→ T-005 ─────────────────────↗
```

---

## 关键路径

最长依赖链：T-001 → T-002 → T-004 → T-006 → T-009 → T-010
（共 {{N}} 个 Task，预估 {{loc}} 行）

---

## ⏸ 等待用户确认

> 本文件为 Phase 2 产物，需经用户 review 通过后方可进入 Phase 3。
>
> 请回复：
>
> - ✅ approve              → 进入 Phase 3 逐任务实现
> - 🔧 revise: <反馈>       → 修订任务拆分
> - ❌ reject               → 终止流水线
>
> **在收到 ✅ 之前，禁止调用任何 Phase 3 的工具。**
