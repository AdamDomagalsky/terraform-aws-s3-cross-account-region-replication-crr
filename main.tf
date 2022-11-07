terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  SourceRootUserARN = "arn:aws:iam::${data.aws_caller_identity.Source.account_id}:root"
  TargetRootUserARN = "arn:aws:iam::${data.aws_caller_identity.Target.account_id}:root"
}

provider "aws" {
  alias   = "Source"
  profile = var.SourceAccount
  region  = var.SourceRegion
}

provider "aws" {
  alias   = "Target"
  profile = var.TargetAccount
  region  = var.TargetRegion
}

data "aws_caller_identity" "Source" {
  provider = aws.Source
}

data "aws_caller_identity" "Target" {
  provider = aws.Target
}

data "aws_iam_role" "SourceAdminRole" {
  provider = aws.Source
  name     = split("/", data.aws_caller_identity.Source.arn)[1]
}

data "aws_iam_role" "TargetAdminRole" {
  provider = aws.Target
  name     = split("/", data.aws_caller_identity.Target.arn)[1]
}

output "SourceIAM" {
  value = data.aws_iam_role.SourceAdminRole.arn
}

output "TargetIAM" {
  value = data.aws_iam_role.TargetAdminRole.arn
}
