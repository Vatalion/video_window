#!/bin/bash

# Database Recovery Test Script
# Story: 03-3 Data Retention & Backup Procedures
# Purpose: Automated monthly recovery testing to validate <4 hour RTO

set -e  # Exit on error

# Configuration
PROJECT_NAME="${PROJECT_NAME:-video-window}"
TEST_DATE=$(date +%Y%m%d-%H%M%S)
TEST_INSTANCE_ID="${PROJECT_NAME}-recovery-test-${TEST_DATE}"
LOG_FILE="recovery-test-${TEST_DATE}.log"
SUBNET_GROUP="${DB_SUBNET_GROUP:-default}"
SECURITY_GROUP="${DB_SECURITY_GROUP}"
RTO_THRESHOLD_HOURS=4

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        error "PostgreSQL client (psql) is not installed"
        exit 1
    fi
    
    if [ -z "$SECURITY_GROUP" ]; then
        error "DB_SECURITY_GROUP environment variable is not set"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Select recovery method (rotate monthly)
select_recovery_method() {
    MONTH=$(date +%m)
    MONTH_MOD=$((MONTH % 3))
    
    case $MONTH_MOD in
        1)
            RECOVERY_METHOD="pitr"
            log "Recovery method: Point-in-Time Recovery (PITR)"
            ;;
        2)
            RECOVERY_METHOD="snapshot"
            log "Recovery method: Snapshot Restore"
            ;;
        0)
            RECOVERY_METHOD="aws_backup"
            log "Recovery method: AWS Backup Restore"
            ;;
    esac
}

# PITR Recovery
test_pitr_recovery() {
    log "Starting PITR recovery test..."
    
    # Use staging database as source
    SOURCE_DB="${PROJECT_NAME}-staging"
    
    # Check if staging database exists
    if ! aws rds describe-db-instances --db-instance-identifier "$SOURCE_DB" &>/dev/null; then
        warning "Staging database not found, using production for test (read-only)"
        SOURCE_DB="${PROJECT_NAME}"
    fi
    
    # Calculate recovery time (1 hour ago)
    RECOVERY_TIME=$(date -u -d '1 hour ago' +'%Y-%m-%dT%H:%M:%SZ')
    
    log "Restoring from $SOURCE_DB to point-in-time: $RECOVERY_TIME"
    
    aws rds restore-db-instance-to-point-in-time \
        --source-db-instance-identifier "$SOURCE_DB" \
        --target-db-instance-identifier "$TEST_INSTANCE_ID" \
        --restore-time "$RECOVERY_TIME" \
        --db-subnet-group-name "$SUBNET_GROUP" \
        --vpc-security-group-ids "$SECURITY_GROUP" \
        --no-multi-az \
        --publicly-accessible \
        --tags Key=Name,Value="$TEST_INSTANCE_ID" Key=Purpose,Value=RecoveryTest Key=AutoDelete,Value=true \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        success "PITR restore initiated successfully"
    else
        error "PITR restore failed"
        return 1
    fi
}

# Snapshot Recovery
test_snapshot_recovery() {
    log "Starting snapshot recovery test..."
    
    # Find most recent automated snapshot
    SNAPSHOT_ID=$(aws rds describe-db-snapshots \
        --db-instance-identifier "${PROJECT_NAME}-staging" \
        --snapshot-type automated \
        --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1].DBSnapshotIdentifier' \
        --output text)
    
    if [ -z "$SNAPSHOT_ID" ] || [ "$SNAPSHOT_ID" == "None" ]; then
        error "No automated snapshots found"
        return 1
    fi
    
    log "Restoring from snapshot: $SNAPSHOT_ID"
    
    aws rds restore-db-instance-from-db-snapshot \
        --db-instance-identifier "$TEST_INSTANCE_ID" \
        --db-snapshot-identifier "$SNAPSHOT_ID" \
        --db-instance-class db.t3.micro \
        --db-subnet-group-name "$SUBNET_GROUP" \
        --vpc-security-group-ids "$SECURITY_GROUP" \
        --no-multi-az \
        --publicly-accessible \
        --tags Key=Name,Value="$TEST_INSTANCE_ID" Key=Purpose,Value=RecoveryTest Key=AutoDelete,Value=true \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        success "Snapshot restore initiated successfully"
    else
        error "Snapshot restore failed"
        return 1
    fi
}

# Wait for instance to be available
wait_for_instance() {
    log "Waiting for instance to become available..."
    
    local max_wait=3600  # 1 hour max wait
    local elapsed=0
    local interval=30
    
    while [ $elapsed -lt $max_wait ]; do
        STATUS=$(aws rds describe-db-instances \
            --db-instance-identifier "$TEST_INSTANCE_ID" \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null)
        
        if [ "$STATUS" == "available" ]; then
            success "Instance is available"
            return 0
        fi
        
        log "Instance status: $STATUS (waiting...)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    error "Instance did not become available within timeout"
    return 1
}

# Validate recovered data
validate_data() {
    log "Validating recovered data..."
    
    # Get endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$TEST_INSTANCE_ID" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
    
    if [ -z "$ENDPOINT" ]; then
        error "Could not retrieve database endpoint"
        return 1
    fi
    
    log "Connecting to: $ENDPOINT"
    
    # Run validation queries
    VALIDATION_RESULT=$(psql -h "$ENDPOINT" -U postgres -d serverpod -t -c "
        SELECT 
            'users=' || COUNT(*) 
        FROM users;
    " 2>&1)
    
    if [ $? -eq 0 ]; then
        log "Validation result: $VALIDATION_RESULT"
        success "Data validation passed"
        return 0
    else
        error "Data validation failed: $VALIDATION_RESULT"
        return 1
    fi
}

# Cleanup test instance
cleanup() {
    log "Cleaning up test instance..."
    
    if [ -n "$TEST_INSTANCE_ID" ]; then
        aws rds delete-db-instance \
            --db-instance-identifier "$TEST_INSTANCE_ID" \
            --skip-final-snapshot \
            >> "$LOG_FILE" 2>&1 || warning "Failed to delete test instance (may need manual cleanup)"
        
        log "Test instance deletion initiated: $TEST_INSTANCE_ID"
    fi
}

# Calculate and report RTO
calculate_rto() {
    END_TIME=$(date +%s)
    RTO_SECONDS=$((END_TIME - START_TIME))
    RTO_HOURS=$(awk "BEGIN {printf \"%.2f\", $RTO_SECONDS/3600}")
    
    log "========================================="
    log "RECOVERY TEST SUMMARY"
    log "========================================="
    log "Start Time: $(date -d @$START_TIME)"
    log "End Time: $(date -d @$END_TIME)"
    log "Total Duration: ${RTO_HOURS} hours"
    log "Recovery Method: $RECOVERY_METHOD"
    log "========================================="
    
    # Check if RTO meets requirement
    if (( $(awk "BEGIN {print ($RTO_HOURS < $RTO_THRESHOLD_HOURS)}") )); then
        success "✅ RTO REQUIREMENT MET: ${RTO_HOURS}h < ${RTO_THRESHOLD_HOURS}h"
        echo "PASSED" > recovery-test-result.txt
        exit 0
    else
        error "❌ RTO REQUIREMENT FAILED: ${RTO_HOURS}h >= ${RTO_THRESHOLD_HOURS}h"
        echo "FAILED" > recovery-test-result.txt
        exit 1
    fi
}

# Main execution
main() {
    log "========================================="
    log "DATABASE RECOVERY TEST"
    log "Test ID: $TEST_DATE"
    log "========================================="
    
    START_TIME=$(date +%s)
    
    # Setup trap for cleanup
    trap cleanup EXIT
    
    # Run test sequence
    check_prerequisites
    select_recovery_method
    
    case $RECOVERY_METHOD in
        pitr)
            test_pitr_recovery || exit 1
            ;;
        snapshot)
            test_snapshot_recovery || exit 1
            ;;
        aws_backup)
            warning "AWS Backup recovery test not yet implemented"
            log "Falling back to snapshot recovery"
            test_snapshot_recovery || exit 1
            ;;
    esac
    
    wait_for_instance || exit 1
    validate_data || exit 1
    
    calculate_rto
}

# Run main function
main "$@"

