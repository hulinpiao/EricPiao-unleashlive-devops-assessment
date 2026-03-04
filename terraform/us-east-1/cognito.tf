# Cognito User Pool and Client (us-east-1 only)

# User Pool
resource "aws_cognito_user_pool" "this" {
  name = "assessment-user-pool"

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Verification settings
  auto_verified_attributes = ["email"]

  # Username attributes
  username_attributes = ["email"]

  tags = var.common_tags
}

# User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "assessment-client"
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows           = ["ALLOW_USER_PASSWORD_AUTH"]
  allowed_oauth_flows           = []
  allowed_oauth_scopes          = []
  prevent_user_existence_errors = "ENABLED"

  # Token settings (in hours for access/id tokens, days for refresh token)
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  # Callback URLs (adjust as needed)
  callback_urls                = ["https://example.com/callback"]
  supported_identity_providers = ["COGNITO"]

  # Enable SRP (Secure Remote Password) for better compatibility
  generate_secret = false

  depends_on = [aws_cognito_user_pool.this]
}

# User Pool Domain (optional, for hosted UI)
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "assessment-auth"
  user_pool_id = aws_cognito_user_pool.this.id

  depends_on = [aws_cognito_user_pool.this]
}
