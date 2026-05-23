# 集成校验报告（INTEGRATION_REPORT）

> 由 Phase 5 产出。所有 Task 状态为 `passed` 或显式 `waived` 后执行。

- **报告时间**：{{datetime}}
- **覆盖 Task 数**：{{N}}
- **来源规格书**：`.spec2code/IMPLEMENTATION_SPEC.md`
- **原始方案路径**：{{...}}

---

## 1. 构建与测试

### 1.1 构建

```
$ go build ./...
{{命令输出 / "ok"}}
退出码：{{0/非0}}
```

### 1.2 vet

```
$ go vet ./...
{{...}}
退出码：{{0/非0}}
```

### 1.3 测试

```
$ go test ./...
{{...}}
退出码：{{0/非0}}
```

- 测试覆盖率：{{x.x%}}（如已开启 `-cover`）
- 失败测试列表：{{...}}（如有）

### 1.4 静态检查（如适用）

```
$ {{golangci-lint run / make lint}}
{{...}}
```

> 任一失败 → **整体 FAIL**。

### 1.5 nilaway 增量门禁（**对增量代码强制；存量遗留登记不处理**）

> 范围与执行步骤详见 [@references/05-integration-check.md](../references/05-integration-check.md) §1.5。

- **BASELINE_COMMIT**：`{{REPO_PROFILE.md §5.5 中记录的值，如 a1b2c3d4 / GREENFIELD / NO_GIT}}`
- **INCR_FILES 来源**：☐ tasks.json 产出文件并集 ☐ git diff 兜底 ☐ 全仓（绿地）
- **INCR_FILES 数量**：{{N}}

执行结果：

```
$ nilaway ./... > .spec2code/state/nilaway.raw.txt
原始报告条数：{{X}}
增量命中（nilaway.incr.txt）：{{Y}} 行  ← **必须为 0**
存量遗留（nilaway.legacy.txt）：{{Z}} 行  ← 不阻塞，仅登记
```

- [ ] **`nilaway.incr.txt` 行数 = 0**（任一行 → FAIL）
- 存量遗留涉及文件清单（仅文件名，不展开行号）：{{...}}
- 存量遗留登记说明：存量代码命中，**不在本次方案治理范围**，建议由仓库 Owner 排期独立任务治理。
- 若用户在 Phase 0 选择不安装 nilaway → 替换为人工降级登记：降级原因 / Owner / 整改时间 = {{...}}

---

## 2. 接口衔接抽样

### 链路 1：{{流程名}}

| 层 | 文件 | 关注点 | 结果 |
|---|---|---|---|
| HTTP Handler | `internal/interfaces/http/{{xxx}}.go:{{line}}` | 参数解析、错误码映射 | ✅ |
| Application | `internal/application/{{xxx}}.go:{{line}}` | 编排、事务边界 | ✅ |
| Repository | `internal/infrastructure/persistence/{{xxx}}.go:{{line}}` | SQL、超时、乐观锁 | ✅ |
| RPC Client | `internal/infrastructure/rpc/{{xxx}}.go:{{line}}` | 超时、重试、幂等 | ✅ |

发现的衔接问题：{{...}}

### 链路 2：{{流程名}}

{{同上}}

---

## 3. 配置完整性

| 引用位置 | 配置 key | 是否在 configs/ 中定义 | 默认值 |
|---|---|---|---|
| `cmd/server/main.go:{{line}}` | `server.port` | ✅ `configs/config.yaml` | 8080 |
| `infrastructure/persistence/db.go:{{line}}` | `mysql.dsn` | ✅ | — |
| {{...}} | {{...}} | {{...}} | {{...}} |

缺漏清单：{{...}}（如有）

---

## 4. trace_id / context 全链路

抽样链路：{{流程名}}

- [x/✗] 入口处生成或读取 trace_id（位置 `{{file:line}}`）
- [x/✗] context 一路透传到 DB 调用（位置 `{{file:line}}`）
- [x/✗] context 一路透传到 RPC 调用（位置 `{{file:line}}`）
- [x/✗] 关键日志携带 `trace_id` 字段
- [x/✗] 生产路径中无 `context.Background()` / `context.TODO()`

---

## 5. 遗漏回扫

> 打开**原始方案文档**，逐条核对。

### 5.1 功能列表

| 方案功能 | 覆盖情况 | 关联 Task | 缺口/备注 |
|---|---|---|---|
| 创建订单 | ✅ | T-009, T-010 | — |
| 取消订单 | ❌ 未覆盖 | — | 需新增 Task；或登记豁免 |
| {{...}} | {{...}} | {{...}} | {{...}} |

### 5.2 非功能需求

| 类别 | 需求 | 覆盖情况 | 关联 Task | 缺口/备注 |
|---|---|---|---|---|
| 限流 | 单用户 10 次/秒 | ✅ | T-XXX | — |
| 监控 | 关键链路 QPS/Latency/Error | ⚠️ 部分 | T-XXX | 缺 Error Rate 指标 |
| 日志 | 结构化 + trace_id | ✅ | 全部 | — |
| 报警 | 错误率 > 1% 报警 | ❌ | — | 仓库无报警基础设施，登记豁免 |
| 灰度 | 按 user_id 灰度 | ❌ | — | 方案要求但未落地 |
| 回滚 | 支持快速回滚 | ✅ | T-XXX | 通过 K8s rollback |
| 降级 | 优惠券服务降级 | ❌ | — | 方案要求但未落地 |
| 幂等 | 创建订单幂等 | ✅ | T-009 | — |
| 安全 | 鉴权 + SQL 注入防护 | ✅ | T-010, T-006 | — |

---

## 6. 一致性问题清单（不阻塞，但需整改）

| 问题 | 位置 | 建议 |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

---

## 7. 豁免登记（如有）

| 项目 | 豁免理由 | Owner | 后续整改时间 |
|---|---|---|---|
| 报警接入 | 仓库无报警基础设施 | {{...}} | 下个迭代 |

---

## 8. 反作弊与状态一致性（**强制门禁**）

### 8.1 SPEC_QUESTION 残留

```
$ grep -rn "// SPEC_QUESTION:" --include="*.go" .
{{命令输出 / "0 matches"}}
```

- 未解决条数：{{N}}（**必须为 0**，否则 FAIL）

### 8.2 attempt ≥ 3 但未通过

- `tasks.json` 中是否存在 `attempt >= 3 && status not in [passed, waived]` 的 Task：☐ 否 ☐ 是
- 若是，列表：{{T-XXX, T-YYY}}（**任一存在即 FAIL**）

### 8.3 进度状态一致性（PROGRESS.md ↔ tasks.json）

| 比对项 | PROGRESS.md | tasks.json | 一致 |
|---|---|---|---|
| Phase 0 状态 | done | done | ✅ |
| Phase 1 状态 | done | done | ✅ |
| Phase 2 状态 | done | done | ✅ |
| Phase 3/4 完成数 | X/N | X/N | ✅ |
| {{T-001 状态/Attempt}} | passed/1 | passed/1 | ✅ |
| {{...}} | {{...}} | {{...}} | {{...}} |

任一不一致 → **FAIL**。

### 8.4 SPEC_COVERAGE.md 未覆盖项

- 总数：{{N}}，未覆盖：{{Z}}（**必须 = 0** 或全部已豁免）
- 未覆盖项列表：{{...}}

### 8.5 TASKS / tasks.json 禁用字段扫描

```
$ grep -nE "(工作量|工时|估时|人天|story[ _-]?point|effort|estimateHours|manDays|workload)" \
    .spec2code/TASKS.md .spec2code/state/tasks.json
{{命令输出 / "0 matches"}}
```

- 命中条数：{{N}}（**必须为 0**，否则 FAIL）

---

## 9. 总体结论

☐ ✅ **PASS**：§1~§5、§8 全部通过；§6 一致性问题清单仅含 Minor；可上线
☐ ⚠️ **PASS_WITH_WAIVER**：存在 Major 问题但已在 §7 登记豁免（理由 + Owner + 后续整改时间）；可上线但需后续闭环
☐ ❌ **FAIL**：构建/测试不通过，或 §8 反作弊任一不通过，或存在未豁免的功能遗漏；不可上线

**上线门禁**：{{允许 / 不允许}}

**最大阻塞项**（如 FAIL）：{{...}}

**后续动作**：

- {{...}}

---

## ⏸ 等待用户确认

> 本文件为 Phase 5 产物。请回复：
>
> - ✅ approve              → 流水线落地完成
> - 🔧 revise: <反馈>       → 修订集成校验
> - ❌ reject               → 终止流水线（保留产物）
