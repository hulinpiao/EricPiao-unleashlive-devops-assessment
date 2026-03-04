# Phase 5: Test Development

**Estimated Time:** 30 minutes
**Responsible Agent:** Test Agent
**Dependencies:** Phase 3, Phase 4 complete

---

## Phase Objective

Write integration test scripts to verify API functionality and performance in both regions.

---

## Task List

### TEST-001: Write Test Script

| Field | Content |
|-------|---------|
| **Task ID** | `TEST-001` |
| **Status** | ⏳ |
| **Owner** | Test Agent |
| **Depends On** | `DEP-006`, `DEP-010` |
| **Description** | Create integration test script:<br>1. Cognito login to get JWT<br>2. Concurrent calls to 4 API endpoints<br>3. Verify region field in responses<br>4. Measure and compare latency |
| **Deliverable** | `tests/integration_test.py` |
| **Acceptance Criteria** | Python code has no syntax errors, implements all required functionality |

### TEST-002: Write Requirements

| Field | Content |
|-------|---------|
| **Task ID** | `TEST-002` |
| **Status** | ⏳ |
| **Owner** | Test Agent |
| **Depends On** | `TEST-001` |
| **Description** | List Python dependencies required by test script |
| **Deliverable** | `tests/requirements.txt` |
| **Acceptance Criteria** | Includes boto3, asyncio and other dependencies, versions specified |

---

## Execution Order

```
TEST-001 → TEST-002
```

---

## Test Content

```python
# tests/integration_test.py functionality overview

1. Cognito Login
   - Login using candidate email
   - Get JWT Token

2. Concurrent calls to 4 endpoints
   - us-east-1: /greet
   - us-east-1: /dispatch
   - eu-west-1: /greet
   - eu-west-1: /dispatch

3. Verify Results
   - Response status code = 200
   - Region field is correct
   - SNS message sent successfully

4. Performance Analysis
   - Output latency for each request
   - Compare latency difference between regions
```

---

## Acceptance Criteria

- [ ] Test script is runnable
- [ ] Can verify 4 endpoints
- [ ] Can output latency comparison data
- [ ] requirements.txt includes all dependencies

---

## Test Execution

```bash
cd tests
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

## Next Phase

After completion, proceed to **[Phase 6: CI/CD Configuration](../06-cicd/plan.md)**
