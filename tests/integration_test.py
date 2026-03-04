#!/usr/bin/env python3
"""
AWS DevOps Assessment - Integration Test

Tests the /greet and /dispatch endpoints in both us-east-1 and eu-west-1 regions.

Usage:
    python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
"""

import asyncio
import argparse
import json
import time
import boto3
import requests
from typing import Dict, List, Any
from datetime import datetime, timezone

# Test Configuration
CONFIG = {
    "cognito": {
        "user_pool_id": "us-east-1_l3E5QLXQS",
        "client_id": "3qkmqvl0dchmmubm99td0s39fq",
        "region": "us-east-1"
    },
    "api_endpoints": {
        "us-east-1": {
            "base_url": "https://vvlh40b81e.execute-api.us-east-1.amazonaws.com/$default",
            "greet": "",
            "dispatch": "/dispatch"
        },
        "eu-west-1": {
            "base_url": "https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default",
            "greet": "",
            "dispatch": "/dispatch"
        }
    }
}


class CognitoAuth:
    """Handle Cognito authentication"""

    def __init__(self, config: Dict):
        self.client = boto3.client('cognito-idp', region_name=config['region'])
        self.user_pool_id = config['user_pool_id']
        self.client_id = config['client_id']
        self.token = None

    def login(self, email: str, password: str) -> bool:
        """
        Login to Cognito and retrieve JWT token

        Args:
            email: User email
            password: User password

        Returns:
            True if login successful, False otherwise
        """
        try:
            response = self.client.initiate_auth(
                ClientId=self.client_id,
                AuthFlow='USER_PASSWORD_AUTH',
                AuthParameters={
                    'USERNAME': email,
                    'PASSWORD': password
                }
            )

            self.token = response['AuthenticationResult']['IdToken']
            return True

        except Exception as e:
            print(f"❌ Cognito login failed: {str(e)}")
            return False

    def get_headers(self) -> Dict[str, str]:
        """Get headers with JWT token for API requests"""
        if not self.token:
            raise ValueError("Not logged in. Call login() first.")

        return {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }


class APITester:
    """Handle API testing and performance measurement"""

    def __init__(self, config: Dict):
        self.config = config
        self.results = []

    async def call_api(self, region: str, endpoint: str, method: str = "GET",
                      body: Dict = None, headers: Dict = None) -> Dict[str, Any]:
        """
        Call API endpoint and measure performance

        Args:
            region: AWS region (us-east-1 or eu-west-1)
            endpoint: API endpoint path
            method: HTTP method
            body: Request body (for POST requests)
            headers: Request headers

        Returns:
            Dictionary with response data and timing
        """
        url = f"{self.config[region]['base_url']}{endpoint}"

        start_time = time.time()

        try:
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=30)
            elif method == "POST":
                response = requests.post(url, json=body, headers=headers, timeout=30)
            else:
                raise ValueError(f"Unsupported method: {method}")

            end_time = time.time()
            latency = (end_time - start_time) * 1000  # Convert to ms

            result = {
                'region': region,
                'endpoint': endpoint,
                'method': method,
                'status_code': response.status_code,
                'latency_ms': round(latency, 2),
                'success': response.status_code == 200,
                'response_body': response.text if response.text else None,
                'timestamp': datetime.now(timezone.utc).isoformat()
            }

            # Try to parse JSON and extract region field
            if result['response_body']:
                try:
                    data = json.loads(result['response_body'])
                    result['response_region'] = data.get('region', 'N/A')
                except json.JSONDecodeError:
                    result['response_region'] = 'N/A'

            return result

        except Exception as e:
            end_time = time.time()
            latency = (end_time - start_time) * 1000

            return {
                'region': region,
                'endpoint': endpoint,
                'method': method,
                'status_code': 0,
                'latency_ms': round(latency, 2),
                'success': False,
                'error': str(e),
                'timestamp': datetime.now(timezone.utc).isoformat()
            }

    async def test_endpoint(self, region: str, endpoint_type: str,
                            headers: Dict, email: str = None):
        """Test a single endpoint"""
        if endpoint_type == "greet":
            # Use empty string to match $default route
            result = await self.call_api(region, "", "GET", headers=headers)
        elif endpoint_type == "dispatch":
            body = {"email": email} if email else {}
            # Use /dispatch to match POST /dispatch route
            result = await self.call_api(region, "/dispatch", "POST", body=body, headers=headers)
        else:
            raise ValueError(f"Unknown endpoint type: {endpoint_type}")

        self.results.append(result)
        return result

    async def run_all_tests(self, headers: Dict, email: str):
        """Run all tests concurrently"""
        print("\n🚀 Starting concurrent API tests...")
        print("=" * 60)

        tasks = [
            self.test_endpoint("us-east-1", "greet", headers),
            self.test_endpoint("us-east-1", "dispatch", headers, email),
            self.test_endpoint("eu-west-1", "greet", headers),
            self.test_endpoint("eu-west-1", "dispatch", headers, email)
        ]

        await asyncio.gather(*tasks)

        print("\n✅ All tests completed!")

    def print_summary(self):
        """Print test summary"""
        print("\n" + "=" * 60)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 60)

        total = len(self.results)
        successful = sum(1 for r in self.results if r['success'])
        failed = total - successful

        print(f"\nTotal Tests: {total}")
        print(f"✅ Successful: {successful}")
        print(f"❌ Failed: {failed}")

        # Detailed results
        print("\n" + "-" * 60)
        print("DETAILED RESULTS:")
        print("-" * 60)

        for result in self.results:
            status = "✅" if result['success'] else "❌"
            region = result['region']
            endpoint = result['endpoint']
            status_code = result['status_code']
            latency = result['latency_ms']
            response_region = result.get('response_region', 'N/A')

            print(f"{status} [{region}] {endpoint}")
            print(f"   Status Code: {status_code}")
            print(f"   Latency: {latency}ms")
            print(f"   Response Region: {response_region}")

            if not result['success'] and 'error' in result:
                print(f"   Error: {result['error']}")
            print()

        # Performance comparison by region
        print("-" * 60)
        print("PERFORMANCE ANALYSIS:")
        print("-" * 60)

        us_east_latencies = [r['latency_ms'] for r in self.results if r['region'] == 'us-east-1' and r['success']]
        eu_west_latencies = [r['latency_ms'] for r in self.results if r['region'] == 'eu-west-1' and r['success']]

        if us_east_latencies:
            avg_us = sum(us_east_latencies) / len(us_east_latencies)
            print(f"\nus-east-1 Average Latency: {avg_us:.2f}ms")
            print(f"  - Greet: {us_east_latencies[0] if len(us_east_latencies) > 0 else 'N/A'}ms")
            print(f"  - Dispatch: {us_east_latencies[1] if len(us_east_latencies) > 1 else 'N/A'}ms")

        if eu_west_latencies:
            avg_eu = sum(eu_west_latencies) / len(eu_west_latencies)
            print(f"\neu-west-1 Average Latency: {avg_eu:.2f}ms")
            print(f"  - Greet: {eu_west_latencies[0] if len(eu_west_latencies) > 0 else 'N/A'}ms")
            print(f"  - Dispatch: {eu_west_latencies[1] if len(eu_west_latencies) > 1 else 'N/A'}ms")

        if us_east_latencies and eu_west_latencies:
            diff = avg_eu - avg_us
            print(f"\n🌍 Latency Difference:")
            print(f"   eu-west-1 is {abs(diff):.2f}ms {'slower' if diff > 0 else 'faster'} than us-east-1")

        print("\n" + "=" * 60)

        # Verify region fields
        print("\n📍 REGION VERIFICATION:")
        print("-" * 60)

        for result in self.results:
            if result['success']:
                response_region = result.get('response_region', 'N/A')
                expected_region = result['region']

                if expected_region == "us-east-1" and response_region == "us-east-1":
                    print(f"✅ [{result['region']}] {result['endpoint']}: Correct region")
                elif expected_region == "eu-west-1" and response_region == "eu-west-1":
                    print(f"✅ [{result['region']}] {result['endpoint']}: Correct region")
                else:
                    print(f"⚠️  [{result['region']}] {result['endpoint']}: Region mismatch (expected: {expected_region}, got: {response_region})")

        print("\n" + "=" * 60)


async def main():
    """Main test execution"""
    parser = argparse.ArgumentParser(description='AWS DevOps Assessment Integration Test')
    parser.add_argument('--email', required=True, help='Cognito user email')
    parser.add_argument('--password', required=True, help='Cognito user password')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')

    args = parser.parse_args()

    print("🧪 AWS DevOps Assessment - Integration Test")
    print("=" * 60)
    print(f"Timestamp: {datetime.now(timezone.utc).isoformat()}")
    print(f"Test Email: {args.email}")
    print("=" * 60)

    # Initialize
    auth = CognitoAuth(CONFIG['cognito'])
    tester = APITester(CONFIG['api_endpoints'])

    # Step 1: Cognito Login
    print("\n🔐 Step 1: Cognito Authentication")
    print("-" * 60)

    if not auth.login(args.email, args.password):
        print("❌ Authentication failed. Exiting.")
        return

    print("✅ Authentication successful!")

    headers = auth.get_headers()

    # Step 2: Run API Tests
    await tester.run_all_tests(headers, args.email)

    # Step 3: Print Summary
    tester.print_summary()

    print("\n✨ Test completed!")


if __name__ == "__main__":
    asyncio.run(main())
