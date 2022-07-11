variable "prefix" {
  nullable = false
  type = string
}

resource "aws_s3_bucket" "s3-site" {
  bucket_prefix = var.prefix
}

resource "aws_s3_bucket_acl" "s3-site-acl" {
  bucket = aws_s3_bucket.s3-site.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "s3-site-config" {
  bucket = aws_s3_bucket.s3-site.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "s3-bucket-policy" {
  bucket = aws_s3_bucket.s3-site.id
  policy = data.aws_iam_policy_document.allow_access.json
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.s3-site.arn,
      "${aws_s3_bucket.s3-site.arn}/*",
    ]
  }
}
