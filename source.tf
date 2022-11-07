data "aws_iam_policy_document" "SourceAssumeRole" {
  provider = aws.Source
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "SourceReplication" {
  provider = aws.Source
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [
      "${data.aws_s3_bucket.Source.arn}",
      "${aws_s3_bucket.Target.arn}",
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
    ]

    resources = [
      "${data.aws_s3_bucket.Source.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = [
      "${aws_s3_bucket.Target.arn}/*"
    ]
  }

  dynamic "statement" {
    for_each = var.SourceKeyID != null ? [var.SourceKeyID] : []
    content {
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = [
        "arn:aws:kms:${var.SourceRegion}:${data.aws_caller_identity.Source.account_id}:key/${var.SourceKeyID}"
      ]
    }
  }
}

resource "aws_iam_policy" "SourceReplication" {
  provider = aws.Source
  name     = "${var.Name}-replication-policy"
  policy   = data.aws_iam_policy_document.SourceReplication.json
}

resource "aws_iam_role" "SourceReplication" {
  provider           = aws.Source
  name               = "${var.Name}-replication"
  assume_role_policy = data.aws_iam_policy_document.SourceAssumeRole.json
}

resource "aws_iam_role_policy_attachment" "SourceReplication" {
  provider   = aws.Source
  role       = aws_iam_role.SourceReplication.name
  policy_arn = aws_iam_policy.SourceReplication.arn
}

data "aws_s3_bucket" "Source" {
  provider = aws.Source
  bucket   = var.SourceBucketName
}

resource "aws_s3_bucket_replication_configuration" "Replication" {
  provider = aws.Source
  bucket   = data.aws_s3_bucket.Source.id
  role     = aws_iam_role.SourceReplication.arn

  rule {
    id     = var.Name
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.Target.arn
      storage_class = var.ReplicationStorageClass
      account       = data.aws_caller_identity.Target.account_id
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.Target.arn
      }
    }
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}
