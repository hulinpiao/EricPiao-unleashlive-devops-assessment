Analyze the current codebase. Then use the team agent method to start multiple agents to solve the following errors:
  ((venv) ) hulin@Mac:~/Documents/jobs/unleashlive - devops assessment/v2/tests$ python integration_test.py --email hulindevtest@gmail.com --password Hulindevtest123!
  🧪 AWS DevOps Assessment - Integration Test
  ============================================================
  /Users/hulin/Documents/jobs/unleashlive - devops assessment/v2/tests/integration_test.py:286: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
    print(f"Timestamp: {datetime.utcnow().isoformat()}")
  Timestamp: 2026-03-04T05:32:46.745996
  Test Email: hulindevtest@gmail.com
  ============================================================

  🔐 Step 1: Cognito Authentication
  ------------------------------------------------------------
  ✅ Authentication successful!

  🚀 Starting concurrent API tests...
  ============================================================
  /Users/hulin/Documents/jobs/unleashlive - devops assessment/v2/tests/integration_test.py:160: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
    'timestamp': datetime.utcnow().isoformat()
  /Users/hulin/Documents/jobs/unleashlive - devops assessment/v2/tests/integration_test.py:135: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
    'timestamp': datetime.utcnow().isoformat()

  ✅ All tests completed!

  ============================================================
  📊 TEST RESULTS SUMMARY
  ============================================================

  Total Tests: 4
  ✅ Successful: 0
  ❌ Failed: 4

  ------------------------------------------------------------
  DETAILED RESULTS:
  ------------------------------------------------------------
  ❌ [us-east-1] greet
     Status Code: 0
     Latency: 755.18ms
     Response Region: N/A
     Error: HTTPSConnectionPool(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Max retries exceeded with url: /$defaultgreet (Caused by NameResolutionError("HTTPSConnection(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Failed to resolve
  'm0jtt2ga9b.execute-api.us-east-1.amazonaws.com' ([Errno 8] nodename nor servname provided, or not known)"))

  ❌ [us-east-1] dispatch
     Status Code: 0
     Latency: 3.05ms
     Response Region: N/A
     Error: HTTPSConnectionPool(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Max retries exceeded with url: /$defaultdispatch (Caused by NameResolutionError("HTTPSConnection(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Failed to resolve
  'm0jtt2ga9b.execute-api.us-east-1.amazonaws.com' ([Errno 8] nodename nor servname provided, or not known)"))

  ❌ [eu-west-1] greet
     Status Code: 500
     Latency: 2685.32ms
     Response Region: N/A

  ❌ [eu-west-1] dispatch
     Status Code: 500
     Latency: 2082.14ms
     Response Region: N/A

  ------------------------------------------------------------
  PERFORMANCE ANALYSIS:
  ------------------------------------------------------------

  ============================================================

  📍 REGION VERIFICATION:
  ------------------------------------------------------------

  ============================================================

  ✨ Test completed!

  Some people say the possible cause is an AWS API Gateway connection issue, with the following error message:

  HTTPSConnectionPool(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Max retries exceeded with url: /$defaultgreet (Caused by NameResolutionError("HTTPSConnection(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Failed to resolve
  'm0jtt2ga9b.execute-api.us-east-1.amazonaws.com' ([Errno 8] nodename nor servname provided, or not known)"))

  According to analysis, the root cause is:
  - DNS resolution in VPC (vpc-0d534680557c7da16) is disabled or misconfigured
  - Although the VPC has internet connectivity (Internet Gateway and routing are correctly configured), DNS queries cannot resolve API Gateway endpoint hostnames

  Required solutions:
  1. Enable DNS resolution and DNS hostnames in VPC settings
  2. Verify DHCP options set is configured as AmazonProvidedDNS
  3. Check if security groups allow DNS traffic on port 53

  Please help me generate specific fix steps and AWS CLI commands.
  \
  \
  I think it might be an AWS API Gateway connection issue, with the following error message:

  HTTPSConnectionPool(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Max retries exceeded with url: /$defaultgreet (Caused by NameResolutionError("HTTPSConnection(host='m0jtt2ga9b.execute-api.us-east-1.amazonaws.com', port=443): Failed to resolve
  'm0jtt2ga9b.execute-api.us-east-1.amazonaws.com' ([Errno 8] nodename nor servname provided, or not known)"))

  According to analysis, the root cause is:
  - DNS resolution in VPC (vpc-0d534680557c7da16) is disabled or misconfigured
  - Although the VPC has internet connectivity (Internet Gateway and routing are correctly configured), DNS queries cannot resolve API Gateway endpoint hostnames

  Required solutions:
  1. Enable DNS resolution and DNS hostnames in VPC settings
  2. Verify DHCP options set is configured as AmazonProvidedDNS
  3. Check if security groups allow DNS traffic on port 53

  Please help me generate specific fix steps and AWS CLI commands.
