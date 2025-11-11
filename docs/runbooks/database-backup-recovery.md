# Database Backup & Recovery Procedures

**Version:** 1.0.0  
**Last Updated:** 2025-11-11  
**Owner:** DevOps/Operations Team  
**Status:** Active  
**Story:** 03-3 Data Retention & Backup Procedures

## Overview

This runbook documents the backup and recovery procedures for the Video Window PostgreSQL database, including Point-in-Time Recovery (PITR) and AWS Backup restore procedures.

## RTO/RPO Requirements

- **RTO (Recovery Time Objective):** < 4 hours
- **RPO (Recovery Point Objective):** < 1 hour (via PITR)
- **Backup Frequency:** Daily automated snapshots
- **Backup Retention:** 30 days
- **PITR Window:** 7 days (continuous backup)

## Backup Architecture

### Automated Backups

1. **RDS Automated Backups:**
   - Frequency: Daily during backup window (03:00-04:00 UTC)
   - Retention: 30 days
   - Storage: Encrypted snapshots in AWS
   - Point-in-Time Recovery: Enabled (7-day window)

2. **AWS Backup Service:**
   - Frequency: Daily at 05:00 UTC
   - Retention: 30 days
   - Vault: `video-window-backup-vault`
   - Backup Plan: `video-window-database-backup-plan`

### What's Backed Up

- PostgreSQL database (production): `video-window`
- PostgreSQL database (staging): `video-window-staging`
- All database tables, indexes, and data
- Database configuration and parameters
- User accounts and permissions

### What's NOT Backed Up

- Temporary tables
- Cache data
- Session data (stored in Redis - separate backup)
- Application logs (stored in CloudWatch)

## Backup Verification

### Daily Verification (Automated)

Automated checks run daily:
- ✅ Backup job completion status
- ✅ Backup age < 25 hours (CloudWatch alarm)
- ✅ Backup size consistency check
- ✅ Snapshot encryption verification

### Weekly Verification (Manual)

Operations team should verify weekly:
- [ ] Latest backup exists in RDS snapshots
- [ ] AWS Backup vault contains recent backups
- [ ] No CloudWatch alarms triggered
- [ ] Backup logs show no errors

### Monthly Verification (Recovery Test)

**Required:** Full recovery test monthly to validate <4 hour RTO

See "Recovery Testing" section below.

## Recovery Scenarios

### Scenario 1: Point-in-Time Recovery (PITR)

**Use Case:** Recover from data corruption, accidental deletion, or bad deployment within the last 7 days.

**Steps:**

1. **Identify Recovery Target Time**
   ```bash
   # Determine the timestamp to recover to (before the incident)
   RECOVERY_TIME="2025-11-11T10:30:00Z"
   ```

2. **Create Recovery Instance**
   ```bash
   # Using AWS CLI
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier video-window \
     --target-db-instance-identifier video-window-recovery-$(date +%Y%m%d%H%M) \
     --restore-time "$RECOVERY_TIME" \
     --db-subnet-group-name <subnet-group-name> \
     --vpc-security-group-ids <security-group-id>
   
   # Wait for instance to be available (10-20 minutes)
   aws rds wait db-instance-available \
     --db-instance-identifier video-window-recovery-$(date +%Y%m%d%H%M)
   ```

3. **Verify Recovered Data**
   ```bash
   # Connect to recovery instance
   psql -h <recovery-instance-endpoint> -U postgres -d serverpod
   
   # Verify critical tables
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM transactions;
   SELECT MAX(created_at) FROM audit_log;
   
   # Verify data integrity
   # Run application-specific validation queries
   ```

4. **Update DNS or Swap Endpoints**
   ```bash
   # Option A: Update Route53 to point to recovery instance
   # Option B: Rename instances (requires downtime)
   
   # Minimal downtime approach:
   # 1. Set maintenance mode
   # 2. Stop application connections
   # 3. Rename instances
   # 4. Update Route53
   # 5. Resume application
   ```

5. **Cleanup**
   ```bash
   # After successful verification, delete old instance
   aws rds delete-db-instance \
     --db-instance-identifier video-window-old \
     --skip-final-snapshot
   ```

**Estimated Time:** 1-2 hours

### Scenario 2: Snapshot Restore

**Use Case:** Recover from daily snapshot (up to 30 days old).

**Steps:**

1. **List Available Snapshots**
   ```bash
   # List RDS automated snapshots
   aws rds describe-db-snapshots \
     --db-instance-identifier video-window \
     --snapshot-type automated
   
   # List manual snapshots
   aws rds describe-db-snapshots \
     --db-instance-identifier video-window \
     --snapshot-type manual
   ```

2. **Restore from Snapshot**
   ```bash
   # Choose snapshot ID
   SNAPSHOT_ID="rds:video-window-2025-11-11-03-00"
   
   # Restore
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier video-window-restored \
     --db-snapshot-identifier $SNAPSHOT_ID \
     --db-instance-class db.t3.micro \
     --db-subnet-group-name <subnet-group-name> \
     --vpc-security-group-ids <security-group-id>
   
   # Wait for completion
   aws rds wait db-instance-available \
     --db-instance-identifier video-window-restored
   ```

3. **Verify and Swap (Same as PITR Scenario, steps 3-5)**

**Estimated Time:** 1.5-3 hours

### Scenario 3: AWS Backup Restore

**Use Case:** Restore from AWS Backup vault (alternative to RDS snapshots).

**Steps:**

1. **List Recovery Points**
   ```bash
   # Find recovery points in backup vault
   aws backup list-recovery-points-by-backup-vault \
     --backup-vault-name video-window-backup-vault
   ```

2. **Initiate Restore Job**
   ```bash
   # Get recovery point ARN
   RECOVERY_POINT_ARN="arn:aws:backup:..."
   
   # Create restore job
   aws backup start-restore-job \
     --recovery-point-arn $RECOVERY_POINT_ARN \
     --iam-role-arn arn:aws:iam::ACCOUNT_ID:role/video-window-backup-role \
     --metadata '{
       "DBInstanceIdentifier": "video-window-restored",
       "DBInstanceClass": "db.t3.micro",
       "Engine": "postgres",
       "MultiAZ": "false"
     }'
   ```

3. **Monitor Restore Job**
   ```bash
   aws backup describe-restore-job \
     --restore-job-id <job-id>
   ```

4. **Verify and Swap (Same as PITR Scenario, steps 3-5)**

**Estimated Time:** 2-4 hours

### Scenario 4: Cross-Region Disaster Recovery

**Use Case:** Complete AWS region failure.

**Prerequisites:**
- Cross-region snapshot copy configured (future enhancement)
- Read replica in secondary region (future enhancement)

**Steps:** (To be documented when cross-region DR is implemented)

## Recovery Testing

### Monthly Recovery Test Procedure

**Purpose:** Validate <4 hour RTO requirement (AC4)

**Schedule:** First Monday of each month, during maintenance window

**Test Steps:**

1. **Preparation (5 minutes)**
   ```bash
   # Start timer
   START_TIME=$(date +%s)
   
   # Log test initiation
   echo "Recovery test started: $(date)" >> recovery-test-log.txt
   
   # Select recovery method (rotate monthly)
   # Month 1: PITR
   # Month 2: Snapshot restore
   # Month 3: AWS Backup restore
   ```

2. **Execute Recovery (60-90 minutes)**
   ```bash
   # Follow appropriate recovery scenario above
   # Use staging database for testing (not production)
   
   # Example: PITR test
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier video-window-staging \
     --target-db-instance-identifier video-window-test-$(date +%Y%m%d) \
     --restore-time "$(date -u -d '1 hour ago' +'%Y-%m-%dT%H:%M:%SZ')" \
     --db-subnet-group-name <subnet-group> \
     --vpc-security-group-ids <security-group>
   ```

3. **Data Integrity Validation (30 minutes)**
   ```bash
   # Connect to test instance
   psql -h <test-instance-endpoint> -U postgres -d serverpod
   
   # Run validation queries
   \i validation_queries.sql
   
   # Verify:
   # - Row counts match expected ranges
   # - Latest data timestamp is within expected window
   # - Foreign key constraints intact
   # - Indexes present and valid
   # - No data corruption
   ```

4. **Application Connection Test (15 minutes)**
   ```bash
   # Update test environment to use recovered database
   # Run smoke tests
   # Verify:
   # - Application can connect
   # - Read operations work
   # - Write operations work
   # - Authentication works
   # - Critical workflows function
   ```

5. **Calculate RTO (5 minutes)**
   ```bash
   # End timer
   END_TIME=$(date +%s)
   RTO_SECONDS=$((END_TIME - START_TIME))
   RTO_HOURS=$(awk "BEGIN {print $RTO_SECONDS/3600}")
   
   # Log results
   echo "Recovery completed: $(date)" >> recovery-test-log.txt
   echo "RTO achieved: $RTO_HOURS hours" >> recovery-test-log.txt
   
   # Verify RTO < 4 hours
   if (( $(awk "BEGIN {print ($RTO_HOURS < 4)}") )); then
     echo "✅ RTO requirement met: $RTO_HOURS < 4 hours"
   else
     echo "❌ RTO requirement FAILED: $RTO_HOURS >= 4 hours"
     # Escalate to team lead
   fi
   ```

6. **Cleanup (10 minutes)**
   ```bash
   # Delete test instance
   aws rds delete-db-instance \
     --db-instance-identifier video-window-test-$(date +%Y%m%d) \
     --skip-final-snapshot
   
   # Document results in runbook log
   # Update recovery procedures if issues found
   ```

**Expected RTO:** 2-3 hours (well within 4 hour requirement)

## Monitoring & Alerting

### CloudWatch Alarms

1. **Backup Age Alarm**
   - **Metric:** `TimeSinceLastBackup`
   - **Threshold:** > 25 hours
   - **Action:** Send SNS notification
   - **Status:** Active

2. **Backup Failure Alarm**
   - **Source:** EventBridge rule on backup job state
   - **Trigger:** Backup job state = FAILED or EXPIRED
   - **Action:** Send SNS notification
   - **Status:** Active

### SNS Notifications

- **Topic:** `video-window-backup-notifications`
- **Subscribers:** ops-team@craftvideomarketplace.com
- **Delivery:** Email + SMS for critical alerts

### Dashboard Metrics

Grafana dashboard: "Database Backup Health"
- Backup success rate (last 30 days)
- Time since last successful backup
- Backup size trend
- Restore test results

## Troubleshooting

### Backup Job Fails

**Symptoms:** CloudWatch alarm triggered, no recent snapshot

**Diagnosis:**
```bash
# Check RDS events
aws rds describe-events \
  --source-identifier video-window \
  --source-type db-instance

# Check backup job status
aws backup list-backup-jobs \
  --by-backup-vault-name video-window-backup-vault \
  --by-state FAILED
```

**Common Causes:**
1. **Insufficient IAM permissions:** Verify backup role has required policies
2. **Storage full:** Check allocated storage and increase if needed
3. **Long-running queries:** Check for blocking queries during backup window
4. **Network issues:** Verify VPC connectivity

**Resolution:**
- Fix underlying cause
- Manually trigger backup if necessary
- Monitor next automated backup

### PITR Restore Fails

**Symptoms:** Restore job fails or restored instance is incomplete

**Diagnosis:**
```bash
# Check RDS restore events
aws rds describe-events \
  --source-identifier <restore-target-id> \
  --source-type db-instance

# Verify PITR is enabled
aws rds describe-db-instances \
  --db-instance-identifier video-window \
  --query 'DBInstances[0].BackupRetentionPeriod'
```

**Common Causes:**
1. **Target time outside PITR window:** PITR only available for last 7 days
2. **Insufficient subnet/security group access:** Verify network config
3. **Instance name conflict:** Use unique identifier

**Resolution:**
- Use snapshot restore if PITR unavailable
- Verify all restore parameters
- Retry with corrected configuration

### Slow Restore Performance

**Symptoms:** Restore takes > 4 hours

**Diagnosis:**
- Check database size
- Verify instance class matches source
- Check network throughput

**Optimization:**
- Use larger instance class for restore (scale down after)
- Restore during low-traffic periods
- Consider multi-AZ for production (after restore)

## Data Retention Compliance

### Legal Requirements

- **Financial records:** 7 years (retained separately, see compliance docs)
- **User data:** Per privacy policy (2 years inactive)
- **Audit logs:** 2 years
- **Backups:** 30 days operational, then deleted

### Backup Scope

**Included in Backups:**
- All production database tables
- User accounts and profiles
- Transaction records
- Content metadata
- System configuration

**Excluded from Backups:**
- Redis cache data (transient)
- CloudWatch logs (separate retention)
- S3 objects (separate backup policy)
- Temporary tables

### Cross-Border Considerations

- **EU data:** Backups stored in same region as source
- **GDPR compliance:** Backups encrypted, access logged
- **Data residency:** No cross-region backup copy (currently)

## Emergency Contacts

### Primary On-Call
- **DevOps Team:** ops-team@craftvideomarketplace.com
- **Escalation:** CTO
- **Incident Response:** incident-response@craftvideomarketplace.com

### AWS Support
- **Support Plan:** Business
- **Case Priority:** Urgent (< 1 hour response for production down)

## Related Documents

- [Data Classification Framework](./data-classification.md)
- [DSAR Process](./dsar-process.md)
- [ADR-0003: Database Architecture](../architecture/adr/ADR-0003-database-architecture.md)
- [ADR-0005: AWS Infrastructure](../architecture/adr/ADR-0005-aws-infrastructure.md)
- [Tech Spec Epic 03](../tech-spec-epic-03.md)

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0.0 | Initial version | Amelia (Dev Agent) |

## Appendix: Validation Queries

**File:** `validation_queries.sql`

```sql
-- User data validation
SELECT 
  'users' as table_name,
  COUNT(*) as row_count,
  MIN(created_at) as oldest_record,
  MAX(created_at) as newest_record
FROM users;

-- Transaction validation
SELECT 
  'transactions' as table_name,
  COUNT(*) as row_count,
  SUM(amount) as total_amount,
  MAX(created_at) as latest_transaction
FROM transactions;

-- Data integrity checks
SELECT 
  'orphaned_records' as check_name,
  COUNT(*) as issue_count
FROM videos v
LEFT JOIN users u ON v.user_id = u.id
WHERE u.id IS NULL;

-- Index validation
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Database size
SELECT 
  pg_size_pretty(pg_database_size('serverpod')) as database_size;
```

