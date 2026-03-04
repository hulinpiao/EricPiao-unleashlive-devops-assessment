# Terraform State Backend
terraform {
  backend "s3" {
    bucket  = "unleash-assessment-terraform-state"
    key     = "environments/us-east-1/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # Note: Not using DynamoDB locking for this assessment
    # In production, you should enable state locking with:
    # dynamodb_table = "terraform-state-lock"
  }
}
