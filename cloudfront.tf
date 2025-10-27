data "aws_cloudfront_origin_request_policy" "origin" {
  name = "Managed-AllViewerAndCloudFrontHeaders-2022-06"
}

data "aws_cloudfront_cache_policy" "cache" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

resource "random_password" "cloudfront_origin_header" {
  length  = 16
  special = false
  upper   = false
  numeric = false

  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
      numeric,
    ]
  }
}
