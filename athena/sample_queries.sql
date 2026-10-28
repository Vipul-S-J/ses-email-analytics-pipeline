-- Example analytics queries against the ses_events table.

-- 1. Count of each event type
SELECT eventType, COUNT(*) AS event_count
FROM ses_events
GROUP BY eventType
ORDER BY event_count DESC;

-- 2. Delivery rate = deliveries / sends
SELECT
  SUM(CASE WHEN eventType = 'Delivery' THEN 1 ELSE 0 END) AS deliveries,
  SUM(CASE WHEN eventType = 'Send'     THEN 1 ELSE 0 END) AS sends,
  ROUND(
    100.0 * SUM(CASE WHEN eventType = 'Delivery' THEN 1 ELSE 0 END)
          / NULLIF(SUM(CASE WHEN eventType = 'Send' THEN 1 ELSE 0 END), 0),
    2
  ) AS delivery_rate_pct
FROM ses_events;

-- 3. Bounces broken down by type
SELECT bounce.bounceType AS bounce_type,
       bounce.bounceSubType AS bounce_sub_type,
       COUNT(*) AS count
FROM ses_events
WHERE eventType = 'Bounce'
GROUP BY bounce.bounceType, bounce.bounceSubType
ORDER BY count DESC;

-- 4. Engagement: opens and clicks per day
SELECT date(from_iso8601_timestamp(mail.timestamp)) AS day,
       SUM(CASE WHEN eventType = 'Open'  THEN 1 ELSE 0 END) AS opens,
       SUM(CASE WHEN eventType = 'Click' THEN 1 ELSE 0 END) AS clicks
FROM ses_events
WHERE eventType IN ('Open', 'Click')
GROUP BY date(from_iso8601_timestamp(mail.timestamp))
ORDER BY day;

-- 5. Top recipients by complaint count
SELECT recipient, COUNT(*) AS complaints
FROM ses_events
CROSS JOIN UNNEST(mail.destination) AS t(recipient)
WHERE eventType = 'Complaint'
GROUP BY recipient
ORDER BY complaints DESC
LIMIT 20;
