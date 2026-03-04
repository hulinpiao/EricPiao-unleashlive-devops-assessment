# Phase 5: 测试开发

**预计时间：** 30分钟
**负责 Agent：** Test Agent
**依赖：** Phase 3, Phase 4 完成

---

## 阶段目标

编写集成测试脚本，验证两个区域的 API 功能和性能。

---

## 任务清单

### TEST-001: 编写测试脚本

| 字段 | 内容 |
|------|------|
| **Task ID** | `TEST-001` |
| **Status** | ⏳ |
| **Owner** | Test Agent |
| **Depends On** | `DEP-006`, `DEP-010` |
| **Description** | 创建集成测试脚本：<br>1. Cognito 登录获取 JWT<br>2. 并发调用 4 个 API 端点<br>3. 验证响应中的 region 字段<br>4. 测量并对比延迟 |
| **Deliverable** | `tests/integration_test.py` |
| **Acceptance Criteria** | Python 代码无语法错误、实现了所有必需功能 |

### TEST-002: 编写 requirements

| 字段 | 内容 |
|------|------|
| **Task ID** | `TEST-002` |
| **Status** | ⏳ |
| **Owner** | Test Agent |
| **Depends On** | `TEST-001` |
| **Description** | 列出测试脚本所需的 Python 依赖 |
| **Deliverable** | `tests/requirements.txt` |
| **Acceptance Criteria** | 包含 boto3, asyncio 等依赖、版本明确 |

---

## 执行顺序

```
TEST-001 → TEST-002
```

---

## 测试内容

```python
# tests/integration_test.py 功能概览

1. Cognito 登录
   - 使用候选人邮箱登录
   - 获取 JWT Token

2. 并发调用 4 个端点
   - us-east-1: /greet
   - us-east-1: /dispatch
   - eu-west-1: /greet
   - eu-west-1: /dispatch

3. 验证结果
   - 响应状态码 = 200
   - region 字段正确
   - SNS 消息发送成功

4. 性能分析
   - 输出每个请求的延迟
   - 对比两个区域的延迟差异
```

---

## 验收标准

- [ ] 测试脚本可运行
- [ ] 能验证 4 个端点
- [ ] 能输出延迟对比数据
- [ ] requirements.txt 包含所有依赖

---

## 测试执行

```bash
cd tests
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

## 下一阶段

完成后进入 **[Phase 6: CI/CD 配置](../06-cicd/plan.md)**
