variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket that stores SES event data"
  type        = string
}

variable "stream_name" {
  description = "Name of the Kinesis Data Firehose delivery stream"
  type        = string
  default     = "aws-ses-analytics-firehose"
}

variable "config_set_name" {
  description = "Name of the SES configuration set"
  type        = string
  default     = "ses-dashboard"
}

variable "s3_prefix" {
  description = "Prefix under which Firehose writes objects in the bucket"
  type        = string
  default     = "raw/"
}
