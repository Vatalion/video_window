# Documentation Governance System

Status: v1.0 — Comprehensive ownership matrix, review schedules, and version control procedures

## Overview

This governance system establishes clear ownership, responsibilities, and processes for maintaining high-quality documentation across the project.

## Ownership Matrix

### Document Type Ownership

```yaml
# docs/quality-automation/ownership-matrix.yml
ownership_matrix:
  document_types:
    user_stories:
      primary_owner: "product-owner"
      secondary_owners: ["business-analyst", "tech-lead"]
      contributors: ["ui-designer", "qa-engineer", "developer"]
      approvers: ["product-owner", "tech-lead"]
      review_frequency: "bi-weekly"
      retention_period: "permanent"

    technical_decisions:
      primary_owner: "architect"
      secondary_owners: ["tech-lead", "senior-developer"]
      contributors: ["developer", "devops-engineer"]
      approvers: ["architect", "cto"]
      review_frequency: "monthly"
      retention_period: "permanent"

    architecture_documents:
      primary_owner: "architect"
      secondary_owners: ["tech-lead", "system-designer"]
      contributors: ["developer", "database-admin", "devops-engineer"]
      approvers: ["architect", "tech-lead"]
      review_frequency: "quarterly"
      retention_period: "permanent"

    qa_assessments:
      primary_owner: "qa-lead"
      secondary_owners: ["test-engineer", "security-analyst"]
      contributors: ["developer", "product-owner"]
      approvers: ["qa-lead", "tech-lead"]
      review_frequency: "as-needed"
      retention_period: "2-years"

    api_documentation:
      primary_owner: "api-lead"
      secondary_owners: ["backend-developer", "tech-writer"]
      contributors: ["frontend-developer", "qa-engineer"]
      approvers: ["api-lead", "tech-lead"]
      review_frequency: "monthly"
      retention_period: "current-version-plus-1"

    user_guides:
      primary_owner: "tech-writer"
      secondary_owners: ["product-owner", "ui-designer"]
      contributors: ["customer-support", "developer"]
      approvers: ["product-owner", "tech-writer"]
      review_frequency: "monthly"
      retention_period: "current-version-plus-2"

    compliance_documents:
      primary_owner: "compliance-officer"
      secondary_owners: ["legal-counsel", "security-analyst"]
      contributors: ["process-owner", "auditor"]
      approvers: ["compliance-officer", "legal-counsel"]
      review_frequency: "quarterly"
      retention_period: "7-years"

role_definitions:
  product-owner:
    responsibilities:
      - "Own user story content and accuracy"
      - "Ensure business requirements are properly documented"
      - "Approve user-facing documentation"
      - "Maintain product backlog documentation"
    skills_required: ["product-knowledge", "business-analysis", "communication"]

  architect:
    responsibilities:
      - "Own technical decisions and architecture"
      - "Ensure technical accuracy and consistency"
      - "Approve architectural documentation"
      - "Maintain system design documentation"
    skills_required: ["system-design", "technical-leadership", "documentation"]

  tech-lead:
    responsibilities:
      - "Own implementation details and technical specifications"
      - "Ensure code documentation completeness"
      - "Review and approve technical documentation"
      - "Maintain development guidelines"
    skills_required: ["technical-expertise", "team-leadership", "quality-standards"]

  qa-lead:
    responsibilities:
      - "Own testing strategy and quality documentation"
      - "Ensure test coverage documentation"
      - "Review and approve quality-related documents"
      - "Maintain quality standards documentation"
    skills_required: ["testing-expertise", "quality-assurance", "risk-assessment"]

  tech-writer:
    responsibilities:
      - "Own documentation quality and consistency"
      - "Ensure proper grammar and style"
      - "Maintain documentation templates and guidelines"
      - "Review and edit all user-facing documentation"
    skills_required: ["technical-writing", "editing", "style-guides"]

  compliance-officer:
    responsibilities:
      - "Own compliance and regulatory documentation"
      - "Ensure legal and regulatory requirements are met"
      - "Maintain audit trail and documentation"
      - "Review and approve compliance-related documents"
    skills_required: ["regulatory-knowledge", "risk-management", "attention-to-detail"]
```

### Automated Ownership Assignment

```python
#!/usr/bin/env python3
"""
Automated ownership assignment and tracking system.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime, timedelta

class GovernanceManager:
    """Manages documentation governance, ownership, and compliance."""

    def __init__(self, config_path: str = "docs/quality-automation/ownership-matrix.yml"):
        self.config_path = config_path
        self.ownership_matrix = self._load_ownership_matrix()
        self.docs_dir = Path("docs")
        self.governance_dir = Path("docs/quality-automation/governance")
        self.governance_dir.mkdir(parents=True, exist_ok=True)

    def _load_ownership_matrix(self) -> Dict:
        """Load ownership matrix from configuration file."""
        try:
            import yaml
            with open(self.config_path, 'r') as f:
                return yaml.safe_load(f)
        except ImportError:
            print("PyYAML not installed, using default configuration")
            return self._get_default_ownership_matrix()
        except FileNotFoundError:
            print(f"Ownership matrix file not found: {self.config_path}")
            return self._get_default_ownership_matrix()

    def _get_default_ownership_matrix(self) -> Dict:
        """Get default ownership matrix configuration."""
        return {
            "ownership_matrix": {
                "document_types": {
                    "user_stories": {
                        "primary_owner": "product-owner",
                        "review_frequency": "bi-weekly",
                        "retention_period": "permanent"
                    },
                    "technical_decisions": {
                        "primary_owner": "architect",
                        "review_frequency": "monthly",
                        "retention_period": "permanent"
                    },
                    "architecture_documents": {
                        "primary_owner": "architect",
                        "review_frequency": "quarterly",
                        "retention_period": "permanent"
                    }
                }
            }
        }

    def detect_document_type(self, file_path: Path) -> str:
        """Detect document type from file path and content."""
        relative_path = file_path.relative_to(self.docs_dir)
        path_str = str(relative_path).lower()
        filename = file_path.name.lower()

        # Directory-based detection
        if "stories" in path_str:
            return "user_stories"
        elif "adr" in path_str or "technical-decisions" in path_str:
            return "technical_decisions"
        elif "architecture" in path_str:
            return "architecture_documents"
        elif "qa/assessments" in path_str:
            return "qa_assessments"
        elif "api" in path_str:
            return "api_documentation"
        elif "user-guide" in path_str or "guides" in path_str:
            return "user_guides"
        elif "compliance" in path_str:
            return "compliance_documents"

        # Filename pattern detection
        if filename.startswith("adr-"):
            return "technical_decisions"
        elif filename.startswith("readme"):
            return "general_documentation"

        return "general_documentation"

    def assign_ownership(self, file_path: Path) -> Dict:
        """Assign ownership based on document type."""
        doc_type = self.detect_document_type(file_path)
        ownership_config = self.ownership_matrix["ownership_matrix"]["document_types"].get(doc_type, {})

        return {
            "file_path": str(file_path),
            "document_type": doc_type,
            "primary_owner": ownership_config.get("primary_owner", "unassigned"),
            "secondary_owners": ownership_config.get("secondary_owners", []),
            "contributors": ownership_config.get("contributors", []),
            "approvers": ownership_config.get("approvers", []),
            "review_frequency": ownership_config.get("review_frequency", "monthly"),
            "retention_period": ownership_config.get("retention_period", "permanent"),
            "assigned_at": datetime.now().isoformat(),
            "last_reviewed": None,
            "next_review": self._calculate_next_review(ownership_config.get("review_frequency", "monthly"))
        }

    def _calculate_next_review(self, frequency: str) -> str:
        """Calculate next review date based on frequency."""
        now = datetime.now()

        if frequency == "weekly":
            next_review = now + timedelta(weeks=1)
        elif frequency == "bi-weekly":
            next_review = now + timedelta(weeks=2)
        elif frequency == "monthly":
            next_review = now + timedelta(days=30)
        elif frequency == "quarterly":
            next_review = now + timedelta(days=90)
        elif frequency == "annually":
            next_review = now + timedelta(days=365)
        else:
            next_review = now + timedelta(days=30)  # Default to monthly

        return next_review.isoformat()

    def save_ownership_record(self, ownership: Dict):
        """Save ownership record for a document."""
        file_path = Path(ownership["file_path"])
        ownership_file = self.governance_dir / f"{file_path.stem}.ownership.json"

        with open(ownership_file, 'w') as f:
            json.dump(ownership, f, indent=2)

    def process_all_documents(self):
        """Process all documents and assign ownership."""
        print("Processing all documentation files...")

        for doc_file in self.docs_dir.rglob("*.md"):
            # Skip system files
            if any(pattern in str(doc_file) for pattern in
                   [".git", "node_modules", ".DS_Store", "quality-automation"]):
                continue

            ownership = self.assign_ownership(doc_file)
            self.save_ownership_record(ownership)

        print("Ownership assignment completed!")

    def generate_ownership_report(self) -> Dict:
        """Generate comprehensive ownership report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "total_documents": 0,
            "documents_by_type": {},
            "ownership_summary": {},
            "review_schedule": [],
            "overdue_reviews": []
        }

        # Process all ownership records
        for ownership_file in self.governance_dir.glob("*.ownership.json"):
            try:
                with open(ownership_file, 'r') as f:
                    ownership = json.load(f)

                report["total_documents"] += 1

                # Count by document type
                doc_type = ownership["document_type"]
                report["documents_by_type"][doc_type] = report["documents_by_type"].get(doc_type, 0) + 1

                # Count by primary owner
                primary_owner = ownership["primary_owner"]
                report["ownership_summary"][primary_owner] = report["ownership_summary"].get(primary_owner, 0) + 1

                # Add to review schedule
                next_review = datetime.fromisoformat(ownership["next_review"])
                report["review_schedule"].append({
                    "file": ownership["file_path"],
                    "document_type": doc_type,
                    "owner": primary_owner,
                    "next_review": ownership["next_review"]
                })

                # Check for overdue reviews
                if next_review < datetime.now():
                    report["overdue_reviews"].append({
                        "file": ownership["file_path"],
                        "document_type": doc_type,
                        "owner": primary_owner,
                        "overdue_since": ownership["next_review"]
                    })

            except Exception as e:
                print(f"Error processing ownership file {ownership_file}: {e}")

        # Sort review schedule by next review date
        report["review_schedule"].sort(key=lambda x: x["next_review"])

        return report

    def save_ownership_report(self, report: Dict):
        """Save ownership report to file."""
        report_file = self.governance_dir / f"ownership-report-{datetime.now().strftime('%Y%m%d')}.json"

        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Ownership report saved: {report_file}")
        return report_file

    def check_governance_compliance(self) -> Dict:
        """Check governance compliance across all documents."""
        compliance_report = {
            "checked_at": datetime.now().isoformat(),
            "compliance_score": 0,
            "issues": [],
            "recommendations": []
        }

        total_checks = 0
        passed_checks = 0

        # Check ownership assignment
        ownership_files = list(self.governance_dir.glob("*.ownership.json"))
        if not ownership_files:
            compliance_report["issues"].append({
                "severity": "high",
                "category": "ownership",
                "description": "No ownership records found"
            })
        else:
            passed_checks += 1
        total_checks += 1

        # Check overdue reviews
        for ownership_file in ownership_files:
            try:
                with open(ownership_file, 'r') as f:
                    ownership = json.load(f)

                next_review = datetime.fromisoformat(ownership["next_review"])
                if next_review < datetime.now():
                    compliance_report["issues"].append({
                        "severity": "medium",
                        "category": "review",
                        "description": f"Overdue review: {ownership['file_path']}",
                        "overdue_days": (datetime.now() - next_review).days
                    })
                else:
                    passed_checks += 1
                total_checks += 1

            except Exception as e:
                compliance_report["issues"].append({
                    "severity": "low",
                    "category": "data",
                    "description": f"Error reading ownership file: {ownership_file}"
                })

        # Calculate compliance score
        if total_checks > 0:
            compliance_report["compliance_score"] = (passed_checks / total_checks) * 100

        # Generate recommendations
        if compliance_report["compliance_score"] < 80:
            compliance_report["recommendations"].append("Overall compliance score is below 80% - immediate attention required")

        overdue_count = len([issue for issue in compliance_report["issues"] if issue["category"] == "review"])
        if overdue_count > 5:
            compliance_report["recommendations"].append(f"High number of overdue reviews ({overdue_count}) - consider scheduling catch-up")

        return compliance_report

def main():
    """Main execution function."""
    import sys

    manager = GovernanceManager()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "assign":
            manager.process_all_documents()

        elif command == "report":
            report = manager.generate_ownership_report()
            report_file = manager.save_ownership_report(report)
            print(json.dumps(report, indent=2))

        elif command == "compliance":
            compliance = manager.check_governance_compliance()
            print(json.dumps(compliance, indent=2))

        elif command == "help":
            print("Documentation Governance Manager")
            print("Usage: python governance-manager.py <command>")
            print("Commands:")
            print("  assign      Assign ownership to all documents")
            print("  report      Generate ownership report")
            print("  compliance  Check governance compliance")
            print("  help        Show this help message")

        else:
            print(f"Unknown command: {command}")
            print("Use 'help' for usage information")

    else:
        print("Documentation Governance Manager")
        print("Usage: python governance-manager.py <command>")
        print("Commands:")
        print("  assign      Assign ownership to all documents")
        print("  report      Generate ownership report")
        print("  compliance  Check governance compliance")
        print("  help        Show this help message")

if __name__ == "__main__":
    main()
```

## Review Schedule Automation

### Automated Review Reminders

```bash
#!/bin/bash
# docs/scripts/review-reminder.sh

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

# Send email reminder
send_email_reminder() {
    local recipient="$1"
    local subject="$2"
    local body="$3"

    if [[ "$EMAIL_ENABLED" == "true" ]]; then
        echo "$body" | mail -s "$subject" -r "$EMAIL_FROM" "$recipient" \
            -S smtp="$SMTP_SERVER" || log_warning "Failed to send email to $recipient"
    else
        log_info "Email disabled. Would send to $recipient:"
        echo "Subject: $subject"
        echo "$body"
        echo "---"
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

    # Process all ownership records
    for ownership_file in "$GOVERNANCE_DIR"/*.ownership.json; do
        if [[ ! -f "$ownership_file" ]]; then
            continue
        fi

        # Extract review information
        local file_path
        local primary_owner
        local next_review

        file_path=$(jq -r '.file_path' "$ownership_file" 2>/dev/null || echo "")
        primary_owner=$(jq -r '.primary_owner' "$ownership_file" 2>/dev/null || echo "")
        next_review=$(jq -r '.next_review' "$ownership_file" 2>/dev/null || echo "")

        if [[ -z "$file_path" || -z "$primary_owner" || -z "$next_review" ]]; then
            continue
        fi

        # Parse dates
        local now_epoch=$(date +%s)
        local review_epoch=$(date -d "$next_review" +%s 2>/dev/null || echo 0)
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

    local schedule_file="$GOVERNANCE_DIR/review-schedule.md"
    local report_date=$(date '+%Y-%m-%d')

    cat > "$schedule_file" << EOF
# Documentation Review Schedule

Generated: $report_date
Next check: $(date -d "+$REMINDER_DAYS days" '+%Y-%m-%d')

## Overview

This report shows the upcoming review schedule for all documentation.

## Upcoming Reviews (Next $REMINDER_DAYS Days)

EOF

    # Add upcoming reviews to report
    local upcoming_count=0
    local reminder_epoch=$(date -d "+$REMINDER_DAYS days" +%s)

    for ownership_file in "$GOVERNANCE_DIR"/*.ownership.json; do
        if [[ ! -f "$ownership_file" ]]; then
            continue
        fi

        local file_path
        local primary_owner
        local next_review
        local document_type

        file_path=$(jq -r '.file_path' "$ownership_file" 2>/dev/null || echo "")
        primary_owner=$(jq -r '.primary_owner' "$ownership_file" 2>/dev/null || echo "")
        next_review=$(jq -r '.next_review' "$ownership_file" 2>/dev/null || echo "")
        document_type=$(jq -r '.document_type' "$ownership_file" 2>/dev/null || echo "")

        if [[ -z "$file_path" || -z "$next_review" ]]; then
            continue
        fi

        local review_epoch=$(date -d "$next_review" +%s 2>/dev/null || echo 0)

        if [[ "$review_epoch" -gt 0 && "$review_epoch" -lt "$reminder_epoch" ]]; then
            ((upcoming_count++))

            local review_date=$(date -d "$next_review" '+%Y-%m-%d')
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
```

## Version Control Procedures

### Automated Version Management

```python
#!/usr/bin/env python3
"""
Automated version control procedures for documentation.
"""

import json
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import subprocess

class DocumentationVersionManager:
    """Manages versioning and archival procedures for documentation."""

    def __init__(self, docs_dir: str = "docs", versions_dir: str = "docs/versions"):
        self.docs_dir = Path(docs_dir)
        self.versions_dir = Path(versions_dir)
        self.versions_dir.mkdir(parents=True, exist_ok=True)

    def extract_version_from_file(self, file_path: Path) -> Optional[str]:
        """Extract version information from document content."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Look for version patterns
            version_patterns = [
                r'Version:\s*(\d+\.\d+\.\d+)',
                r'v(\d+\.\d+\.\d+)',
                r'Version\s*(\d+\.\d+\.\d+)',
                r'Status:\s*v(\d+\.\d+\.\d+)'
            ]

            for pattern in version_patterns:
                match = re.search(pattern, content, re.IGNORECASE)
                if match:
                    return match.group(1)

            return None
        except Exception as e:
            print(f"Error reading file {file_path}: {e}")
            return None

    def get_git_file_history(self, file_path: Path) -> List[Dict]:
        """Get Git history for a file."""
        try:
            # Get git log for the file
            result = subprocess.run([
                'git', 'log', '--pretty=format:%H|%an|%ad|%s',
                '--date=iso', str(file_path)
            ], capture_output=True, text=True, cwd=self.docs_dir.parent)

            if result.returncode != 0:
                return []

            history = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('|', 3)
                    if len(parts) >= 4:
                        history.append({
                            'commit': parts[0],
                            'author': parts[1],
                            'date': parts[2],
                            'message': parts[3]
                        })

            return history
        except Exception as e:
            print(f"Error getting git history for {file_path}: {e}")
            return []

    def create_version_snapshot(self, version: str, description: str = "") -> str:
        """Create a snapshot of all documentation at a specific version."""
        snapshot_dir = self.versions_dir / f"v{version}"
        snapshot_dir.mkdir(exist_ok=True)

        # Create snapshot manifest
        manifest = {
            "version": version,
            "created_at": datetime.now().isoformat(),
            "description": description,
            "files": [],
            "total_files": 0
        }

        # Copy all documentation files
        for doc_file in self.docs_dir.rglob("*.md"):
            # Skip version files themselves
            if "versions" in str(doc_file):
                continue

            # Calculate relative path
            relative_path = doc_file.relative_to(self.docs_dir)
            target_path = snapshot_dir / relative_path
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # Copy file
            import shutil
            shutil.copy2(doc_file, target_path)

            # Add to manifest
            version_info = self.extract_version_from_file(doc_file)
            file_info = {
                "path": str(relative_path),
                "original_path": str(doc_file),
                "version": version_info,
                "git_history": self.get_git_file_history(doc_file),
                "size": doc_file.stat().st_size,
                "modified": datetime.fromtimestamp(doc_file.stat().st_mtime).isoformat()
            }

            manifest["files"].append(file_info)
            manifest["total_files"] += 1

        # Save manifest
        manifest_file = snapshot_dir / "manifest.json"
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)

        print(f"Version snapshot created: {snapshot_dir}")
        print(f"Total files: {manifest['total_files']}")

        return str(snapshot_dir)

    def archive_old_versions(self, retention_versions: int = 10):
        """Archive old versions, keeping only the most recent ones."""
        version_dirs = [d for d in self.versions_dir.iterdir() if d.is_dir() and d.name.startswith('v')]
        version_dirs.sort(key=lambda x: x.name, reverse=True)

        if len(version_dirs) <= retention_versions:
            print("No versions to archive (within retention limit)")
            return

        versions_to_archive = version_dirs[retention_versions:]
        archive_dir = self.versions_dir / "archive"
        archive_dir.mkdir(exist_ok=True)

        for version_dir in versions_to_archive:
            target_dir = archive_dir / version_dir.name
            import shutil
            shutil.move(str(version_dir), str(target_dir))
            print(f"Archived: {version_dir.name} -> archive/{version_dir.name}")

    def generate_version_report(self) -> Dict:
        """Generate comprehensive version report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "current_versions": [],
            "archived_versions": [],
            "version_statistics": {},
            "recommendations": []
        }

        # Get current versions
        current_dir = self.versions_dir
        archive_dir = self.versions_dir / "archive"

        for version_dir in current_dir.iterdir():
            if version_dir.is_dir() and version_dir.name.startswith('v'):
                manifest_file = version_dir / "manifest.json"
                if manifest_file.exists():
                    with open(manifest_file, 'r') as f:
                        manifest = json.load(f)
                    report["current_versions"].append(manifest)

        # Get archived versions
        if archive_dir.exists():
            for version_dir in archive_dir.iterdir():
                if version_dir.is_dir() and version_dir.name.startswith('v'):
                    manifest_file = version_dir / "manifest.json"
                    if manifest_file.exists():
                        with open(manifest_file, 'r') as f:
                            manifest = json.load(f)
                        report["archived_versions"].append(manifest)

        # Calculate statistics
        total_files = sum(v.get("total_files", 0) for v in report["current_versions"])
        report["version_statistics"] = {
            "current_versions": len(report["current_versions"]),
            "archived_versions": len(report["archived_versions"]),
            "total_files_current": total_files,
            "average_files_per_version": total_files / len(report["current_versions"]) if report["current_versions"] else 0
        }

        # Generate recommendations
        if len(report["current_versions"]) > 15:
            report["recommendations"].append("Consider archiving older versions to reduce storage")

        if len(report["current_versions"]) < 3:
            report["recommendations"].append("Create more frequent version snapshots for better history tracking")

        return report

    def save_version_report(self, report: Dict):
        """Save version report to file."""
        report_file = self.versions_dir / f"version-report-{datetime.now().strftime('%Y%m%d')}.json"

        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Version report saved: {report_file}")
        return report_file

def main():
    """Main execution function."""
    import sys

    manager = DocumentationVersionManager()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "snapshot":
            version = sys.argv[2] if len(sys.argv) > 2 else datetime.now().strftime("%Y.%m.%d")
            description = sys.argv[3] if len(sys.argv) > 3 else f"Version {version} snapshot"
            manager.create_version_snapshot(version, description)

        elif command == "archive":
            retention = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            manager.archive_old_versions(retention)

        elif command == "report":
            report = manager.generate_version_report()
            report_file = manager.save_version_report(report)
            print(json.dumps(report, indent=2))

        elif command == "help":
            print("Documentation Version Manager")
            print("Usage: python version-manager.py <command> [options]")
            print("Commands:")
            print("  snapshot [version] [description]  Create version snapshot")
            print("  archive [retention_count]         Archive old versions")
            print("  report                           Generate version report")
            print("  help                             Show this help message")

        else:
            print(f"Unknown command: {command}")
            print("Use 'help' for usage information")

    else:
        print("Documentation Version Manager")
        print("Usage: python version-manager.py <command> [options]")
        print("Commands:")
        print("  snapshot [version] [description]  Create version snapshot")
        print("  archive [retention_count]         Archive old versions")
        print("  report                           Generate version report")
        print("  help                             Show this help message")

if __name__ == "__main__":
    main()
```

This comprehensive governance system establishes clear ownership, automated review schedules, and version control procedures to maintain high-quality documentation throughout the project lifecycle.