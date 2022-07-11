resource "aws_cloudfront_origin_access_identity" "s3-cloudfront-identity" {
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3-cloudfront" {
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cache_policy_id        = "98bea9ec-fe04-4d6d-a220-59d6fba7ebad"
    cached_methods         = ["GET", "HEAD"]
    compress               = "true"
    default_ttl            = "3600"
    max_ttl                = "3600"
    min_ttl                = "3600"
    smooth_streaming       = "false"
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "https-only"
  }

  default_root_object = "index.html"
  enabled             = "true"
  http_version        = "http2"
  is_ipv6_enabled     = "true"

  origin {
    connection_attempts = "3"
    connection_timeout  = "10"
    domain_name         = aws_s3_bucket.s3-site.bucket_regional_domain_name
    origin_id           = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3-cloudfront-identity.cloudfront_access_identity_path
    }
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = "false"

  viewer_certificate {
    cloudfront_default_certificate = "true"
    minimum_protocol_version       = "TLSv1"
  }
}

