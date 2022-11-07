data "aws_iam_policy_document" "TargetKey" {
  provider = aws.Target

  statement {
    sid    = "Allow everything for Root and Admin"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        local.TargetRootUserARN,
        data.aws_iam_role.TargetAdminRole.arn
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow encryption by source account root"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        local.SourceRootUserARN,
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "Target" {
  provider    = aws.Target
  description = "KMS Key to encrypt S3 Bucket for ${var.Name}"
  policy      = data.aws_iam_policy_document.TargetKey.json
}

resource "aws_kms_alias" "Target" {
  provider      = aws.Target
  name          = "alias/${var.Name}"
  target_key_id = aws_kms_key.Target.id
}

resource "aws_s3_bucket" "Target" {
  provider = aws.Target
  bucket   = var.TargetBucketName
}

data "aws_iam_policy_document" "TargetBucketPolicy" {
  provider = aws.Target
  statement {
    sid    = "ReplicateObjectsFrom-${var.Name}"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        local.SourceRootUserARN
      ]
    }

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = [
      "${aws_s3_bucket.Target.arn}",
      "${aws_s3_bucket.Target.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "Target" {
  provider = aws.Target
  bucket   = var.TargetBucketName
  policy   = data.aws_iam_policy_document.TargetBucketPolicy.json
}

resource "aws_s3_bucket_acl" "Target" {
  provider = aws.Target
  bucket   = aws_s3_bucket.Target.id
  acl      = "private"
}

resource "aws_s3_bucket_versioning" "Target" {
  provider = aws.Target
  bucket   = aws_s3_bucket.Target.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "Target" {
  provider = aws.Target
  bucket   = aws_s3_bucket.Target.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.Target.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
