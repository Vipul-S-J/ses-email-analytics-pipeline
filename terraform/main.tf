terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# S3 bucket for SES event data
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "events" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "events" {
  bucket                  = aws_s3_bucket.events.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# IAM role allowing Firehose to write to the S3 bucket
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "${var.stream_name}-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
}

data "aws_iam_policy_document" "firehose_s3" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.events.arn,
      "${aws_s3_bucket.events.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "firehose_s3" {
  name   = "${var.stream_name}-s3-policy"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.firehose_s3.json
}

# ---------------------------------------------------------------------------
# Kinesis Data Firehose delivery stream -> S3
# ---------------------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "ses" {
  name        = var.stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = aws_s3_bucket.events.arn
    prefix             = var.s3_prefix
    buffering_interval = 300 # 5 minutes
    buffering_size     = 5   # 5 MiB
    compression_format = "UNCOMPRESSED"
  }
}

# ---------------------------------------------------------------------------
# SES configuration set + Firehose event destination
# ---------------------------------------------------------------------------
resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = var.config_set_name
}

data "aws_iam_policy_document" "ses_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ses_to_firehose" {
  name               = "${var.config_set_name}-ses-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.ses_assume.json
}

data "aws_iam_policy_document" "ses_firehose" {
  statement {
    actions   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
    resources = [aws_kinesis_firehose_delivery_stream.ses.arn]
  }
}

resource "aws_iam_role_policy" "ses_firehose" {
  name   = "${var.config_set_name}-ses-firehose-policy"
  role   = aws_iam_role.ses_to_firehose.id
  policy = data.aws_iam_policy_document.ses_firehose.json
}

resource "aws_sesv2_configuration_set_event_destination" "firehose" {
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = "firehose-destination"

  event_destination {
    enabled = true
    matching_event_types = [
      "SEND",
      "DELIVERY",
      "REJECT",
      "BOUNCE",
      "COMPLAINT",
      "OPEN",
      "CLICK",
      "RENDERING_FAILURE",
    ]

    kinesis_firehose_destination {
      delivery_stream_arn = aws_kinesis_firehose_delivery_stream.ses.arn
      iam_role_arn        = aws_iam_role.ses_to_firehose.arn
    }
  }
}
