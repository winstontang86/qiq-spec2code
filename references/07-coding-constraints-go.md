# Go 语言特化编码约束

> 本文件列出 Go 项目落地时的特化约束，与 [@06-coding-constraints-common.md](06-coding-constraints-common.md) 配合使用。
>
> **基本原则**：日志库、HTTP 框架、ORM、测试库、错误返回风格、目录命名等**风格类**决策**沿用 `REPO_PROFILE.md` 的"风格基线"**，本文件不重复定义。本文件只保留"违反必返工"的 Go 最小核心集——类型精度、context、错误处理、nil 安全、数据库底线、测试。其它约束按需后续扩展。

## G1. 类型与精度

- **G1.1** 金额：使用 `int64`，单位"分"。禁止 `float32` / `float64`。
- **G1.2** 时间：DB 用 `DATETIME(3)` 或 `BIGINT`（Unix ms），Go 用 `time.Time`，传输用 RFC3339 + UTC。
- **G1.3** ID：`int64`；JSON 对外展示如需字符串（避免 JS 精度丢失），统一加 `json:"...,string"`。
- **G1.4** 枚举：`type OrderStatus int8` + `const (OrderStatusCreated OrderStatus = 1 ...)`，禁止裸数字。

## G2. context 与超时

- **G2.1** 所有可能阻塞/做 I/O 的函数第一个参数必须是 `ctx context.Context`。
- **G2.2** 数据库操作：`db.WithContext(ctx)` + `context.WithTimeout(ctx, 3*time.Second)`（默认值，规格书可覆盖）。
- **G2.3** RPC/HTTP client 调用：`context.WithTimeout(ctx, 1*time.Second)`（默认值，规格书可覆盖）。
- **G2.4** 启动期初始化允许 `context.Background()`；请求/任务路径**禁止** `context.Background()` / `context.TODO()`。
- **G2.5** 启动 goroutine 处理后台任务时，必须可被 ctx 取消，且进程退出时优雅关闭。

## G3. 错误处理

- **G3.1** 包装错误使用 `fmt.Errorf("create order user_id=%d: %w", userID, err)`，必须用 `%w`。
- **G3.2** 自定义业务错误使用 sentinel error（`var ErrOrderNotFound = errors.New("order not found")`）或 typed error，配合 `errors.Is` / `errors.As` 判定。
- **G3.3** 禁止 `if err != nil { return errors.New("xxx") }` 这种丢失错误链的写法。
- **G3.4** 禁止 `_ = someFunc()` 吞错；如确需忽略，必须有注释说明原因。
- **G3.5** `panic` 仅用于不可恢复的程序错误（如配置启动校验失败）；HTTP/RPC handler 必须有 recover 中间件（具体中间件实现沿用仓库现状）。

## G4. nil 安全（**强制：增量代码必须通过 nilaway 检查**）

> Go 中绝大多数线上 panic 来自"以为非 nil 的指针/接口/map/slice 实际为 nil"。本组为硬约束。
>
> **范围**：nilaway 门禁仅覆盖本次方案的**增量代码**（`INCR_FILES`，定义见 [@references/05-integration-check.md](05-integration-check.md) §1.5）。**存量代码命中报告不在本次治理范围内**，仅登记不修复。

- **G4.1** **增量代码 `nilaway` 报告必须为空**：Phase 5 集成校验会执行 `nilaway ./...` 全仓扫描后按 `INCR_FILES` 做差分，**`nilaway.incr.txt` 任一行即 FAIL**。存量遗留落入 `nilaway.legacy.txt`，仅登记不阻塞。
  - 仓库未安装 nilaway 时，Phase 0 扫描阶段须提示用户安装：`go install go.uber.org/nilaway/cmd/nilaway@latest`。
  - 用户拒绝安装时，必须**对增量代码**人工逐文件审查指针解引用，并在 `INTEGRATION_REPORT.md` 显式登记降级。
  - **严禁**为了让增量报告为空而擅自修改存量代码（属于规格书外发挥，参见红线）。
- **G4.2** **返回指针/接口的函数**：调用方必须先判 nil 再解引用，禁止"反正不会为 nil"的假设。
- **G4.3** **可能为 nil 的字段**：结构体中表示"可选"的字段使用指针 + 显式判 nil；不要用零值含糊代表"无"。
- **G4.4** **map 写入前必须确保已初始化**：`m == nil` 时写入 panic；接收外部传入的 map 前先判空，未初始化则 `m = make(...)`。
- **G4.5** **类型断言必须使用 comma-ok 形式**：`v, ok := x.(T)` + `if !ok` 处理；禁止裸 `v := x.(T)` 在生产路径出现。
- **G4.6** **JSON / RPC 反序列化的指针字段**：使用前必须判 nil，特别是 protobuf 生成代码中的 message 字段。
- **G4.7** **error 包装链中的 sentinel 判定**：`errors.Is(err, target)` 前不需判 nil（标准库已处理），但 `errors.As` 的目标变量必须先初始化。

## G5. 数据库底线

- **G5.1** 所有 SQL 必须参数化；GORM `Where("id = ?", id)`，禁止 `Where(fmt.Sprintf("id = %d", id))`。
- **G5.2** 事务使用闭包形式（如 GORM `db.Transaction(func(tx *gorm.DB) error {...})`），禁止手写 `Begin/Commit/Rollback`。
- **G5.3** 乐观锁：`Where("id = ? AND version = ?", id, version).Updates(...)`，并校验 `RowsAffected`。
- **G5.4** 敏感写操作（DELETE / UPDATE 全表）必须有 `WHERE`；建议加单元测试守护。
- **G5.5** 具体 ORM/SQL 库选型、连接池参数命名、查询构建风格 → **沿用 `REPO_PROFILE.md` 风格基线**。

## G6. 测试

- **G6.1** 文件命名 `xxx_test.go`，与被测文件同包或 `xxx_test` 包。
- **G6.2** mock 库（gomock / testify mock / 其他）、断言库选型 → **沿用 `REPO_PROFILE.md` 风格基线**；新仓库由规格书定。
- **G6.3** 数据库集成测试使用 `sqlmock` / `testcontainers-go` 等，禁止依赖共享开发库。
- **G6.4** 验收标准的每条都要有对应测试用例；异常分支至少 1 条用例。

---

> 以下原 G4/G6/G7/G10/G11 等约束已迁移至"风格基线"，沿用 `REPO_PROFILE.md` 的仓库现状：
>
> - 日志库（zap / slog / 其他）、字段命名、级别使用
> - HTTP 框架（gin / echo / 标准库）、中间件顺序、响应包装格式
> - 并发风格（errgroup 用法、loop 变量捕获，Go 1.22+ 已修复）
> - 工程化命令（gofmt / goimports / go vet / golangci-lint） — 由 Phase 5 集成校验直接 `go vet ./...` + 仓库已配置的 `make lint`，不在此重复列约束
> - 反 anti-pattern 速查（`time.Now().Sub` / `interface{}` 等） — 属代码风格，不属规格符合性

> 当仓库画像中**未发现**某项基线时，由 Phase 1 规格书显式声明；不允许 Implementer 凭空选型。
