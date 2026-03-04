#!/bin/sh
set -e

echo "Starting ECS task script..."
echo "EMAIL: $EMAIL"
echo "SNS_TOPIC_ARN: $SNS_TOPIC_ARN"
echo "REGION: $REGION"

# Send SNS message
sns_payload=$(cat <<EOF
{
  "email": "$EMAIL",
  "source": "ECS",
  "region": "$REGION",
  "repo": "$GITHUB_REPO"
}
EOF
)

echo "Sending SNS message..."
aws sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --message "$sns_payload" \
  --region "$REGION"

echo "SNS message sent successfully!"
echo "ECS task completed."
