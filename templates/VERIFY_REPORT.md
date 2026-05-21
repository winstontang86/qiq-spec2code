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

逐条核对 `TASK_CONTEXT.md` §6：

- [x/✗] 金额 int64 单位分
- [x/✗] DB 操作 3 秒超时
- [x/✗] RPC 调用 1 秒超时
- [x/✗] RPC 重试上限 + 退避
- [x/✗] 乐观锁 version 字段
- [x/✗] 日志结构化 + trace_id
- [x/✗] 错误 `%w` 包装
- [x/✗] for 循环内无 DB/RPC
- [x/✗] 无硬编码
- [x/✗] 所有 I/O 传 ctx
- [x/✗] 资源 defer Close

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

#### [MATCH-001] [Block]

- **问题类型**：缺失
- **规格书要求**：§4 Step 6 — 事务失败时调用 `inventoryService.Rollback(ctx, orderNo)`
- **代码现状**：`order_service.go:160-180` 仅打印日志，未调用 Rollback
- **差异说明**：库存扣减成功而订单创建失败时未回滚库存，导致库存数据不一致
- **修复建议**：在事务失败的 `defer` 或返回前增加 `_ = i.inventoryService.Rollback(ctx, orderNo)`，并对回滚失败的情况记录补偿日志（按规格书要求）
- **影响范围**：影响所有 CreateOrder 失败路径；不影响其他 Task

#### [MATCH-002] [Major]

- **问题类型**：约束违反
- **规格书要求**：§6.B1 — DB 操作 3 秒超时
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
