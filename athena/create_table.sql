-- Athena external table over the raw SES event JSON stored in S3 by Firehose.
-- Replace the S3 LOCATION with your own bucket/prefix before running.
--
-- SES publishes newline-delimited JSON. Each record has an "eventType" plus a
-- "mail" object and an event-specific object (delivery, bounce, complaint, ...).

CREATE EXTERNAL TABLE IF NOT EXISTS ses_events (
  eventType string,
  mail struct<
    timestamp: string,
    messageId: string,
    source: string,
    sendingAccountId: string,
    destination: array<string>,
    tags: map<string, array<string>>
  >,
  delivery struct<
    timestamp: string,
    processingTimeMillis: int,
    recipients: array<string>,
    smtpResponse: string
  >,
  bounce struct<
    bounceType: string,
    bounceSubType: string,
    timestamp: string
  >,
  complaint struct<
    timestamp: string,
    complaintFeedbackType: string
  >,
  open struct<
    timestamp: string,
    ipAddress: string,
    userAgent: string
  >,
  click struct<
    timestamp: string,
    ipAddress: string,
    userAgent: string,
    link: string
  >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://my-ses-analytics-bucket/raw/'
TBLPROPERTIES ('ignore.malformed.json' = 'true');
