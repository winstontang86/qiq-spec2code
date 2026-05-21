# 实现规格书（IMPLEMENTATION_SPEC）

> 由 Phase 1 产出。**这是后续编码的唯一真理来源**。任何含糊、暧昧、留待"工程师自行决定"的描述都不合格。

- 来源方案：{{原始方案路径/标题/版本}}
- 仓库画像：`.spec2code/REPO_PROFILE.md`
- 产出时间：{{datetime}}

---

## 1. 项目结构定义

### 1.1 目录树

```
{{完整目录树，每个目录附 1 行职责说明}}
project-root/
├── cmd/
│   └── server/
│       └── main.go              # HTTP 服务启动入口（复用 / 新增）
├── internal/
│   ├── domain/                  # 领域层（复用 / 新增）
│   │   ├── entity/
│   │   ├── valueobject/
│   │   └── repository/          # 仓储接口（仅接口）
│   ├── application/             # 应用服务层
│   ├── infrastructure/          # 基础设施层
│   │   ├── persistence/
│   │   ├── cache/
│   │   └── rpc/
│   └── interfaces/              # 接入层
│       ├── http/
│       └── consumer/
├── pkg/
├── configs/
├── scripts/sql/
└── ...
```

每个目录右侧标注「**复用已有** / **新增**」，并对照 `REPO_PROFILE.md`。

### 1.2 命名规范

- 包名：{{...}}
- 文件名：{{...}}
- 接口/接收器：{{...}}
- 错误码：{{...}}
- API 路径：{{...}}

### 1.3 与仓库现状的偏离

> 列出所有偏离 `REPO_PROFILE.md` 的设计决策与原因。无偏离写"无"。

- 偏离 1：{{...}}（原因：{{...}}）

---

## 2. 核心数据结构定义

### 2.1 实体：{{EntityName}}

- **数据库表名**：`{{table_name}}`
- **分表策略**：{{无 / 按 user_id % 64}}
- **字符集/引擎**：{{utf8mb4 / InnoDB}}

#### 字段表

| 字段名 | Go 类型 | DB 类型 | 必填 | 默认值 | 索引 | 说明 |
|---|---|---|---|---|---|---|
| id | int64 | BIGINT | 是 | 自增 | PK | 主键 |
| order_no | string | VARCHAR(32) | 是 | - | UNIQUE | 订单号 |
| user_id | int64 | BIGINT | 是 | - | idx_user_id | 用户ID |
| status | int8 | TINYINT | 是 | 1 | - | 订单状态 |
| amount | int64 | BIGINT | 是 | - | - | 金额（单位：分） |
| created_at | time.Time | DATETIME(3) | 是 | CURRENT_TIMESTAMP(3) | - | 创建时间（UTC） |
| updated_at | time.Time | DATETIME(3) | 是 | CURRENT_TIMESTAMP(3) | - | 更新时间（UTC） |
| version | int32 | INT | 是 | 1 | - | 乐观锁版本 |

#### 枚举

```go
type OrderStatus int8

const (
    OrderStatusCreated  OrderStatus = 1 // 已创建
    OrderStatusPaid     OrderStatus = 2 // 已支付
    OrderStatusShipped  OrderStatus = 3 // 已发货
    OrderStatusComplete OrderStatus = 4 // 已完成
    OrderStatusCanceled OrderStatus = 5 // 已取消
)
```

#### 状态机

合法转换：

```
Created   → Paid       (支付成功)
Created   → Canceled   (用户/超时取消)
Paid      → Shipped    (商家发货)
Paid      → Canceled   (退款)
Shipped   → Complete   (确认收货)
```

非法转换：返回错误 `ErrInvalidStatusTransition`。

> 重复以上结构，为每个实体定义。

---

## 3. 接口契约定义

### 3.1 接口：{{接口名称}}

- **路径/方法**：`POST /api/v1/orders`
- **认证**：需要登录，从 Header `X-User-Id` 获取
- **限流**：单用户 10 次/秒

#### 请求体

| 字段 | 类型 | 必填 | 校验 | 说明 |
|---|---|---|---|---|
| product_id | int64 | 是 | >0 | 商品ID |
| quantity | int32 | 是 | [1,999] | 数量 |
| address_id | int64 | 是 | >0 | 收货地址ID |
| coupon_id | int64 | 否 | >=0 | 优惠券ID（0 表示不使用） |
| idempotency_key | string | 是 | UUID v4 | 幂等键 |

#### 响应体（成功）

```json
HTTP 200
{
  "code": 0,
  "message": "success",
  "data": {
    "order_no": "ORD20240101000001",
    "amount": 9900,
    "status": 1
  }
}
```

#### 错误码表

| code | HTTP | message | 说明 | 处理建议 |
|---|---|---|---|---|
| 10001 | 400 | invalid parameter | 参数校验失败 | 检查请求 |
| 10002 | 409 | duplicate request | 重复请求 | 查询订单 |
| 20001 | 400 | product not found | 商品不存在 | — |
| 20002 | 400 | insufficient stock | 库存不足 | 提示用户 |
| 50001 | 500 | internal error | 系统错误 | 重试 |

#### 幂等性

- 幂等键：`idempotency_key`
- 存储：Redis SETNX，key=`idempotent:{user_id}:{idempotency_key}`，TTL 24h
- 重复请求返回首次结果。

> 重复以上结构，为每个接口定义。

---

## 4. 核心流程伪代码

### 4.1 流程：{{流程名}}

```
func {{FuncName}}(ctx, req) (resp, err):
    // Step 1: 参数校验
    validate(req)

    // Step 2: 幂等检查
    existing = redis.GET("idempotent:{user_id}:{idempotency_key}")
    if existing != nil:
        return existing, ErrDuplicateRequest

    // Step 3: 查询商品（RPC，超时 1s，重试 2 次）
    product = productService.GetProduct(ctx, req.product_id)
    if product == nil:
        return nil, ErrProductNotFound

    // Step 4: 计算价格
    amount = product.price * req.quantity
    if req.coupon_id != 0:
        coupon = couponService.GetCoupon(ctx, req.coupon_id, user_id)
        if coupon == nil or coupon.expired:
            return nil, ErrCouponNotAvailable
        amount = applyCoupon(amount, coupon)

    // Step 5: 扣减库存（RPC 幂等，使用 order_no 作为幂等键）
    err = inventoryService.Deduct(ctx, req.product_id, req.quantity, order_no)
    if err != nil:
        return nil, ErrInsufficientStock

    // Step 6: 创建订单 + outbox（数据库事务）
    BEGIN TRANSACTION
        orderRepo.Create(ctx, order)
        outboxRepo.Create(ctx, outboxMsg)
    COMMIT
    // 失败时：调用 inventoryService.Rollback(ctx, order_no)；
    //        Rollback 失败时记录补偿日志，由定时任务兜底

    // Step 7: 设置幂等结果
    redis.SET("idempotent:{user_id}:{idempotency_key}", resp, TTL=24h)
    // 失败时不影响主流程，仅记日志（数据库唯一约束兜底）

    // Step 8: 返回结果
    return resp, nil
```

#### 异常分支

| 步骤 | 异常类型 | 处理方式 |
|---|---|---|
| Step 3 | RPC 超时 | 返回 50001，由调用方重试 |
| Step 5 | 库存不足 | 返回 20002，**不**回滚（未发生写） |
| Step 6 | DB 事务失败 | 调用 inventoryService.Rollback；失败则补偿日志 |
| Step 7 | Redis 失败 | 仅记日志，不影响主流程 |

> 重复以上结构，为每个核心流程定义。

---

## 5. 模块依赖关系图

```
interfaces/http
    └── application/order_service
              ├── domain/entity
              ├── domain/repository (interface)
              ├── infrastructure/persistence (impl)
              ├── infrastructure/cache
              └── infrastructure/rpc/{product,inventory}_client
```

### 实现层次

| Layer | 内容 |
|---|---|
| Layer 0 | domain/entity, domain/valueobject |
| Layer 1 | domain/repository（接口） |
| Layer 2 | infrastructure/*（实现 repository 接口） |
| Layer 3 | application/* |
| Layer 4 | interfaces/* |

> 同 Layer 内可并行；跨 Layer 严格串行。

---

## 6. 编码约束清单

> 摘自 [@references/06-coding-constraints-common.md](../references/06-coding-constraints-common.md) 与 [@references/07-coding-constraints-go.md](../references/07-coding-constraints-go.md)，按本方案实际涉及范围摘取。

### 6.1 类型与单位

- [ ] 金额字段使用 `int64`，单位"分"。
- [ ] 时间使用 `time.Time`（UTC），DB 列 `DATETIME(3)`。
- [ ] ID 使用 `int64`。
- [ ] 枚举使用 `type Foo int8` + 显式常量。

### 6.2 超时与重试

- [ ] DB 操作超时 3 秒。
- [ ] RPC 调用超时 1 秒。
- [ ] RPC 重试最多 2 次，退避 100ms / 200ms。
- [ ] 仅幂等下游允许重试。

### 6.3 幂等与并发

- [ ] 写操作必须幂等。
- [ ] 乐观锁使用 version 字段；更新时 `WHERE version=? SET version=version+1` 并校验 RowsAffected。
- [ ] 禁止 for 循环内单条 DB/RPC 调用。

### 6.4 错误处理

- [ ] 错误使用 `fmt.Errorf("...: %w", err)` 包装。
- [ ] 不吞错；忽略必须注释说明。
- [ ] 业务错误使用 sentinel 或 typed error。

### 6.5 日志

- [ ] 结构化（zap）。
- [ ] 含 trace_id。
- [ ] 敏感字段脱敏。

### 6.6 配置

- [ ] 所有可变值从配置文件/环境变量读取。
- [ ] 启动期校验配置完整性。

### 6.7 安全

- [ ] 所有外部输入参数校验。
- [ ] SQL 参数化。
- [ ] 错误消息对外脱敏。

### 6.8 测试

- [ ] 每个产出有单元测试。
- [ ] 覆盖正常 + 异常 + 边界。
- [ ] mock 在接口层。

### 6.9 依赖版本约束

- Go {{1.21+}}
- MySQL {{8.0}}
- Redis {{7.0}}
- {{其他}}

---

> ✅ 用户确认本规格书后，方可进入 Phase 2 任务拆分。
