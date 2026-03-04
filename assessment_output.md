🧪 AWS DevOps Assessment - Integration Test
============================================================
Timestamp: 2026-03-04T10:54:34.780928+00:00
Test Email: piaohulin2007@gmail.com
============================================================

🔐 Step 1: Cognito Authentication
------------------------------------------------------------
✅ Authentication successful!

🚀 Starting concurrent API tests...
============================================================

✅ All tests completed!

============================================================
📊 TEST RESULTS SUMMARY
============================================================

Total Tests: 4
✅ Successful: 4
❌ Failed: 0

------------------------------------------------------------
DETAILED RESULTS:
------------------------------------------------------------
✅ [us-east-1]
   Status Code: 200
   Latency: 2085.08ms
   Response Region: us-east-1

✅ [us-east-1] /dispatch
   Status Code: 200
   Latency: 1117.38ms
   Response Region: us-east-1

✅ [eu-west-1]
   Status Code: 200
   Latency: 2805.31ms
   Response Region: eu-west-1

✅ [eu-west-1] /dispatch
   Status Code: 200
   Latency: 1571.54ms
   Response Region: eu-west-1

------------------------------------------------------------
PERFORMANCE ANALYSIS:
------------------------------------------------------------

us-east-1 Average Latency: 1601.23ms
  - Greet: 2085.08ms
  - Dispatch: 1117.38ms

eu-west-1 Average Latency: 2188.43ms
  - Greet: 2805.31ms
  - Dispatch: 1571.54ms

🌍 Latency Difference:
   eu-west-1 is 587.20ms slower than us-east-1

============================================================

📍 REGION VERIFICATION:
------------------------------------------------------------
✅ [us-east-1] : Correct region
✅ [us-east-1] /dispatch: Correct region
✅ [eu-west-1] : Correct region
✅ [eu-west-1] /dispatch: Correct region

============================================================