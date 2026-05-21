# 单 Task 校验报告（VERIFY_REPORT）

> 由 Verifier 产出。每次校验都在文件末尾追加新的 `## Attempt N` 章节。

- **任务 ID**：{{T-XXX}}
- **任务名称**：{{...}}
- **本次校验**：Attempt {{N}}
- **校验时间**：{{datetime}}

---

## Attempt {{N}}

### 1. 校验概要

- **总体结论**：☐ ✅ Pass ☐ ⚠️ Pass with non-blocking issues ☐ ❌ Fail
- **Block 数**：{{N}}
- **Major 数**：{{N}}
- **Minor 数**：{{N}}
- **Info 数**：{{N}}

**逐轮对账（Re-Verify、仅 Attempt ≥ 2 填写）**：

- 上轮已修复：{{N}} 项 → [MATCH-T009-001, MATCH-T009-003 ...]
- 仍残留：{{N}} 项 → [MATCH-T009-002 ...]
- 本轮新增：{{N}} 项 → [MATCH-T009-006 ...]
- 回归（REGRESSION）：{{N}} 项 → [MATCH-T009-001 ...]

> 严格按以下规则推导结论，不允许主观裁量：
> - 任一 Block → ❌ Fail
> - 无 Block 但有 Major → ⚠️ Pass with non-blocking issues（可进入下一 Task，但需在本批次结束前修复）
> - 仅 Minor / Info → ✅ Pass

### 2. 维度 1：结构符合性

- [x/✗] 产出文件清单与 outputs 完全一致
- [x/✗] 文件路径与规格书一致
- [x/✗] package 名称正确
- [x/✗] 无循环依赖
- [x/✗] 不违反层次依赖

### 3. 维度 2：数据结构符合性（逐字段比对表）

| 规格书字段 | 规格书类型 | 代码字段 | 代码类型 | 一致性 | 备注 |
|---|---|---|---|---|---|
| order_no | string | OrderNo | string | ✅ | |
| amount | int64 | Amount | float64 | ❌ | 应为 int64 |
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

#### 枚举/状态机比对

- [x/✗] 枚举名与值一致
- [x/✗] 合法状态转换全部实现
- [x/✗] 非法转换被拒绝

### 4. 维度 3：接口符合性

- [x/✗] 接口方法签名与规格书一致
- [x/✗] HTTP 路径/方法与规格书一致
- [x/✗] 错误码值、HTTP 状态码、message 一致
- [x/✗] 校验规则与规格书一致

### 5. 维度 4：流程符合性（逐步骤比对表）

| 规格书步骤 | 代码实现位置 | 一致性 | 备注 |
|---|---|---|---|
| Step 1 参数校验 | order_handler.go:45-60 | ✅ | |
| Step 2 幂等检查 | order_service.go:78-85 | ✅ | |
| Step 5 库存扣减 | order_service.go:120-130 | ✅ | |
| Step 6 事务失败回滚 | order_service.go:160-180 | ❌ | 缺少 inventoryService.Rollback 调用 |

#### 异常分支

- [x/✗] 每个异常分支都有处理
- [x/✗] 处理方式与规格书一致

#### 事务边界

- [x/✗] 事务范围正确
- [x/✗] 事务内操作清单正确
- [x/✗] 事务外回滚补偿已实现

#### 幂等性

- [x/✗] 幂等键来源正确
- [x/✗] 存储与 TTL 与规格书一致

### 6. 维度 5：编码约束符合性

#### 5.1 核心约束

- [x/✗] 金额 `int64` 单位"分"
- [x/✗] 时间 UTC，DB 精确到毫秒
- [x/✗] ID `int64`，枚举 typed const 无裸数字
- [x/✗] DB 操作设置超时（默认 3s，与规格书一致）
- [x/✗] RPC/HTTP 调用设置超时（默认 1s，与规格书一致）
- [x/✗] 仅幂等下游允许重试
- [x/✗] 写操作幂等；幂等键来源/存储/TTL 与规格书一致
- [x/✗] 乐观锁 version 字段，校验 `RowsAffected`
- [x/✗] 错误 `%w` 包装；无吞错
- [x/✗] for 循环内无单条 DB/RPC
- [x/✗] 所有 I/O 传 `ctx`，生产路径无 `context.Background()` / `context.TODO()`
- [x/✗] SQL 参数化，无字符串拼接

#### 5.2 nil 安全（必查）

- [x/✗] 返回指针/接口的函数，调用方均显式判 nil
- [x/✗] map 写入前已确认非 nil
- [x/✗] 类型断言均使用 `v, ok := x.(T)` 形式
- [x/✗] JSON / RPC 反序列化的指针字段使用前已判 nil
- [x/✗] `nilaway` 对本任务相关文件无报告（如本地工具可用）

#### 5.3 风格沿用（对照 `REPO_PROFILE.md` §5.5）

- [x/✗] 日志库、字段命名、级别与基线一致
- [x/✗] HTTP 框架、响应包装格式与基线一致
- [x/✗] 测试 mock/断言库与基线一致
- [x/✗] 错误返回风格（`(T, error)` / `*AppError`）与基线一致
- [x/✗] 包名/文件命名/接收器与基线一致

> 风格不一致默认为 Major；如基线本身缺失则降级为 Info 并记入 §11 后续整改项。

### 7. 维度 6：测试覆盖性

- [x/✗] 存在测试文件
- [x/✗] 验收标准每条都有测试
- [x/✗] 正常路径有测试
- [x/✗] 每个异常分支至少 1 条测试
- [x/✗] 边界条件有测试
- [x/✗] mock 在接口层

### 8. 维度 7：安全性基础

- [x/✗] 无 SQL 拼接
- [x/✗] 敏感字段日志已脱敏
- [x/✗] 无硬编码密钥
- [x/✗] 用户输入有校验
- [x/✗] 错误消息对外脱敏

### 9. 维度 8：反向检查

- [x/✗] 代码无规格书外的功能
- [x/✗] 代码无规格书外的字段/参数
- [x/✗] 代码无规格书外的错误码
- [x/✗] 代码无与规格书矛盾的实现
- [x/✗] `// SPEC_QUESTION:` 注释已被记录到 IMPL_REPORT 偏差章节

### 10. 问题清单

> 问题 ID 格式**必须**为 `MATCH-T<task>-<seq>`（如 `MATCH-T009-001`）。多轮校验时同一问题沿用原始序号，新增问题递增。回归问题在序号前加 `[REGRESSION]` 标记，严重程度按 Block 处理。

#### [MATCH-T009-001] [Block]

- **问题类型**：缺失
- **规格书要求**：§5 Step 6 — 事务失败时调用 `inventoryService.Rollback(ctx, orderNo)`
- **代码现状**：`order_service.go:160-180` 仅打印日志，未调用 Rollback
- **差异说明**：库存扣减成功而订单创建失败时未回滚库存，导致库存数据不一致
- **修复建议**：在事务失败的 `defer` 或返回前增加 `_ = i.inventoryService.Rollback(ctx, orderNo)`，并对回滚失败的情况记录补偿日志（按规格书要求）
- **影响范围**：影响所有 CreateOrder 失败路径；不影响其他任务

#### [MATCH-T009-002] [Major]

- **问题类型**：约束违反
- **规格书要求**：§9.2 — DB 操作 3 秒超时
- **代码现状**：`order_repository_mysql.go:33` 未设置超时，使用 `r.db.WithContext(ctx)` 但 ctx 无 deadline
- **差异说明**：默认无超时，DB 阻塞会拖慢整条链路
- **修复建议**：使用 `ctx, cancel := context.WithTimeout(ctx, 3*time.Second); defer cancel()`
- **影响范围**：本 Task 所有方法

> 重复以上格式，列全本次发现的问题。

### 11. 校验结论

- **总体结论**：{{✅ Pass / ⚠️ Pass with non-blocking issues / ❌ Fail}}
- **后续动作**：
  - ✅ Pass → 进入下一 Task
  - ⚠️ Pass with non-blocking issues → 进入下一 Task；Major 需登记本批次整改
  - ❌ Fail → 反馈 Implementer 重做（attempt + 1）；attempt ≥ 3 时停止流水线并上报
