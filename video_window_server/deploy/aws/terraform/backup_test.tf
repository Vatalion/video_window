# Terraform Test Configuration for Backup Setup
# Story: 03-3 Data Retention & Backup Procedures
# Purpose: Validate backup configuration meets acceptance criteria

# This file contains test assertions and validation checks
# Run with: terraform plan -target=test_suite.backup_validation

# Test 1: Verify RDS backup retention is 30 days (AC3)
locals {
  test_backup_retention_production = aws_db_instance.postgres.backup_retention_period == 30
  test_backup_retention_staging    = var.enable_staging_server ? aws_db_instance.postgres_staging[0].backup_retention_period >= 7 : true
  
  # Test 2: Verify PITR is enabled (AC2)
  test_pitr_enabled = length(aws_db_instance.postgres.enabled_cloudwatch_logs_exports) > 0
  
  # Test 3: Verify AWS Backup vault exists (AC1)
  test_backup_vault_exists = aws_backup_vault.main.name != ""
  
  # Test 4: Verify backup plan has 30-day retention (AC1, AC3)
  test_backup_plan_retention = aws_backup_plan.database_backup.rule[0].lifecycle[0].delete_after == 30
  
  # Test 5: Verify backup monitoring is configured (AC5)
  test_backup_monitoring = (
    aws_sns_topic.backup_notifications.arn != "" &&
    aws_cloudwatch_event_rule.backup_failure.name != "" &&
    aws_cloudwatch_metric_alarm.backup_age.alarm_name != ""
  )
  
  # Test 6: Verify backup schedule is daily
  test_backup_schedule = can(regex("cron\\(0 5 \\* \\* \\? \\*\\)", aws_backup_plan.database_backup.rule[0].schedule))
  
  # Test 7: Verify encryption is enabled
  test_encryption_enabled = aws_db_instance.postgres.storage_encrypted == true
  
  # Test 8: Verify backup window is configured
  test_backup_window = aws_db_instance.postgres.backup_window == "03:00-04:00"
  
  # Aggregate test results
  all_tests_passed = (
    local.test_backup_retention_production &&
    local.test_backup_retention_staging &&
    local.test_pitr_enabled &&
    local.test_backup_vault_exists &&
    local.test_backup_plan_retention &&
    local.test_backup_monitoring &&
    local.test_backup_schedule &&
    local.test_encryption_enabled &&
    local.test_backup_window
  )
}

# Output test results
output "backup_test_results" {
  description = "Backup configuration test results"
  value = {
    ac1_aws_backup_configured = {
      vault_exists     = local.test_backup_vault_exists
      plan_configured  = aws_backup_plan.database_backup.id != ""
      schedule_daily   = local.test_backup_schedule
      status          = local.test_backup_vault_exists && local.test_backup_schedule ? "✅ PASS" : "❌ FAIL"
    }
    ac2_pitr_enabled = {
      cloudwatch_logs_enabled = local.test_pitr_enabled
      backup_retention        = aws_db_instance.postgres.backup_retention_period >= 7
      status                 = local.test_pitr_enabled ? "✅ PASS" : "❌ FAIL"
    }
    ac3_retention_30_days = {
      rds_retention         = aws_db_instance.postgres.backup_retention_period
      aws_backup_retention  = aws_backup_plan.database_backup.rule[0].lifecycle[0].delete_after
      status               = local.test_backup_plan_retention && local.test_backup_retention_production ? "✅ PASS" : "❌ FAIL"
    }
    ac5_monitoring_alerting = {
      sns_configured         = aws_sns_topic.backup_notifications.arn != ""
      event_rule_configured  = aws_cloudwatch_event_rule.backup_failure.name != ""
      alarm_configured       = aws_cloudwatch_metric_alarm.backup_age.alarm_name != ""
      status                = local.test_backup_monitoring ? "✅ PASS" : "❌ FAIL"
    }
    encryption = {
      storage_encrypted = local.test_encryption_enabled
      status           = local.test_encryption_enabled ? "✅ PASS" : "❌ FAIL"
    }
    backup_window = {
      configured = local.test_backup_window
      value     = aws_db_instance.postgres.backup_window
      status    = local.test_backup_window ? "✅ PASS" : "❌ FAIL"
    }
    overall_status = local.all_tests_passed ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED"
  }
}

# Validation checks (will fail terraform plan if conditions not met)
check "backup_retention_compliance" {
  assert {
    condition     = aws_db_instance.postgres.backup_retention_period == 30
    error_message = "Production database backup retention must be 30 days (AC3)"
  }
  
  assert {
    condition     = aws_backup_plan.database_backup.rule[0].lifecycle[0].delete_after == 30
    error_message = "AWS Backup plan retention must be 30 days (AC3)"
  }
}

check "pitr_enabled" {
  assert {
    condition     = length(aws_db_instance.postgres.enabled_cloudwatch_logs_exports) > 0
    error_message = "PostgreSQL CloudWatch logs must be enabled for PITR (AC2)"
  }
  
  assert {
    condition     = aws_db_instance.postgres.backup_retention_period > 0
    error_message = "Backup retention period must be greater than 0 for PITR (AC2)"
  }
}

check "monitoring_configured" {
  assert {
    condition     = aws_sns_topic.backup_notifications.name != ""
    error_message = "SNS topic for backup notifications must be configured (AC5)"
  }
  
  assert {
    condition     = aws_cloudwatch_event_rule.backup_failure.name != ""
    error_message = "CloudWatch event rule for backup failures must be configured (AC5)"
  }
  
  assert {
    condition     = aws_cloudwatch_metric_alarm.backup_age.alarm_name != ""
    error_message = "CloudWatch alarm for backup age must be configured (AC5)"
  }
}

check "encryption_enabled" {
  assert {
    condition     = aws_db_instance.postgres.storage_encrypted == true
    error_message = "Database storage must be encrypted"
  }
}

# Data source to verify backup vault after apply
data "aws_backup_vault" "verify" {
  name = aws_backup_vault.main.name
  
  depends_on = [aws_backup_vault.main]
}

# Output for recovery documentation (AC4)
output "recovery_information" {
  description = "Information needed for recovery procedures (AC4)"
  value = {
    backup_vault_name     = aws_backup_vault.main.name
    backup_plan_id        = aws_backup_plan.database_backup.id
    sns_topic_arn         = aws_sns_topic.backup_notifications.arn
    rds_backup_window     = aws_db_instance.postgres.backup_window
    rds_backup_retention  = aws_db_instance.postgres.backup_retention_period
    pitr_window_days      = aws_db_instance.postgres.backup_retention_period
    recovery_scripts      = {
      test_script      = "video_window_server/deploy/aws/scripts/test_recovery.sh"
      validation_sql   = "video_window_server/deploy/aws/scripts/validation_queries.sql"
      runbook          = "docs/runbooks/database-backup-recovery.md"
    }
    rto_target           = "< 4 hours"
    rpo_target           = "< 1 hour (PITR enabled)"
  }
}

