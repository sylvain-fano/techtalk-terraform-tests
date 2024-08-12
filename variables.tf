variable "bucket_name" {
  description = "Name of the s3 bucket. Must be unique."
  default     = "tt-tf-test-aws-s3-website"
  type        = string

  validation {
    condition     = length(var.bucket_name) <= 30
    error_message = "Variable length should be 30 characters or less"
  }
}

variable "region" {
  description = "The AWS region to deploy to"
  default     = "eu-central-1"
  type        = string

  validation {
    condition     = can(regex("^eu-", var.region))
    error_message = "Should be one of the European region"
  }
}
