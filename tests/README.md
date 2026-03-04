# Integration Tests

> End-to-end API validation for multi-region AWS deployment.

---

## Overview

This test suite validates the deployed AWS infrastructure by:

1. Authenticating with Cognito
2. Calling API endpoints in both regions
3. Verifying responses and SNS message delivery
4. Measuring latency across regions

---

## Test Coverage

| Test | Description |
|------|-------------|
| Cognito Auth | Login and JWT token retrieval |
| us-east-1 /greet | API call + DynamoDB write + SNS |
| us-east-1 /dispatch | API call + ECS task + SNS |
| eu-west-1 /greet | API call + DynamoDB write + SNS |
| eu-west-1 /dispatch | API call + ECS task + SNS |
| Latency Comparison | Response time across regions |

---

## Prerequisites

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

## Configuration

Set environment variables or edit the script:

```bash
export COGNITO_USER_POOL_ID="us-east-1_xxxxx"
export COGNITO_CLIENT_ID="xxxxxxxxxx"
export API_URL_US_EAST_1="https://xxx.execute-api.us-east-1.amazonaws.com"
export API_URL_EU_WEST_1="https://xxx.execute-api.eu-west-1.amazonaws.com"
```

Or get from Terraform outputs:

```bash
# From us-east-1 deployment
cd ../terraform/us-east-1
export COGNITO_USER_POOL_ID=$(terraform output -raw cognito_pool_id)
export COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
export API_URL_US_EAST_1=$(terraform output -raw api_gateway_url)

# From eu-west-1 deployment
cd ../eu-west-1
export API_URL_EU_WEST_1=$(terraform output -raw api_gateway_url)
```

---

## Run Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run tests
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `--email` | Cognito user email |
| `--password` | Cognito user password |
| `--environment` | Environment name (default: development) |

---

## Expected Output

```
==========================================
Integration Test Results
==========================================

✅ Cognito Authentication: SUCCESS
✅ us-east-1 /greet: 200 (latency: 245ms)
✅ us-east-1 /dispatch: 200 (latency: 312ms)
✅ eu-west-1 /greet: 200 (latency: 198ms)
✅ eu-west-1 /dispatch: 200 (latency: 267ms)

SNS Messages: 4 sent
Latency Comparison: eu-west-1 faster by 47ms average

==========================================
ALL TESTS PASSED
==========================================
```

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `InvalidPasswordException` | Check password meets Cognito policy |
| `NotAuthorizedException` | Verify Cognito Pool ID and Client ID |
| `401 Unauthorized` | JWT token expired, re-authenticate |
| `404 Not Found` | Check API Gateway URL |
| `Timeout` | Increase timeout or check AWS region |

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `boto3` | AWS SDK for Python |
| `requests` | HTTP client |
| `asyncio` | Concurrent API calls |

---

*Version: 1.0*
*Last Updated: 2026-03-04*
