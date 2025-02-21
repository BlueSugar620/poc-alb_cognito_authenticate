resource "aws_cognito_user_pool" "main" {
  name = "alb-cognito-sample"

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  auto_verified_attributes = ["email"]
  alias_attributes         = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_message = "{username}さん、あなたの初期パスワードは {####} です。初回ログインの後パスワード変更が必要です。"
      email_subject = "$invite to alb-cognito sample"
      sms_message   = "{username}さん、あなたの初期パスワードは {####} です。初回ログインの後パスワード変更が必要です。"
    }
  }
}

resource "aws_acm_certificate" "auth" {
  domain_name       = "auth.${var.domain_name}"
  validation_method = "DNS"
  provider          = aws.virginia
}

resource "aws_route53_record" "auth_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.auth.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  zone_id         = data.aws_route53_zone.main.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "auth" {
  certificate_arn         = aws_acm_certificate.auth.arn
  validation_record_fqdns = [for record in aws_route53_record.auth_certificate : record.fqdn]
  provider                = aws.virginia
}

resource "aws_cognito_user_pool_domain" "main" {
  domain          = "auth.${aws_route53_record.main.name}"
  certificate_arn = aws_acm_certificate.auth.arn
  user_pool_id    = aws_cognito_user_pool.main.id

  depends_on = [aws_acm_certificate_validation.auth]
}

resource "aws_route53_record" "auth" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "auth.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = aws_cognito_user_pool_domain.main.cloudfront_distribution
    zone_id                = aws_cognito_user_pool_domain.main.cloudfront_distribution_zone_id
    evaluate_target_health = true
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "alb-cognito-sample"
  user_pool_id = aws_cognito_user_pool.main.id

  callback_urls = [
    "https://${var.domain_name}/oauth2/idpresponse"
  ]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  allowed_oauth_flows_user_pool_client = true
}

