# 仓库画像（REPO_PROFILE）

> 由 Phase 0 产出。所有结论必须可追溯到具体文件路径或 grep 结果；找不到的事实写"未发现"，不要写"应该是 / 可能是"。

## 1. 总览

- 仓库根路径：`{{repo_path}}`
- 类型：☐ Greenfield（绿地，仅有元文件） ☐ Brownfield（已有代码）
- 主语言：{{language}}（版本：{{version}}）
- 最近一次 commit：{{last_commit}}
- 关键元文件：
  - [ ] `LICENSE`
  - [ ] `README.md`
  - [ ] `.gitignore`
  - [ ] `go.mod`
  - [ ] `Makefile`
  - [ ] `Dockerfile`
  - [ ] CI 配置（`.github/workflows/` / `.gitlab-ci.yml`）

## 2. 语言与依赖（Go 项目）

- Go 版本：`{{go_version}}`
- HTTP 框架：`{{http_framework}}`（如 gin / echo / chi / 标准库 / **未引入**）
- ORM：`{{orm}}`（如 gorm / sqlx / ent / **未引入**）
- 缓存客户端：`{{cache_client}}`（如 go-redis / **未引入**）
- RPC 框架：`{{rpc_framework}}`（如 grpc-go / kitex / 自研 / **未引入**）
- 日志：`{{logger}}`（如 zap / logrus / zerolog / 标准库 / **未引入**）
- 配置：`{{config_lib}}`（如 viper / 自研 / **未引入**）
- 测试：`{{test_lib}}`（如 stretchr/testify / gomock / **未引入**）
- 可观测性：`{{observability}}`（如 otel / prometheus / **未引入**）

> 每项给出具体证据：`go.mod 中存在 github.com/xxx/yyy v1.x.x`，或写"未引入"。

## 3. 目录分层

判定结果：☐ DDD ☐ Clean Arch ☐ MVC ☐ Flat ☐ Mixed ☐ N/A（绿地）

一级目录职责（实测，不只看名字）：

| 目录 | 实际职责 | 证据文件 |
|---|---|---|
| `cmd/` | {{...}} | {{...}} |
| `internal/` | {{...}} | {{...}} |
| `pkg/` | {{...}} | {{...}} |
| `api/` | {{...}} | {{...}} |
| `configs/` | {{...}} | {{...}} |
| `scripts/` | {{...}} | {{...}} |

## 4. 公共能力清点

| 能力 | 状态 | 位置/证据 | 备注 |
|---|---|---|---|
| 错误处理 | 已有/部分有/未有 | | |
| 结构化日志 | | | |
| trace_id 注入 | | | |
| context 工具 | | | |
| 配置加载 | | | |
| HTTP recover 中间件 | | | |
| 鉴权中间件 | | | |
| 限流中间件 | | | |
| Access Log 中间件 | | | |
| DB 事务封装 | | | |
| Redis 连接封装 | | | |
| 幂等键工具 | | | |
| 测试 mock 框架 | | | |
| 集成测试入口 | | | |

## 5. 命名与风格约定

- 包命名：{{...}}
- 文件命名：{{...}}（如 `xxx_repository.go`）
- 错误码：{{...}}（数值 / 字符串 / iota 枚举）
- API 路径：{{...}}（`/api/v1/...`）
- 接收器：{{...}}
- 错误返回：{{...}}（`(T, error)` / `*AppError` / panic）

如有不一致：

- 不一致点：{{...}}
- 选择的基线风格：{{...}}（最普遍的）

## 5.5 风格基线（Phase 1 唯一引用源）

> **本表是 Phase 1 规格书 §9 编码约束的唯一引用源**。Phase 1 不得凭空声明风格选型；本表中"未引入"的项必须由规格书显式声明并说明引入原因。

| 维度 | 仓库现状（基线值） | 证据文件 |
|---|---|---|
| 日志库 | {{zap / slog / logrus / 未引入}} | {{...}} |
| 日志字段命名 | {{snake_case / camelCase / 未统一}} | {{...}} |
| 日志 trace_id 注入方式 | {{logger.WithContext / 自定义 helper / 未有}} | {{...}} |
| HTTP 框架 | {{gin / echo / 标准库 / 未引入}} | {{...}} |
| HTTP 响应格式 | {{`{code,message,data}` / 其他}} | {{...}} |
| HTTP 中间件顺序 | {{...}} | {{...}} |
| ORM/SQL 库 | {{gorm v2 / sqlx / ent / 未引入}} | {{...}} |
| 事务封装风格 | {{闭包 / 手写 Begin/Commit / 未有}} | {{...}} |
| 错误返回风格 | {{`(T, error)` / `*AppError`}} | {{...}} |
| 错误包装风格 | {{`fmt.Errorf("%w")` / 自定义 wrap}} | {{...}} |
| 错误码风格 | {{int / iota typed / 字符串常量}} | {{...}} |
| 测试 mock 库 | {{gomock / testify mock / 未引入}} | {{...}} |
| 测试断言库 | {{testify / 标准库 / 未引入}} | {{...}} |
| 配置加载方式 | {{viper / envconfig / 自研}} | {{...}} |
| 包命名 | {{小写单词 / 其他}} | {{...}} |
| 文件命名 | {{xxx_repository.go / xxx_repo.go}} | {{...}} |
| 接收器命名 | {{单字母 / 全名}} | {{...}} |
| nilaway 是否安装 | ☐ 已安装 ☐ 未安装（建议 `go install go.uber.org/nilaway/cmd/nilaway@latest`） | {{...}} |
| **基线 commit（BASELINE_COMMIT）** | {{git rev-parse HEAD 输出，如 `a1b2c3d4`；用于 Phase 5 增量代码差分；绿地项目填 `GREENFIELD`，无 `.git/` 填 `NO_GIT`}} | {{Phase 5 nilaway/INCR_FILES 兜底基线}} |

## 6. 风险与盲点

- ☐ 无 `go.mod`
- ☐ 无任何测试文件
- ☐ 无 CI 配置
- ☐ 无 `.gitignore`
- ☐ 无 README
- ☐ 大量 `// TODO` / `// FIXME`：{{...}}
- ☐ 多套不一致的实现共存：{{...}}
- ☐ 其他：{{...}}

## 7. 给 Phase 1 的建议

- 项目结构：☐ 直接复用现状 ☐ 在现状上新增 N 个目录 ☐ 绿地从零设计
- 依赖选型：☐ 全部沿用 ☐ 需新增以下依赖：{{...}}
- 命名约定：☐ 沿用现状 ☐ 需统一为：{{...}}
- 关键风险/约束：{{...}}

---

## ⏸ 等待用户确认

> 本文件为 Phase 0 产物，需经用户 review 通过后方可进入 Phase 1。
>
> 请回复：
>
> - ✅ approve              → 进入 Phase 1 实现规格书生成
> - 🔧 revise: <反馈>       → 修订仓库画像
> - ❌ reject               → 终止流水线
>
> **在收到 ✅ 之前，禁止调用任何 Phase 1 的工具。**
