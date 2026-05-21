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

> ✅ 用户确认本画像后，方可进入 Phase 1。
