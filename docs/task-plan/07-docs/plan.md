# Phase 7: 文档编写

**预计时间：** 15分钟
**负责 Agent：** Doc Agent
**依赖：** Phase 4, Phase 5 完成

---

## 阶段目标

编写项目 README.md，包含完整的使用说明。

---

## 任务清单

### DOC-001: 编写 README.md

| 字段 | 内容 |
|------|------|
| **Task ID** | `DOC-001` |
| **Status** | ⏳ |
| **Owner** | Doc Agent |
| **Skill** | `/docs-writer` |
| **Depends On** | `DEP-010`, `TEST-001`, `CICD-001` |
| **Description** | 创建项目使用文档：<br>1. 项目简介<br>2. 架构图<br>3. 前置条件<br>4. 部署步骤<br>5. 测试说明<br>6. 清理说明 |
| **Deliverable** | `README.md` |
| **Acceptance Criteria** | 格式正确、包含所有章节、步骤可执行 |

---

## README 结构

```markdown
# AWS DevOps Assessment

## 项目简介
简要说明项目目标和架构

## 架构图
展示两个区域的部署架构

## 前置条件
- AWS CLI
- Terraform
- Python 3.11

## 部署步骤
### 1. us-east-1 部署
### 2. eu-west-1 部署

## 测试说明
如何运行测试脚本

## 清理说明
terraform destroy 命令
```

---

## 验收标准

- [ ] README.md 格式正确
- [ ] 包含所有必需章节
- [ ] 部署步骤清晰可执行
- [ ] 测试说明完整

---

## 项目完成

✅ **所有 Phase 完成！**

**最后步骤：**
1. 运行测试验证功能
2. 确认 SNS 消息发送成功
3. 执行 `terraform destroy` 清理资源
4. 提交代码到 GitHub
