# Multi-Agent 协作规则设计

## Team Agent 自主协作规范

---

## 0. Agent 架构概览

### 0.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Team Agent 架构                             │
└─────────────────────────────────────────────────────────────────┘

        ┌─────────────────────────────────────────────┐
        │         当前窗口 (自动作为 Team Lead)        │
        │         协调、任务分配、进度跟踪              │
        └─────────────────────────────────────────────┘
                          │
        ┌─────────┬───────┼───────┬─────────┐
        │         │       │       │         │
        ▼         ▼       ▼       ▼         ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐
  │IaC Agent │ │Test Agent│ │Doc Agent │ │Task Manager   │
  │Terraform │ │ 测试验证  │ │  文档     │ │  Kanboard     │
  └──────────┘ └──────────┘ └──────────┘ └───────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Kanboard   │
                                        │  (via API)  │
                                        └─────────────┘
```

**重要：** 当前窗口自动承担 Team Lead 角色，无需额外创建 Lead Agent。

### 0.2 Agent 职责

| Agent | 主要职责 | 交付物 | 验证方式 | 专属 Skill |
|-------|----------|--------|----------|-----------|
| **Team Lead** (当前窗口) | 任务分配、进度跟踪、协调 | 更新任务状态 | - | - |
| **IaC Agent** | 编写 Terraform 代码 | modules/ 代码 | Test Agent 验证 | ✅ terraform-engineer |
| **Test Agent** | 编写测试脚本、验证功能 | tests/integration_test.py | 运行测试 | - |
| **Doc Agent** | 编写 README、文档 | README.md | 人工审核 | ✅ docs-writer |
| **Task Manager** | 管理 Kanboard 任务状态 | 实时同步任务进度 | Kanboard API | - |

**重要：**
- **IaC Agent** 必须使用 `/terraform-engineer` skill 执行所有 Terraform 开发任务。
- **Doc Agent** 必须使用 `/docs-writer` skill 执行所有文档编写任务。
- **Task Manager** 是唯一允许访问 Kanboard 的 Agent，负责所有 ticket 管理。

### 0.3 Kanboard 访问权限

| Agent | Kanboard 访问 | 说明 |
|-------|---------------|------|
| **Task Manager** | ✅ 唯一授权 | 通过 API 管理所有 tickets |
| **Team Lead** | ❌ 禁止 | 通过 Task Manager 间接操作 |
| **IaC Agent** | ❌ 禁止 | 通过 SendMessage 通知 Task Manager |
| **Test Agent** | ❌ 禁止 | 通过 SendMessage 通知 Task Manager |
| **Doc Agent** | ❌ 禁止 | 通过 SendMessage 通知 Task Manager |

### 0.3 Vibe Coding 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      Vibe Coding 流程                           │
└─────────────────────────────────────────────────────────────────┘

  当前窗口 (Team Lead) 分配任务
        │
        ▼
  2. IaC Agent 接收任务，编写 Terraform 代码
        │
        ▼
  3. Test Agent 验证代码，运行测试
        │
        ▼
  4. 验证通过 → 当前窗口更新任务状态为 ✅
        │
        ▼
  5. 继续下一个任务
```

### 0.4 任务状态定义

| 状态 | 图标 | 说明 |
|------|------|------|
| 待开始 | ⏳ | 任务已创建，未开始执行 |
| 进行中 | 🔄 | Agent 正在处理 |
| 等待验证 | ⏸️ | 代码已完成，等待 Test Agent 验证 |
| 已完成 | ✅ | 验证通过，任务完成 |
| 失败 | ❌ | 验证失败，需要修复 |

---

## 1. 任务队列规则

### 1.1 任务定义结构

每个任务必须包含以下属性：

| 属性 | 类型 | 说明 |
|------|------|------|
| `task_id` | string | 唯一标识符（如 IAC-001） |
| `subject` | string | 任务标题 |
| `status` | enum | pending / in_progress / completed / failed |
| `owner` | string | 负责的 Agent（null 表示未领取） |
| `blockedBy` | array | 依赖的任务 ID 列表 |
| `priority` | number | 优先级（数字越小越优先） |
| `agentType` | string | 适合的 Agent 类型（iac/test/doc） |

### 1.2 任务 ID 命名规则

```
{AgentType}-{序号}

示例：
- IAC-001 (IaC Agent 任务)
- IAC-002 (IaC Agent 任务)
- TEST-001 (Test Agent 任务)
- DOC-001 (Doc Agent 任务)
```

---

## 2. 任务领取规则

### 2.1 Agent 领取权限

| Agent | 可领取的任务类型 | 示例 |
|-------|------------------|------|
| **Team Lead** | 所有任务 | 协调、分配、监控 |
| **IaC Agent** | `agentType="iac"` 或 `null` | 编写 Terraform 代码 |
| **Test Agent** | `agentType="test"` | 运行测试、验证功能 |
| **Doc Agent** | `agentType="doc"` | 编写文档 |

### 2.2 领取条件

Agent 可以领取任务当且仅当：

```
条件 1：status = "pending" （任务待领取）
   AND
条件 2：owner = null （无人领取）
   AND
条件 3：blockedBy 为空 或 所有依赖任务 status = "completed"
   AND
条件 4：agentType 匹配 Agent 类型 或 agentType = null
```

**伪代码：**
```python
def can_claim(task, agent):
    if task.status != "pending":
        return False
    if task.owner is not None:
        return False
    if task.blockedBy:
        for dep_id in task.blockedBy:
            dep_task = get_task(dep_id)
            if dep_task.status != "completed":
                return False
    if task.agentType and task.agentType != agent.type:
        return False
    return True
```

### 2.3 领取优先级

当有多个任务可领取时，按以下顺序：

1. **优先级**（priority 数字小的优先）
2. **任务 ID**（ID 小的优先，如 IAC-001 → IAC-002）

---

## 3. 任务执行规则

### 3.1 状态转换

```
pending → in_progress → completed
    ↓         ↓
  failed    failed
```

| 转换 | 触发条件 | 操作 |
|------|----------|------|
| `pending` → `in_progress` | Agent 领取任务 | `TaskUpdate(status="in_progress", owner="AgentName")` |
| `in_progress` → `completed` | 工作完成 | `TaskUpdate(status="completed")` |
| `in_progress` → `failed` | 工作失败 | `TaskUpdate(status="failed")` + 通知 Team Lead |

### 3.2 Agent 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent 工作循环                               │
└─────────────────────────────────────────────────────────────────┘

  while 存在任务:
      │
      ▼
  1. 查看任务列表 (TaskList)
      │
      ▼
  2. 查找可领取的任务
      │
      ▼
  3. 有可领取任务？
      ├─ 是 → 领取任务 (TaskUpdate)
      │         │
      │         ▼
      │    4. 执行工作
      │         │
      │         ▼
      │    5. 更新状态
      │         │
      │         ▼
      │    6. 通知相关 Agent (SendMessage)
      │
      └─ 否 → 等待或空闲
```

---

## 4. 任务依赖规则

### 4.1 依赖定义

```python
TaskCreate(
  task_id="IAC-003",
  subject="编写 Lambda Dispatch 模块",
  agentType="iac",
  addBlockedBy=["IAC-001"],  # 依赖 IAC-001（Lambda Greet 模块）
  priority=2
)
```

### 4.2 依赖检查

任务 A 依赖任务 B，意味着：
- 任务 B `completed` 后，任务 A 才能被领取
- 如果任务 B `failed`，任务 A 也无法开始

---

## 5. Agent 间通信规则

### 5.1 通信场景

| 场景 | 发送者 | 接收者 | 消息类型 |
|------|--------|--------|----------|
| **任务完成通知** | 任何 Agent | Team Lead | 任务完成 |
| **验证请求** | IaC Agent | Test Agent | 代码完成，请求验证 |
| **验证结果** | Test Agent | IaC Agent | 测试通过/失败 |
| **文档请求** | Team Lead | Doc Agent | 开始编写文档 |
| **错误通知** | 任何 Agent | Team Lead | 任务失败 |

### 5.2 消息格式

```python
# 任务完成通知
SendMessage(
  type="message",
  recipient="team-lead",
  content="任务 IAC-001 已完成",
  summary="Cognito 模块编写完成"
)

# 验证请求
SendMessage(
  type="message",
  recipient="test-agent",
  content="IAC-001, IAC-002 已完成，请验证",
  summary="请求验证 Lambda 模块"
)

# 验证结果
SendMessage(
  type="message",
  recipient="iac-agent",
  content="测试通过：/greet 端点验证成功",
  summary="TEST-001 完成"
)
```

---

## 6. 错误处理规则

### 6.1 错误分类

| 错误类型 | 处理方式 | 负责方 |
|----------|----------|--------|
| **语法错误** | Agent 自己修复 | Agent 自己 |
| **配置错误** | 修复后重试 | Agent 自己 |
| **依赖问题** | 通知 Team Lead | Team Lead |
| **无法解决** | 标记 failed，通知 Team Lead | Agent + Team Lead |

### 6.2 错误处理流程

```
Agent 遇到错误
      │
      ▼
  能自己解决？
      ├─ 是 → 修复 → 重新执行
      │
      └─ 否 → TaskUpdate(status="failed")
                  │
                  ▼
            SendMessage(to="team-lead", content="任务失败: ...")
                  │
                  ▼
            Team Lead 评估
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
  可修复                   不可修复
      │                       │
      ▼                       ▼
  重新分配任务            取消任务
```

---

## 7. 具体执行示例

### 示例 1：IaC Agent 领取任务

```python
# IaC Agent 的工作流程

# 1. 查看任务列表
tasks = TaskList()

# 2. 查找可领取的 iac 任务
for task in tasks:
    if can_claim(task, self):
        # 3. 领取任务
        TaskUpdate(
            task_id=task.id,
            owner="IaC Agent",
            status="in_progress"
        )

        # 4. 执行工作（编写 Terraform 代码）
        write_terraform_code(task.subject)

        # 5. 完成
        TaskUpdate(task_id=task.id, status="completed")

        # 6. 通知 Test Agent
        SendMessage(
            type="message",
            recipient="test-agent",
            content=f"{task.id} 已完成，请验证"
        )

        break  # 一次只处理一个任务
```

### 示例 2：Test Agent 响应消息

```python
# Test Agent 收到消息后的处理

@on_message
def handle_message(message):
    if "已完成" in message.content:
        # 提取任务 ID
        task_id = extract_task_id(message.content)

        # 创建验证任务
        TaskCreate(
            subject=f"验证 {task_id}",
            agentType="test",
            addBlockedBy=[task_id],  # 依赖原任务
            priority=10
        )
```

### 示例 3：任务依赖链

```python
# 初始任务创建

TaskCreate(
    task_id="IAC-001",
    subject="编写 Cognito 模块",
    agentType="iac",
    priority=1
)

TaskCreate(
    task_id="IAC-002",
    subject="编写 API Gateway 模块",
    agentType="iac",
    addBlockedBy=["IAC-001"],  # 依赖 Cognito
    priority=2
)

TaskCreate(
    task_id="TEST-001",
    subject="验证 Cognito + API Gateway",
    agentType="test",
    addBlockedBy=["IAC-001", "IAC-002"],  # 依赖两个模块
    priority=10
)
```

**执行顺序：**
```
1. IAC-001 完成
2. IAC-002 变为可领取（依赖解除）
3. IAC-002 完成
4. TEST-001 变为可领取（所有依赖完成）
```

---

## 8. Agent 决策树

```
Agent 启动
      │
      ▼
  有任务可领取？
      ├─ 否 → 等待 / 请求任务
      │
      └─ 是 → 领取任务
                │
                ▼
          执行任务
                │
                ▼
          成功？
          ├─ 是 → 标记完成 → 通知相关 Agent → 继续下一个
          │
          └─ 否 → 能修复？
                    ├─ 是 → 修复 → 重试
                    │
                    └─ 否 → 标记失败 → 通知 Team Lead
```

---

## 9. Task Manager Agent 规则

### 9.1 职责定义

Task Manager 是**唯一**被授权访问 Kanboard 的 Agent，负责：

| 职责 | 操作 | Kanboard API |
|------|------|--------------|
| **任务创建** | 创建新 ticket | `createTask` |
| **状态更新** | 移动任务到不同列 | `moveTaskPosition` |
| **添加评论** | 记录任务进展 | `createComment` |
| **状态查询** | 查询任务状态 | `searchTasks`, `getTask` |

### 9.2 Kanboard 状态映射

| Agent 状态 | Kanboard 列 | Column ID | 图标 |
|------------|-------------|-----------|------|
| `pending` | Backlog | 9 | ⏳ |
| `in_progress` | Work in progress | 11 | 🔄 |
| `completed` | Done | 12 | ✅ |

### 9.3 消息协议

**所有 Agent 必须通过 SendMessage 通知 Task Manager 更新任务状态：**

```python
# 任务开始
SendMessage(
    type="message",
    recipient="task-manager",
    content="TASK_START: IAC-001 开始编写 DynamoDB 模块",
    summary="IAC-001 开始"
)

# 任务完成
SendMessage(
    type="message",
    content="TASK_DONE: IAC-001 完成",
    summary="IAC-001 完成"
)

# 任务失败
SendMessage(
    type="message",
    content="TASK_FAILED: IAC-002 失败 - 原因描述",
    summary="IAC-002 失败"
)

# 查询请求
SendMessage(
    type="message",
    content="TASK_QUERY: 查询 Phase 4 所有任务状态",
    summary="查询任务状态"
)
```

### 9.4 Task Manager 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Task Manager 工作流程                         │
└─────────────────────────────────────────────────────────────────┘

  收到消息
      │
      ▼
  解析消息类型
      │
      ├─ TASK_START → moveTaskPosition(column_id: 11)
      │
      ├─ TASK_DONE → moveTaskPosition(column_id: 12)
      │
      ├─ TASK_FAILED → createComment(content)
      │
      └─ TASK_QUERY → searchTasks → SendMessage(result)
```

### 9.5 API 调用示例

```bash
# Task Manager 使用 kanboard-api.sh 脚本

# 移动任务到 Work in progress
~/.claude/kanboard-api.sh moveTaskPosition '{
    "project_id": 3,
    "task_id": 21,
    "column_id": 11,
    "position": 1,
    "swimlane_id": 3
}'

# 添加评论
~/.claude/kanboard-api.sh createComment '{
    "task_id": 21,
    "content": "任务开始执行 - 2026-03-04"
}'

# 查询任务
~/.claude/kanboard-api.sh searchTasks '{
    "project_id": 3,
    "query": ""
}'
```

### 9.6 配置文件位置

| 文件 | 路径 | 用途 |
|------|------|------|
| Kanboard 配置 | `~/.claude/kanboard.json` | API endpoint + token |
| API 脚本 | `~/.claude/kanboard-api.sh` | 命令行工具 |
| 环境变量 | `~/.claude/settings.json` | KANBOARD_API_* |

---

*文档版本: 2.0*
*创建日期: 2026-03-02*
*更新日期: 2026-03-04*
