# Setup Guide — Amazon SES Analytics Pipeline (AWS Console)

This walkthrough configures SES to publish email events to Kinesis Data
Firehose, which stores them in S3 for analysis with Athena.

> All names, account IDs, and ARNs below are placeholders. Replace them with
> your own values.

## 1. Create the Kinesis Data Firehose delivery stream

1. In the AWS Console, open **Amazon Kinesis** → **Data Firehose**.
2. Choose **Create delivery stream**.
3. Give the delivery stream a name, e.g. `aws-ses-analytics-firehose`.
4. For the source, select **Direct PUT or other sources**, then continue.
5. Leave the transformation/configuration options at their defaults.
6. For the destination, choose **Amazon S3**.
7. Select (or create) the target bucket, e.g. `my-ses-analytics-bucket`.
8. Optionally set an S3 prefix (e.g. `raw/`) to organize the objects.
9. Choose or create an IAM role that allows Firehose to write to S3.
10. Review the settings and choose **Create delivery stream**.
11. (Optional) Test with the built-in demo data, then confirm objects land in S3.

## 2. Create an SES configuration set

1. Open **Amazon Simple Email Service** → **Configuration sets**.
2. Choose **Create set**.
3. Name it, e.g. `ses-dashboard`. Leave other options at defaults.
4. After it is created, open the set and go to **Event destinations**.
5. Choose **Add destination**.
6. Select the event types to analyze (Sends, Deliveries, Hard bounces,
   Complaints, Opens, Clicks, etc.), then continue.
7. Choose **Amazon Kinesis Data Firehose** as the destination type.
8. Select the delivery stream and IAM role created in step 1.
9. Continue through the review page and choose **Add destination**.

## 3. Assign the configuration set to a verified identity

1. In SES, open **Verified identities**.
2. Choose the verified domain or email address you send from.
3. Open the **Configuration set** tab and choose **Edit**.
4. Enable **Assign a default configuration set** and select `ses-dashboard`.
5. Save changes.

## 4. Verify data is flowing

Send an email from the verified identity. Within ~5 minutes (Firehose buffers
every 5 minutes or 5 MiB), newline-delimited JSON event records appear in S3,
partitioned by date, e.g.:

```
s3://my-ses-analytics-bucket/raw/2026/10/27/...
```

## 5. Query with Athena

Run [`../athena/create_table.sql`](../athena/create_table.sql) once, then use
[`../athena/sample_queries.sql`](../athena/sample_queries.sql) to analyze the data.

## Reference

[Analyzing Amazon SES event data with AWS Analytics Services](https://aws.amazon.com/blogs/messaging-and-targeting/analyzing-amazon-ses-event-data-with-aws-analytics-services/)
