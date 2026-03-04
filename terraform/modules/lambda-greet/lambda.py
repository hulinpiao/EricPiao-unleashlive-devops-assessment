import json
import boto3
import os
from datetime import datetime, timezone

# Environment variables
DYNAMODB_TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
REGION = os.environ['REGION']

# Extract SNS region from Topic ARN (format: arn:aws:sns:region:account:topic)
SNS_REGION = SNS_TOPIC_ARN.split(':')[3] if ':' in SNS_TOPIC_ARN else REGION

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=REGION)
sns = boto3.client('sns', region_name=SNS_REGION)

def lambda_handler(event, context):
    """
    Lambda handler for /greet endpoint.

    Writes log to DynamoDB and sends SNS message.
    Returns region information.
    """

    # Get request context (from API Gateway)
    request_context = event.get('requestContext', {})
    http_method = event.get('requestContext', {}).get('http', {}).get('method', '')

    # Parse body if present
    body = {}
    if event.get('body'):
        try:
            body = json.loads(event['body'])
        except:
            body = {}

    # Get email from Cognito claims or request body
    email = body.get('email') or request_context.get('authorizer', {}).get('claims', {}).get('email', 'unknown@example.com')

    # Create log entry
    log_entry = {
        'PK': f'LOG#{datetime.now(timezone.utc).isoformat()}',
        'Email': email,
        'Timestamp': datetime.now(timezone.utc).isoformat(),
        'Region': REGION,
        'Source': 'Lambda',
        'Endpoint': '/greet'
    }

    # Write to DynamoDB
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    try:
        table.put_item(Item=log_entry)
        print(f"Log entry written to DynamoDB: {log_entry['PK']}")
    except Exception as e:
        print(f"Error writing to DynamoDB: {str(e)}")
        # Continue anyway, as SNS is more important

    # Send SNS message
    sns_message = {
        'email': email,
        'source': 'Lambda',
        'region': REGION,
        'repo': os.environ.get('GITHUB_REPO', 'https://github.com/user/aws-assessment')
    }

    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(sns_message)
        )
        print(f"SNS message sent: {sns_message}")
    except Exception as e:
        print(f"Error sending SNS message: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to send notification'})
        }

    # Return response
    response = {
        'message': f'Greetings from {REGION}!',
        'region': REGION,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'log_entry': log_entry['PK']
    }

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(response)
    }
