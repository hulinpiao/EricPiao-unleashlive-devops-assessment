import json
import boto3
import os
from datetime import datetime, timezone

# Environment variables
ECS_CLUSTER_ARN = os.environ['ECS_CLUSTER_ARN']
ECS_TASK_DEF_ARN = os.environ['ECS_TASK_DEF_ARN']
SUBNET_ID = os.environ['SUBNET_ID']
SECURITY_GROUP_ID = os.environ['SECURITY_GROUP_ID']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
REGION = os.environ['REGION']

# Initialize AWS clients
ecs = boto3.client('ecs', region_name=REGION)
sns = boto3.client('sns', region_name=REGION)

def lambda_handler(event, context):
    """
    Lambda handler for /dispatch endpoint.

    Triggers ECS Fargate task which sends SNS message.
    Returns region information.
    """

    # Get request context
    request_context = event.get('requestContext', {})

    # Parse body if present
    body = {}
    if event.get('body'):
        try:
            body = json.loads(event['body'])
        except:
            body = {}

    # Get email from Cognito claims or request body
    email = body.get('email') or request_context.get('authorizer', {}).get('claims', {}).get('email', 'unknown@example.com')

    # Extract cluster and task definition from ARNs
    cluster_name = ECS_CLUSTER_ARN.split('/')[-1]
    task_def_name = ECS_TASK_DEF_ARN.split('/')[-1]

    # Run ECS task
    try:
        response = ecs.run_task(
            cluster=cluster_name,
            taskDefinition=task_def_name,
            launchType='FARGATE',
            network_configuration={
                'awsvpcConfiguration': {
                    'subnets': [SUBNET_ID],
                    'securityGroups': [SECURITY_GROUP_ID],
                    'assignPublicIp': 'ENABLED'
                }
            },
            overrides={
                'containerOverrides': [
                    {
                        'name': 'aws-cli',
                        'environment': [
                            {
                                'name': 'EMAIL',
                                'value': email
                            },
                            {
                                'name': 'SNS_TOPIC_ARN',
                                'value': SNS_TOPIC_ARN
                            },
                            {
                                'name': 'REGION',
                                'value': REGION
                            },
                            {
                                'name': 'GITHUB_REPO',
                                'value': os.environ.get('GITHUB_REPO', 'https://github.com/user/aws-assessment')
                            }
                        ]
                    }
                ]
            }
        )

        task_arn = response['tasks'][0]['taskArn']
        task_id = task_arn.split('/')[-1]
        print(f"ECS task started: {task_id}")

    except Exception as e:
        print(f"Error running ECS task: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Failed to start ECS task: {str(e)}'})
        }

    # Return response
    response = {
        'message': f'Task dispatched from {REGION}!',
        'region': REGION,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'task_id': task_id,
        'cluster': cluster_name
    }

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(response)
    }
