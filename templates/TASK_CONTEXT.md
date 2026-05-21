# 单 Task 上下文（TASK_CONTEXT）

> 由 Coordinator 在每个 Task 开始时装配。Implementer **只看本文件**，不去翻原始方案与规格书全文。

---

## 1. 任务信息

- **任务 ID**：{{T-XXX}}
- **任务名称**：{{...}}
- **所属批次**：Batch {{N}}
- **本次尝试次数**：{{attempt}} / 3

## 2. 任务目标

{{1~3 句话描述本任务做什么}}

## 3. 产出文件

- `{{path/to/file_1.go}}`
- `{{path/to/file_1_test.go}}`
- `{{...}}`

> Implementer **必须**且**仅**产出上述文件。多写或少写都会导致校验失败。

## 4. 验收标准

- [ ] {{标准 1}}
- [ ] {{标准 2}}
- [ ] {{...}}

> Implementer 必须**逐条**对照实现，并在 `IMPL_REPORT.md` 中逐条自检。

## 5. 相关规格书片段（完整摘录）

> 摘自 `.spec2code/IMPLEMENTATION_SPEC.md`，与本任务相关的章节**完整复制**到下方，不要给链接。

### 5.1 数据结构（来自规格书 §2）

```
{{完整复制相关实体定义、字段表、枚举、状态机}}
```

### 5.2 接口契约（来自规格书 §3，如适用）

```
{{完整复制相关接口定义、错误码表、幂等说明}}
```

### 5.3 流程伪代码（来自规格书 §4，如适用）

```
{{完整复制相关流程伪代码，包括所有异常分支}}
```

## 6. 编码约束（与本任务相关）

> 摘自规格书 §6，仅保留与本任务相关的条款。

- [ ] {{约束 1}}
- [ ] {{约束 2}}
- [ ] {{...}}

## 7. 依赖接口签名

> 本任务依赖的接口与函数签名（无实现）。**禁止**修改这些签名。

```go
// 来自 T-XXX
type {{X}}Repository interface {
    Create(ctx context.Context, x *entity.X) error
    GetBy{{Field}}(ctx context.Context, k {{Type}}) (*entity.X, error)
}

// 来自 T-XXX
type {{Y}}Service interface {
    {{Method}}(ctx context.Context, ...) (..., error)
}
```

## 8. 已完成的相关代码

> 仅在本任务必须直接使用某个已完成 Task 的代码时，才在此处粘贴该代码原文。

```go
// 来自 T-002，internal/domain/entity/order.go
{{完整粘贴}}
```

## 9. 上次校验反馈（仅 attempt > 1 时存在）

> 由 Coordinator 在重试时注入；本次必须修复以下问题。

```
{{粘贴上一轮 VERIFY_REPORT.md 的"问题清单"章节}}
```

> Implementer **必须逐条响应**：要么修复并指明修复位置，要么显式说明无法修复及原因。

---

> Implementer 收到本上下文后：
> 1. 先输出"任务理解确认"段落；
> 2. 实现代码到指定文件；
> 3. 写 `IMPL_REPORT.md`。
