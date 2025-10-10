#!/bin/bash
# Review reminder system for documentation governance

set -euo pipefail

# Configuration
GOVERNANCE_DIR="${GOVERNANCE_DIR:-docs/quality-automation/governance}"
REMINDER_DAYS="${REMINDER_DAYS:-7}"
OVERDUE_DAYS="${OVERDUE_DAYS:-14}"

# Email configuration (customize as needed)
EMAIL_ENABLED="${EMAIL_ENABLED:-false}"
EMAIL_FROM="${EMAIL_FROM:-noreply@example.com}"
SMTP_SERVER="${SMTP_SERVER:-smtp.example.com}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Send email reminder (placeholder implementation)
send_email_reminder() {
    local recipient="$1"
    local subject="$2"
    local body="$3"

    if [[ "$EMAIL_ENABLED" == "true" ]]; then
        # In a real implementation, this would use a proper email client
        log_info "Email enabled - would send to $recipient"
        echo "Subject: $subject"
        echo "$body"
    else
        log_info "Email disabled - showing reminder content:"
        echo "To: $recipient"
        echo "Subject: $subject"
        echo ""
        echo "$body"
        echo "--- End of reminder ---"
    fi
}

# Generate review reminder body
generate_reminder_body() {
    local file="$1"
    local owner="$2"
    local due_date="$3"
    local overdue_days="$4"

    cat << EOF
Hi $owner,

This is an automated reminder about a pending documentation review.

Document: $file
Review due: $due_date

EOF

    if [[ "$overdue_days" -gt 0 ]]; then
        echo "STATUS: OVERDUE by $overdue_days days"
        echo "ACTION REQUIRED: Please review this document as soon as possible."
        echo
    else
        echo "STATUS: Due for review"
        echo "ACTION: Please review this document by the due date."
        echo
    fi

    cat << EOF
Review Guidelines:
1. Check content accuracy and completeness
2. Verify all links are working
3. Ensure compliance with documentation standards
4. Update any outdated information
5. Add your review comments in the Dev Agent Record section

To complete the review:
1. Open the document and review the content
2. Add your review comments
3. Update the QA Results section
4. Update the review timestamp in the governance records

If you have any questions about this review process, please contact the documentation team.

Best regards,
Documentation Governance System

---
This is an automated message. Please do not reply to this email.
EOF
}

# Check for upcoming and overdue reviews
check_reviews() {
    log_info "Checking for reviews requiring attention..."

    local upcoming_reviews=()
    local overdue_reviews=()

    # Ensure governance directory exists
    mkdir -p "$GOVERNANCE_DIR"

    # Process all ownership records
    for ownership_file in "$GOVERNANCE_DIR"/*.ownership.json; do
        if [[ ! -f "$ownership_file" ]]; then
            continue
        fi

        # Extract review information
        local file_path
        local primary_owner
        local next_review

        # Use jq if available, otherwise use basic text parsing
        if command -v jq &> /dev/null; then
            file_path=$(jq -r '.file_path' "$ownership_file" 2>/dev/null || echo "")
            primary_owner=$(jq -r '.primary_owner' "$ownership_file" 2>/dev/null || echo "")
            next_review=$(jq -r '.next_review' "$ownership_file" 2>/dev/null || echo "")
        else
            log_warning "jq not available - skipping detailed review analysis"
            continue
        fi

        if [[ -z "$file_path" || -z "$primary_owner" || -z "$next_review" ]]; then
            continue
        fi

        # Parse dates
        local now_epoch=$(date +%s)
        local review_epoch
        if command -v date &> /dev/null; then
            review_epoch=$(date -d "$next_review" +%s 2>/dev/null || echo 0)
        else
            log_warning "date command not available - skipping date calculations"
            continue
        fi

        local reminder_epoch=$((now_epoch + REMINDER_DAYS * 24 * 3600))

        if [[ "$review_epoch" -eq 0 ]]; then
            log_warning "Invalid date format in $ownership_file"
            continue
        fi

        # Check if review is overdue
        if [[ "$review_epoch" -lt "$now_epoch" ]]; then
            local overdue_days=$(( (now_epoch - review_epoch) / (24 * 3600) ))
            overdue_reviews+=("$file_path|$primary_owner|$next_review|$overdue_days")
        # Check if review is coming up soon
        elif [[ "$review_epoch" -lt "$reminder_epoch" ]]; then
            upcoming_reviews+=("$file_path|$primary_owner|$next_review|0")
        fi
    done

    # Process overdue reviews
    if [[ ${#overdue_reviews[@]} -gt 0 ]]; then
        log_warning "Found ${#overdue_reviews[@]} overdue reviews"

        for review in "${overdue_reviews[@]}"; do
            IFS='|' read -r file_path owner due_date overdue_days <<< "$review"

            log_error "OVERDUE: $file_path (Owner: $owner, Overdue: $overdue_days days)"

            # Send overdue reminder
            local subject="URGENT: Overdue Documentation Review - $file_path"
            local body
            body=$(generate_reminder_body "$file_path" "$owner" "$due_date" "$overdue_days")
            send_email_reminder "${owner}@example.com" "$subject" "$body"
        done
    fi

    # Process upcoming reviews
    if [[ ${#upcoming_reviews[@]} -gt 0 ]]; then
        log_info "Found ${#upcoming_reviews[@]} upcoming reviews"

        for review in "${upcoming_reviews[@]}"; do
            IFS='|' read -r file_path owner due_date _ <<< "$review"

            log_info "Upcoming: $file_path (Owner: $owner, Due: $due_date)"

            # Send upcoming reminder
            local subject="Documentation Review Due Soon - $file_path"
            local body
            body=$(generate_reminder_body "$file_path" "$owner" "$due_date" "0")
            send_email_reminder "${owner}@example.com" "$subject" "$body"
        done
    fi

    # Generate summary report
    local total_reviews=$((${#overdue_reviews[@]} + ${#upcoming_reviews[@]}))

    if [[ "$total_reviews" -gt 0 ]]; then
        log_info "Review reminder summary:"
        log_info "  Overdue reviews: ${#overdue_reviews[@]}"
        log_info "  Upcoming reviews: ${#upcoming_reviews[@]}"
        log_info "  Total reminders sent: $total_reviews"
    else
        log_success "No reviews requiring attention at this time"
    fi

    # Save reminder log
    local log_file="$GOVERNANCE_DIR/review-reminders.log"
    {
        echo "=== Review Reminder Check - $(date) ==="
        echo "Overdue reviews: ${#overdue_reviews[@]}"
        echo "Upcoming reviews: ${#upcoming_reviews[@]}"
        echo "Total reminders: $total_reviews"
        echo ""
    } >> "$log_file"

    return $total_reviews
}

# Generate review schedule report
generate_schedule_report() {
    log_info "Generating review schedule report..."

    mkdir -p "$GOVERNANCE_DIR"

    local schedule_file="$GOVERNANCE_DIR/review-schedule.md"
    local report_date=$(date '+%Y-%m-%d')

    cat > "$schedule_file" << EOF
# Documentation Review Schedule

Generated: $report_date
Next check: $(date -d "+$REMINDER_DAYS days" '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')

## Overview

This report shows the upcoming review schedule for all documentation.

## Upcoming Reviews (Next $REMINDER_DAYS Days)

EOF

    # Add upcoming reviews to report
    local upcoming_count=0
    local reminder_epoch
    if command -v date &> /dev/null; then
        reminder_epoch=$(date -d "+$REMINDER_DAYS days" +%s 2>/dev/null || echo $(date +%s))
    else
        reminder_epoch=$(date +%s)
    fi

    for ownership_file in "$GOVERNANCE_DIR"/*.ownership.json; do
        if [[ ! -f "$ownership_file" ]]; then
            continue
        fi

        local file_path
        local primary_owner
        local next_review
        local document_type

        if command -v jq &> /dev/null; then
            file_path=$(jq -r '.file_path' "$ownership_file" 2>/dev/null || echo "")
            primary_owner=$(jq -r '.primary_owner' "$ownership_file" 2>/dev/null || echo "")
            next_review=$(jq -r '.next_review' "$ownership_file" 2>/dev/null || echo "")
            document_type=$(jq -r '.document_type' "$ownership_file" 2>/dev/null || echo "")
        else
            continue
        fi

        if [[ -z "$file_path" || -z "$next_review" ]]; then
            continue
        fi

        local review_epoch
        if command -v date &> /dev/null; then
            review_epoch=$(date -d "$next_review" +%s 2>/dev/null || echo 0)
        else
            review_epoch=0
        fi

        if [[ "$review_epoch" -gt 0 && "$review_epoch" -lt "$reminder_epoch" ]]; then
            ((upcoming_count++))

            local review_date
            if command -v date &> /dev/null; then
                review_date=$(date -d "$next_review" '+%Y-%m-%d' 2>/dev/null || echo "$next_review")
            else
                review_date="$next_review"
            fi

            local review_status="Upcoming"

            if [[ "$review_epoch" -lt $(date +%s) ]]; then
                review_status="Overdue"
            fi

            cat >> "$schedule_file" << EOF
### $file_path

- **Owner**: $primary_owner
- **Type**: $document_type
- **Due Date**: $review_date
- **Status**: $review_status

EOF
        fi
    done

    if [[ "$upcoming_count" -eq 0 ]]; then
        echo "No reviews scheduled in the next $REMINDER_DAYS days." >> "$schedule_file"
    fi

    # Add footer
    cat >> "$schedule_file" << EOF

## Review Process

1. **Review Content**: Check for accuracy, completeness, and clarity
2. **Check Links**: Verify all internal and external links work
3. **Update Standards**: Ensure compliance with current documentation standards
4. **Record Results**: Update the QA Results section with findings
5. **Update Timestamp**: Refresh the review date in governance records

## Contact

For questions about the review process, contact the documentation team.

---
*This report is automatically generated by the Documentation Governance System*
EOF

    log_success "Review schedule report generated: $schedule_file"
}

# Main execution
main() {
    case "${1:-check}" in
        "check")
            check_reviews
            ;;
        "schedule")
            generate_schedule_report
            ;;
        "both")
            check_reviews
            generate_schedule_report
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo
            echo "Commands:"
            echo "  check     Check for reviews requiring reminders"
            echo "  schedule  Generate review schedule report"
            echo "  both      Run both check and schedule generation"
            echo "  help      Show this help message"
            echo
            echo "Environment Variables:"
            echo "  GOVERNANCE_DIR  Governance directory (default: docs/quality-automation/governance)"
            echo "  REMINDER_DAYS   Days before due date to send reminder (default: 7)"
            echo "  OVERDUE_DAYS    Days after due date to escalate (default: 14)"
            echo "  EMAIL_ENABLED   Enable email notifications (default: false)"
            echo "  EMAIL_FROM      From email address for notifications"
            echo "  SMTP_SERVER     SMTP server for sending emails"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi