# Multi-Agent Collaboration Rules Design

## Team Agent Autonomous Collaboration Specification

---

## 0. Agent Architecture Overview

### 0.1 Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Team Agent Architecture                     │
└─────────────────────────────────────────────────────────────────┘

        ┌─────────────────────────────────────────────┐
        │         Current Window (Auto Team Lead)     │
        │         Coordination, task allocation, progress tracking │
        └─────────────────────────────────────────────┘
                          │
        ┌─────────┬───────┼───────┬─────────┐
        │         │       │       │         │
        ▼         ▼       ▼       ▼         ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐
  │IaC Agent │ │Test Agent│ │Doc Agent │ │Task Manager   │
  │Terraform │ │ Test &   │ │ Docs     │ │  Kanboard     │
  │          │ │Validation│ │          │ │               │
  └──────────┘ └──────────┘ └──────────┘ └───────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Kanboard   │
                                        │  (via API)  │
                                        └─────────────┘
```

**Important:** The current window automatically assumes the Team Lead role, no need to create an additional Lead Agent.

### 0.2 Agent Responsibilities

| Agent | Primary Responsibilities | Deliverables | Validation Method | Exclusive Skill |
|-------|-------------------------|--------------|-------------------|-----------------|
| **Team Lead** (Current Window) | Task allocation, progress tracking, coordination | Update task status | - | - |
| **IaC Agent** | Write Terraform code | modules/ code | Test Agent validation | ✅ terraform-engineer |
| **Test Agent** | Write test scripts, validate functionality | tests/integration_test.py | Run tests | - |
| **Doc Agent** | Write README, documentation | README.md | Manual review | ✅ docs-writer |
| **Task Manager** | Manage Kanboard task status | Real-time task progress sync | Kanboard API | - |

**Important:**
- **IaC Agent** must use `/terraform-engineer` skill for all Terraform development tasks.
- **Doc Agent** must use `/docs-writer` skill for all documentation writing tasks.
- **Task Manager** is the only Agent allowed to access Kanboard, responsible for all ticket management.

### 0.3 Kanboard Access Permissions

| Agent | Kanboard Access | Description |
|-------|-----------------|-------------|
| **Task Manager** | ✅ Only authorized | Manage all tickets via API |
| **Team Lead** | ❌ Prohibited | Indirect operations through Task Manager |
| **IaC Agent** | ❌ Prohibited | Notify Task Manager via SendMessage |
| **Test Agent** | ❌ Prohibited | Notify Task Manager via SendMessage |
| **Doc Agent** | ❌ Prohibited | Notify Task Manager via SendMessage |

### 0.3 Vibe Coding Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Vibe Coding Workflow                        │
└─────────────────────────────────────────────────────────────────┘

  Current Window (Team Lead) assigns tasks
        │
        ▼
  2. IaC Agent receives task, writes Terraform code
        │
        ▼
  3. Test Agent validates code, runs tests
        │
        ▼
  4. Validation passed → Current window updates task status to ✅
        │
        ▼
  5. Continue to next task
```

### 0.4 Task Status Definitions

| Status | Icon | Description |
|--------|------|-------------|
| Pending | ⏳ | Task created, not started |
| In Progress | 🔄 | Agent is processing |
| Waiting for Validation | ⏸️ | Code complete, waiting for Test Agent validation |
| Completed | ✅ | Validation passed, task complete |
| Failed | ❌ | Validation failed, needs fix |

---

## 1. Task Queue Rules

### 1.1 Task Definition Structure

Each task must contain the following attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `task_id` | string | Unique identifier (e.g., IAC-001) |
| `subject` | string | Task title |
| `status` | enum | pending / in_progress / completed / failed |
| `owner` | string | Responsible Agent (null means unclaimed) |
| `blockedBy` | array | List of dependent task IDs |
| `priority` | number | Priority (lower number = higher priority) |
| `agentType` | string | Suitable Agent type (iac/test/doc) |

### 1.2 Task ID Naming Convention

```
{AgentType}-{Sequence}

Examples:
- IAC-001 (IaC Agent task)
- IAC-002 (IaC Agent task)
- TEST-001 (Test Agent task)
- DOC-001 (Doc Agent task)
```

---

## 2. Task Claiming Rules

### 2.1 Agent Claiming Permissions

| Agent | Claimable Task Types | Example |
|-------|---------------------|---------|
| **Team Lead** | All tasks | Coordination, allocation, monitoring |
| **IaC Agent** | `agentType="iac"` or `null` | Write Terraform code |
| **Test Agent** | `agentType="test"` | Run tests, validate functionality |
| **Doc Agent** | `agentType="doc"` | Write documentation |

### 2.2 Claiming Conditions

An Agent can claim a task if and only if:

```
Condition 1: status = "pending" (task available for claiming)
   AND
Condition 2: owner = null (unclaimed)
   AND
Condition 3: blockedBy is empty OR all dependent tasks status = "completed"
   AND
Condition 4: agentType matches Agent type OR agentType = null
```

**Pseudocode:**
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

### 2.3 Claiming Priority

When multiple tasks are available for claiming, use the following order:

1. **Priority** (lower priority number first)
2. **Task ID** (lower ID first, e.g., IAC-001 → IAC-002)

---

## 3. Task Execution Rules

### 3.1 Status Transitions

```
pending → in_progress → completed
    ↓         ↓
  failed    failed
```

| Transition | Trigger Condition | Operation |
|------------|-------------------|-----------|
| `pending` → `in_progress` | Agent claims task | `TaskUpdate(status="in_progress", owner="AgentName")` |
| `in_progress` → `completed` | Work completed | `TaskUpdate(status="completed")` |
| `in_progress` → `failed` | Work failed | `TaskUpdate(status="failed")` + notify Team Lead |

### 3.2 Agent Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Work Loop                               │
└─────────────────────────────────────────────────────────────────┘

  while tasks exist:
      │
      ▼
  1. View task list (TaskList)
      │
      ▼
  2. Find claimable tasks
      │
      ▼
  3. Claimable task available?
      ├─ Yes → Claim task (TaskUpdate)
      │         │
      │         ▼
      │    4. Execute work
      │         │
      │         ▼
      │    5. Update status
      │         │
      │         ▼
      │    6. Notify relevant Agents (SendMessage)
      │
      └─ No → Wait or idle
```

---

## 4. Task Dependency Rules

### 4.1 Dependency Definition

```python
TaskCreate(
  task_id="IAC-003",
  subject="Write Lambda Dispatch module",
  agentType="iac",
  addBlockedBy=["IAC-001"],  # Depends on IAC-001 (Lambda Greet module)
  priority=2
)
```

### 4.2 Dependency Check

Task A depends on Task B means:
- Task A can only be claimed after Task B is `completed`
- If Task B `failed`, Task A cannot start either

---

## 5. Inter-Agent Communication Rules

### 5.1 Communication Scenarios

| Scenario | Sender | Receiver | Message Type |
|----------|--------|----------|--------------|
| **Task Completion Notification** | Any Agent | Team Lead | Task completed |
| **Validation Request** | IaC Agent | Test Agent | Code complete, request validation |
| **Validation Result** | Test Agent | IaC Agent | Test passed/failed |
| **Documentation Request** | Team Lead | Doc Agent | Start writing documentation |
| **Error Notification** | Any Agent | Team Lead | Task failed |

### 5.2 Message Format

```python
# Task completion notification
SendMessage(
  type="message",
  recipient="team-lead",
  content="Task IAC-001 completed",
  summary="Cognito module writing complete"
)

# Validation request
SendMessage(
  type="message",
  recipient="test-agent",
  content="IAC-001, IAC-002 completed, please validate",
  summary="Request Lambda module validation"
)

# Validation result
SendMessage(
  type="message",
  recipient="iac-agent",
  content="Test passed: /greet endpoint validation successful",
  summary="TEST-001 complete"
)
```

---

## 6. Error Handling Rules

### 6.1 Error Classification

| Error Type | Handling Method | Responsible Party |
|------------|-----------------|-------------------|
| **Syntax Error** | Agent self-fix | Agent itself |
| **Configuration Error** | Fix and retry | Agent itself |
| **Dependency Issue** | Notify Team Lead | Team Lead |
| **Unresolvable** | Mark as failed, notify Team Lead | Agent + Team Lead |

### 6.2 Error Handling Workflow

```
Agent encounters error
      │
      ▼
  Can self-resolve?
      ├─ Yes → Fix → Re-execute
      │
      └─ No → TaskUpdate(status="failed")
                  │
                  ▼
            SendMessage(to="team-lead", content="Task failed: ...")
                  │
                  ▼
            Team Lead assessment
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
  Fixable                 Not fixable
      │                       │
      ▼                       ▼
  Reassign task           Cancel task
```

---

## 7. Concrete Execution Examples

### Example 1: IaC Agent Claims Task

```python
# IaC Agent workflow

# 1. View task list
tasks = TaskList()

# 2. Find claimable iac tasks
for task in tasks:
    if can_claim(task, self):
        # 3. Claim task
        TaskUpdate(
            task_id=task.id,
            owner="IaC Agent",
            status="in_progress"
        )

        # 4. Execute work (write Terraform code)
        write_terraform_code(task.subject)

        # 5. Complete
        TaskUpdate(task_id=task.id, status="completed")

        # 6. Notify Test Agent
        SendMessage(
            type="message",
            recipient="test-agent",
            content=f"{task.id} completed, please validate"
        )

        break  # Process one task at a time
```

### Example 2: Test Agent Responds to Message

```python
# Test Agent message handling

@on_message
def handle_message(message):
    if "completed" in message.content:
        # Extract task ID
        task_id = extract_task_id(message.content)

        # Create validation task
        TaskCreate(
            subject=f"Validate {task_id}",
            agentType="test",
            addBlockedBy=[task_id],  # Depends on original task
            priority=10
        )
```

### Example 3: Task Dependency Chain

```python
# Initial task creation

TaskCreate(
    task_id="IAC-001",
    subject="Write Cognito module",
    agentType="iac",
    priority=1
)

TaskCreate(
    task_id="IAC-002",
    subject="Write API Gateway module",
    agentType="iac",
    addBlockedBy=["IAC-001"],  # Depends on Cognito
    priority=2
)

TaskCreate(
    task_id="TEST-001",
    subject="Validate Cognito + API Gateway",
    agentType="test",
    addBlockedBy=["IAC-001", "IAC-002"],  # Depends on both modules
    priority=10
)
```

**Execution Order:**
```
1. IAC-001 completes
2. IAC-002 becomes claimable (dependency released)
3. IAC-002 completes
4. TEST-001 becomes claimable (all dependencies complete)
```

---

## 8. Agent Decision Tree

```
Agent starts
      │
      ▼
  Tasks available to claim?
      ├─ No → Wait / Request task
      │
      └─ Yes → Claim task
                │
                ▼
          Execute task
                │
                ▼
          Success?
          ├─ Yes → Mark complete → Notify relevant Agents → Continue to next
          │
          └─ No → Can fix?
                    ├─ Yes → Fix → Retry
                    │
                    └─ No → Mark failed → Notify Team Lead
```

---

## 9. Task Manager Agent Rules

### 9.1 Responsibility Definition

Task Manager is the **only** Agent authorized to access Kanboard, responsible for:

| Responsibility | Operation | Kanboard API |
|----------------|-----------|--------------|
| **Task Creation** | Create new ticket | `createTask` |
| **Status Update** | Move task to different column | `moveTaskPosition` |
| **Add Comment** | Record task progress | `createComment` |
| **Status Query** | Query task status | `searchTasks`, `getTask` |

### 9.2 Kanboard Status Mapping

| Agent Status | Kanboard Column | Column ID | Icon |
|--------------|-----------------|-----------|------|
| `pending` | Backlog | 9 | ⏳ |
| `in_progress` | Work in progress | 11 | 🔄 |
| `completed` | Done | 12 | ✅ |

### 9.3 Message Protocol

**All Agents must notify Task Manager via SendMessage to update task status:**

```python
# Task start
SendMessage(
    type="message",
    recipient="task-manager",
    content="TASK_START: IAC-001 starting DynamoDB module",
    summary="IAC-001 started"
)

# Task complete
SendMessage(
    type="message",
    content="TASK_DONE: IAC-001 complete",
    summary="IAC-001 complete"
)

# Task failed
SendMessage(
    type="message",
    content="TASK_FAILED: IAC-002 failed - reason description",
    summary="IAC-002 failed"
)

# Query request
SendMessage(
    type="message",
    content="TASK_QUERY: Query all Phase 4 task statuses",
    summary="Query task status"
)
```

### 9.4 Task Manager Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Task Manager Workflow                         │
└─────────────────────────────────────────────────────────────────┘

  Receive message
      │
      ▼
  Parse message type
      │
      ├─ TASK_START → moveTaskPosition(column_id: 11)
      │
      ├─ TASK_DONE → moveTaskPosition(column_id: 12)
      │
      ├─ TASK_FAILED → createComment(content)
      │
      └─ TASK_QUERY → searchTasks → SendMessage(result)
```

### 9.5 API Call Examples

```bash
# Task Manager uses kanboard-api.sh script

# Move task to Work in progress
~/.claude/kanboard-api.sh moveTaskPosition '{
    "project_id": 3,
    "task_id": 21,
    "column_id": 11,
    "position": 1,
    "swimlane_id": 3
}'

# Add comment
~/.claude/kanboard-api.sh createComment '{
    "task_id": 21,
    "content": "Task started - 2026-03-04"
}'

# Query task
~/.claude/kanboard-api.sh searchTasks '{
    "project_id": 3,
    "query": ""
}'
```

### 9.6 Configuration File Locations

| File | Path | Purpose |
|------|------|---------|
| Kanboard Config | `~/.claude/kanboard.json` | API endpoint + token |
| API Script | `~/.claude/kanboard-api.sh` | Command-line tool |
| Environment Variables | `~/.claude/settings.json` | KANBOARD_API_* |

---

*Document Version: 2.0*
*Created: 2026-03-02*
*Updated: 2026-03-04*
