# us-east-1 部署指南

## 执行步骤

### 1. 初始化并预览

```bash
cd terraform/us-east-1
terraform init
terraform plan
```

### 2. 执行部署

```bash
terraform apply
```

确认提示时输入 `yes`。

### 3. 获取输出值

```bash
# 获取 Cognito 配置（用于 eu-west-1）
terraform output cognito_user_pool_id
terraform output cognito_client_id

# 获取 API Gateway URL
terraform output api_gateway_invoke_url
terraform output testing_instructions
```

### 4. 保存配置（用于 eu-west-1）

```bash
# 将以下输出保存，用于 Phase 4:
COGNITO_POOL_ID=$(terraform output -raw cognito_user_pool_id)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
API_URL=$(terraform output -raw api_gateway_invoke_url)

echo "Cognito Pool ID: $COGNITO_POOL_ID"
echo "Cognito Client ID: $COGNITO_CLIENT_ID"
echo "API URL: $API_URL"
```

---

## 预期资源

部署成功后，将创建以下资源：

| 资源类型 | 数量 | 说明 |
|----------|------|------|
| Cognito User Pool | 1 | 用户认证 |
| Cognito User Pool Client | 1 | 客户端配置 |
| Cognito Domain | 1 | 托管 UI 域名 |
| DynamoDB Table | 1 | GreetingLogs 表 |
| Lambda Functions | 2 | greet, dispatch |
| API Gateway | 1 | HTTP API |
| ECS Cluster | 1 | Fargate 集群 |
| ECS Task Definition | 1 | dispatch 任务 |
| CloudWatch Log Groups | 3 | API, Lambda, ECS |

---

## 测试验证

### 创建 Cognito 测试用户

```bash
# 创建用户
aws cognito-idp sign-up \
  --client-id $(terraform output -raw cognito_client_id) \
  --username test@example.com \
  --password TestPass123! \
  --user-attributes Name=email,Value=test@example.com

# 确认用户（跳过验证）
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id $(terraform output -raw cognito_user_pool_id) \
  --username test@example.com
```

### 测试 /greet 端点

```bash
# 获取 JWT Token
TOKEN=$(aws cognito-idp initiate-auth \
  --client-id $(terraform output -raw cognito_client_id) \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=test@example.com,PASSWORD=TestPass123! \
  --query 'AuthenticationResult.IdToken' \
  --output text)

# 调用 /greet
curl -H "Authorization: Bearer $TOKEN" \
  $(terraform output -raw api_greet_url)
```

### 测试 /dispatch 端点

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' \
  $(terraform output -raw api_dispatch_url)
```

---

## 成本估算

| 资源 | 预计月费用 |
|------|-----------|
| API Gateway | $0.01 |
| Lambda (100万次请求) | ~$0.50 |
| DynamoDB (按需) | ~$1.00 |
| ECS Fargate (按实际使用) | ~$0.10 |
| Cognito | 免费 |
| CloudWatch Logs | ~$0.50 |
| **总计** | **~$2-3/月** |

⚠️ **完成测试后立即销毁资源：**
```bash
terraform destroy
```

---

## 故障排查

### 1. Cognito 域名冲突
如果域名 `assessment-auth` 已存在，修改 `cognito.tf` 中的域名。

### 2. API Gateway 授权错误
确保 Cognito User Pool 已正确创建并获取 JWT Token。

### 3. ECS 任务失败
检查 CloudWatch Logs:
```bash
aws logs tail /ecs/aws-devops-assessment-ecs --follow
```

---

## 下一步

部署成功后，继续 **Phase 4: eu-west-1 部署**
