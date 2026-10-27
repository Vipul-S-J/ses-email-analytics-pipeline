output "s3_bucket" {
  description = "S3 bucket storing SES event data"
  value       = aws_s3_bucket.events.bucket
}

output "firehose_stream" {
  description = "Kinesis Data Firehose delivery stream name"
  value       = aws_kinesis_firehose_delivery_stream.ses.name
}

output "configuration_set" {
  description = "SES configuration set name to assign to a verified identity"
  value       = aws_sesv2_configuration_set.this.configuration_set_name
}
