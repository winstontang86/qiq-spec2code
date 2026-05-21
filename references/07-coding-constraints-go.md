# Go 语言特化编码约束

> 本文件列出 Go 项目落地时的特化约束。与 [@06-coding-constraints-common.md](06-coding-constraints-common.md) 配合使用，**通用约束在 Go 项目中的具体体现**也在此处给出。

## G1. 类型与精度

- **G1.1** 金额：使用 `int64`，单位"分"。禁止 `float32` / `float64`。
- **G1.2** 时间：DB 用 `DATETIME(3)` 或 `BIGINT`（Unix ms），Go 用 `time.Time`，传输用 RFC3339 + UTC。
- **G1.3** ID：`int64`；JSON 序列化如对外展示，使用字符串以避免 JS 精度丢失（`json:"order_no,string"`）。
- **G1.4** 枚举：`type OrderStatus int8` + `const (OrderStatusCreated OrderStatus = 1 ...)`，禁止裸数字。

## G2. context 与超时

- **G2.1** 所有可能阻塞/做 I/O 的函数第一个参数必须是 `ctx context.Context`。
- **G2.2** 数据库操作：`db.WithContext(ctx)` + `context.WithTimeout(ctx, 3*time.Second)`。
- **G2.3** RPC/HTTP client 调用：`context.WithTimeout(ctx, 1*time.Second)`。
- **G2.4** 启动期初始化允许 `context.Background()`；请求/任务路径**禁止** `context.Background()` / `context.TODO()`。
- **G2.5** 启动 goroutine 处理后台任务时，必须可被 ctx 取消，且 main 退出时优雅关闭。

## G3. 错误处理

- **G3.1** 包装错误使用 `fmt.Errorf("create order user_id=%d: %w", userID, err)`，必须用 `%w`。
- **G3.2** 自定义业务错误使用 sentinel error（`var ErrOrderNotFound = errors.New("order not found")`）或 typed error，配合 `errors.Is` / `errors.As` 判定。
- **G3.3** 禁止 `if err != nil { return errors.New("xxx") }` 这种丢失错误链的写法。
- **G3.4** 禁止 `_ = someFunc()` 吞错；如确需忽略，写注释说明原因。
- **G3.5** `panic` 仅用于不可恢复的程序错误（如配置启动校验失败）；HTTP/RPC handler 必须有 recover 中间件。

## G4. 日志

- **G4.1** 优先使用 `zap`（已有库则复用），其次 `slog`（Go 1.21+）。禁止 `log.Printf`。
- **G4.2** 结构化字段命名 snake_case：`zap.String("order_no", orderNo)`、`zap.Int64("user_id", userID)`。
- **G4.3** trace_id 来源：从 ctx 中读取（统一封装一个 `logger.WithContext(ctx)` 工具）。
- **G4.4** 错误日志必须打到 ERROR 级别且必须带 `zap.Error(err)`。
- **G4.5** 禁止在循环内逐次打 INFO 级别大量日志，必须聚合或降级为 DEBUG。

## G5. 数据库（GORM/sqlx 通用）

- **G5.1** 所有 SQL 必须参数化；GORM 使用 `Where("id = ?", id)`，禁止 `Where(fmt.Sprintf("id = %d", id))`。
- **G5.2** 事务使用闭包形式（GORM `db.Transaction(func(tx *gorm.DB) error {...})`），禁止手写 `Begin/Commit/Rollback` 易出错的写法。
- **G5.3** 乐观锁：`Where("id = ? AND version = ?", id, version).Updates(...)`，并校验 `RowsAffected`。
- **G5.4** 查询必须走索引；规格书要求的索引必须在 DDL 中存在。
- **G5.5** 连接池配置：`MaxOpenConns` / `MaxIdleConns` / `ConnMaxLifetime` 从配置读取，禁止默认值上线。
- **G5.6** 敏感操作（DELETE / UPDATE 全表）必须有 `WHERE`；建议加单元测试守护。

## G6. HTTP（gin/echo/标准库通用）

- **G6.1** 路由路径使用规格书定义的精确字符串，禁止"约等于"。
- **G6.2** 请求体使用 struct + tag 校验（`binding:"required,min=1,max=999"`）。
- **G6.3** 响应统一格式：`{"code": int, "message": string, "data": any}`（具体格式以规格书为准）。
- **G6.4** Handler 不直接写业务逻辑，调用 application 层。
- **G6.5** 中间件顺序：recover → trace → access log → auth → rate limit → handler。

## G7. 并发

- **G7.1** 共享状态使用 `sync.Mutex` / `sync.RWMutex` / `atomic` / channel；禁止裸读写共享变量。
- **G7.2** goroutine 必须有明确的退出条件，禁止裸 `go func()` 而无生命周期管理。
- **G7.3** 使用 `errgroup` 做并发任务编排；要传递 ctx。
- **G7.4** 不要在 goroutine 中直接捕获 for 循环变量（Go < 1.22 必须显式拷贝）。

## G8. 项目结构

- **G8.1** 内部包放 `internal/`；可对外暴露的放 `pkg/`。
- **G8.2** 接口与实现分离：`domain/repository` 定义接口，`infrastructure/persistence` 实现。
- **G8.3** 禁止反向依赖：`domain` 不能 import `infrastructure`；`application` 不能 import `interfaces`。
- **G8.4** package 名小写单词，与目录名一致；不要包含连字符。

## G9. 测试

- **G9.1** 文件命名 `xxx_test.go`，与被测文件同包（同包测）或 `xxx_test` 包（外部测）。
- **G9.2** 表驱动测试优先：`for _, tt := range tests { t.Run(tt.name, func(t *testing.T){...}) }`。
- **G9.3** mock 使用 `gomock` 或 `testify/mock`（与仓库已有选型一致）。
- **G9.4** 数据库集成测试使用 `testcontainers-go` 或 `sqlmock`，禁止依赖共享开发库。
- **G9.5** `t.Cleanup` 优先于 `defer` 用于测试资源清理。
- **G9.6** 断言使用 `testify/require`（致命断言）或 `testify/assert`（非致命）。

## G10. 工程化

- **G10.1** `go fmt` / `gofmt -s` / `goimports` 必须通过。
- **G10.2** `go vet ./...` 必须通过。
- **G10.3** 仓库已有 `golangci-lint` 配置则必须通过；新增项目不强制引入。
- **G10.4** `go.mod` 中 Go 版本与仓库现状保持一致；新增依赖必须 `go mod tidy`。
- **G10.5** `_ "package"` 副作用 import 必须有注释说明用途。

## G11. 反 Anti-pattern 速查

| 反例 | 正例 |
|---|---|
| `time.Now().Sub(start)` | `time.Since(start)` |
| `fmt.Errorf("%v", err)` | `fmt.Errorf("...: %w", err)` |
| `interface{}` 满天飞 | 优先具体类型；Go 1.18+ 用泛型替代部分场景；通用容器用 `any` |
| 自定义全局变量配置 | 通过结构体注入 + 构造函数 |
| 大对象作为 receiver | 指针 receiver；统一同一类型的 receiver 风格 |
| `sql.Open` 后立即 query 不 ping | `db.Ping()` 验证连通性 |
| handler 直接调 DB | handler → application → repository |
