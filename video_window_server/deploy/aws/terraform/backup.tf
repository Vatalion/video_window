# AWS Backup Configuration
# Story: 03-3 Data Retention & Backup Procedures
# AC1: AWS Backup configured
# AC3: Backup retention policy (30 days)
# AC5: Backup monitoring and alerting

# Backup Vault
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault"
  
  tags = {
    Name        = "${var.project_name}-backup-vault"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Backup Plan
resource "aws_backup_plan" "database_backup" {
  name = "${var.project_name}-database-backup-plan"

  rule {
    rule_name         = "daily-backup-30day-retention"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"  # Daily at 5 AM UTC
    start_window      = 60                    # Start within 60 minutes
    completion_window = 120                   # Complete within 120 minutes

    lifecycle {
      delete_after = 30  # 30-day retention per AC3
    }

    recovery_point_tags = {
      Environment = "production"
      Automated   = "true"
      BackupType  = "daily"
    }
  }

  tags = {
    Name        = "${var.project_name}-backup-plan"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-backup-role"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Attach AWS Backup service policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup_role.name
}

# Backup Selection - Production Database
resource "aws_backup_selection" "database_backup_selection" {
  name         = "${var.project_name}-database-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.database_backup.id

  resources = [
    aws_db_instance.postgres.arn
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupEnabled"
    value = "true"
  }
}

# Backup Selection - Staging Database (if enabled)
resource "aws_backup_selection" "database_backup_selection_staging" {
  count = var.enable_staging_server ? 1 : 0

  name         = "${var.project_name}-staging-database-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.database_backup.id

  resources = [
    aws_db_instance.postgres_staging[0].arn
  ]
}

# SNS Topic for Backup Notifications (AC5)
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.project_name}-backup-notifications"

  tags = {
    Name        = "${var.project_name}-backup-notifications"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "backup_notifications" {
  arn = aws_sns_topic.backup_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.backup_notifications.arn
      }
    ]
  })
}

# EventBridge Rule for Backup Job Failures
resource "aws_cloudwatch_event_rule" "backup_failure" {
  name        = "${var.project_name}-backup-failure"
  description = "Trigger alert on backup job failure"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["FAILED", "EXPIRED"]
    }
  })

  tags = {
    Name        = "${var.project_name}-backup-failure-rule"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target - Send to SNS
resource "aws_cloudwatch_event_target" "backup_failure_sns" {
  rule      = aws_cloudwatch_event_rule.backup_failure.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.backup_notifications.arn
}

# CloudWatch Alarm for Backup Age (AC5)
resource "aws_cloudwatch_metric_alarm" "backup_age" {
  alarm_name          = "${var.project_name}-backup-age-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TimeSinceLastBackup"
  namespace           = "Custom/Backup"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "25"     # Alert if no backup in 25 hours
  alarm_description   = "Alert when backup is older than 25 hours"
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.backup_notifications.arn]

  tags = {
    Name        = "${var.project_name}-backup-age-alarm"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "backup_vault_name" {
  description = "Name of the AWS Backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.database_backup.id
}

output "backup_sns_topic_arn" {
  description = "ARN of the SNS topic for backup notifications"
  value       = aws_sns_topic.backup_notifications.arn
}

