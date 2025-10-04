locals {
  enabled = var.enable_trail
}

# Discover your Org so the bucket policy can allow AWSLogs/<ORG_ID>/*
data "aws_organizations_organization" "this" {
  count = local.enabled ? 1 : 0
}

# Unique bucket suffix
resource "random_id" "suffix" {
  count       = local.enabled ? 1 : 0
  byte_length = 4
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = "org-trail-${random_id.suffix[0].hex}"
}

# S3 hardening
resource "aws_s3_bucket_public_access_block" "logs" {
  count                   = local.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Modern ownership: disable ACLs (so we don't need x-amz-acl conditions)
resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# simple lifecycle to keep costs low during Phase-0
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-noncurrent-after-30d"
    status = "Enabled"
    noncurrent_version_expiration { noncurrent_days = 30 }
  }
}


# Bucket policy for ORG CloudTrail (account + org paths, with prefix)
data "aws_iam_policy_document" "logs" {
  count = local.enabled ? 1 : 0

  # Allow CloudTrail to check bucket ACL/location
  statement {
    sid     = "CloudTrailBucketPermissionsCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.logs[0].id}"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  # Allow writes for account-level path (mgmt account ID) with your prefix
  statement {
    sid     = "CloudTrailWriteAccount"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.logs[0].id}/cloudtrail/AWSLogs/${data.aws_organizations_organization.this[0].master_account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    # CloudTrail's validation expects this header condition
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Allow writes for organization-level path with your prefix (o-<org-id>)
  statement {
    sid     = "CloudTrailWriteOrganization"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.logs[0].id}/cloudtrail/AWSLogs/${data.aws_organizations_organization.this[0].id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count  = local.enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.logs,
    aws_s3_bucket_ownership_controls.logs
  ]
}


# Org-wide, multi-region CloudTrail (mgmt events only)
resource "aws_cloudtrail" "org" {
  count                         = local.enabled ? 1 : 0
  name                          = "org-trail"
  is_multi_region_trail         = true
  include_global_service_events = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  s3_bucket_name = aws_s3_bucket.logs[0].id
  s3_key_prefix  = "cloudtrail"

  event_selector {
    include_management_events = true
    read_write_type           = "All"
  }

  # Ensure S3 exists & policy is in place before enabling the trail
  depends_on = [
    aws_s3_bucket.logs,
    aws_s3_bucket_policy.logs
  ]
}

output "trail_arn"   { value = local.enabled ? aws_cloudtrail.org[0].arn         : null }
output "logs_bucket" { value = local.enabled ? aws_s3_bucket.logs[0].bucket      : null }
