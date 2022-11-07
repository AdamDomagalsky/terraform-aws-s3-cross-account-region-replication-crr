# Name
variable "Name" {
  type        = string
  description = "Short name to describe this replication."
}

# Source
variable "SourceAccount" {
  type        = string
  description = "AWS Account containing the source bucket."
}

variable "SourceRegion" {
  type        = string
  description = "AWS region containing the source bucket."
}

variable "SourceBucketName" {
  type        = string
  description = "Name of source S3 bucket."
}

variable "SourceKeyID" {
  type        = string
  default     = null
  description = "ID of the KMS Key used for Encryption of the source bucket, leave empty/null if source bucket is not encrypted."
}

# Target
variable "TargetAccount" {
  type        = string
  description = "AWS Account for the target bucket."
}

variable "TargetRegion" {
  type        = string
  description = "AWS region for the target bucket."
}

variable "TargetBucketName" {
  type        = string
  description = "Name for target S3 bucket."
}

# Replication Settings
variable "ReplicationStorageClass" {
  type        = string
  default     = "STANDARD"
  description = "Storage Class for replicated Data, Possible values: STANDARD | REDUCED_REDUNDANCY | STANDARD_IA | ONEZONE_IA | INTELLIGENT_TIERING | GLACIER | DEEP_ARCHIVE | OUTPOSTS | GLACIER_IR"
}
