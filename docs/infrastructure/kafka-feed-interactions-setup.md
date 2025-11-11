# Kafka Feed Interactions Infrastructure Setup

**Story:** 4-5 Content Recommendation Engine Integration  
**Task:** 4 - Provision Kafka topic and IAM role  
**Status:** Infrastructure Documentation

## Kafka Topic Provisioning

### Topic Configuration
- **Topic Name:** `feed.interactions.v1`
- **Partitions:** 6 (for scalability)
- **Replication Factor:** 3 (production)
- **Retention:** 7 days
- **Compression:** snappy

### Schema
```json
{
  "userId": "string",
  "videoId": "string",
  "interactionType": "string",
  "watchTime": "integer",
  "timestamp": "string (ISO8601)"
}
```

### AWS MSK Configuration
```bash
# Create topic via AWS CLI
aws kafka create-topic \
  --cluster-arn arn:aws:kafka:us-east-1:ACCOUNT:cluster/video-window-msk/CLUSTER_ID \
  --topic-name feed.interactions.v1 \
  --partitions 6 \
  --replication-factor 3 \
  --config-configurations RetentionMs=604800000,CompressionType=snappy
```

## IAM Role Configuration

### Role: feed-rec-producer
**Purpose:** Allows Serverpod to produce messages to Kafka topic

### IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kafka:WriteData",
        "kafka:DescribeTopic"
      ],
      "Resource": "arn:aws:kafka:us-east-1:ACCOUNT:topic/video-window-msk/CLUSTER_ID/feed.interactions.v1"
    }
  ]
}
```

### Terraform Configuration
```hcl
resource "aws_iam_role" "feed_rec_producer" {
  name = "feed-rec-producer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "feed_rec_producer_kafka" {
  name = "feed-rec-producer-kafka"
  role = aws_iam_role.feed_rec_producer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kafka:WriteData",
        "kafka:DescribeTopic"
      ]
      Resource = "arn:aws:kafka:us-east-1:${var.account_id}:topic/${var.msk_cluster_arn}/feed.interactions.v1"
    }]
  })
}
```

## Implementation Notes

1. **serverpod_kafka plugin:** Add to `video_window_server/pubspec.yaml`:
   ```yaml
   dependencies:
     serverpod_kafka: 1.3.0
   ```

2. **Configuration:** Add Kafka broker endpoints to Serverpod config
3. **Testing:** Use local Kafka for development, MSK for production

