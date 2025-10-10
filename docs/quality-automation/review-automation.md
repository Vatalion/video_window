# Review Process Automation System

Status: v1.0 — Automated peer review tracking and approval workflows

## Overview

This system automates the documentation review process through structured workflows, automated compliance checking, and peer review tracking.

## Review Workflow Automation

### Automated Review Assignment

```python
# docs/scripts/review-assignment.py
#!/usr/bin/env python3
"""
Automated review assignment system for documentation.
"""

import json
import os
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import random

class ReviewAssignmentEngine:
    """Automated review assignment based on expertise and availability."""

    def __init__(self, config_path: str = "docs/quality-automation/review-config.json"):
        self.config_path = config_path
        self.config = self._load_config()
        self.docs_dir = Path(self.config.get("docs_directory", "docs"))

    def _load_config(self) -> Dict:
        """Load review configuration."""
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                return json.load(f)
        return self._get_default_config()

    def _get_default_config(self) -> Dict:
        """Get default configuration."""
        return {
            "docs_directory": "docs",
            "reviewers": {
                "technical": {
                    "required": 1,
                    "expertise": ["architecture", "technical-decisions", "coding-standards"],
                    "assigned_to": ["tech-lead", "architect"]
                },
                "domain": {
                    "required": 1,
                    "expertise": ["user-stories", "acceptance-criteria", "business-logic"],
                    "assigned_to": ["product-owner", "business-analyst"]
                },
                "qa": {
                    "required": 1,
                    "expertise": ["testing", "quality-assurance", "validation"],
                    "assigned_to": ["qa-lead", "test-engineer"]
                }
            },
            "auto_assignment": {
                "enabled": True,
                "load_balancing": True,
                "consider_expertise": True,
                "avoid_conflicts": True
            },
            "review_deadlines": {
                "standard": 3,  # days
                "urgent": 1,   # days
                "complex": 5    # days
            }
        }

    def detect_document_type(self, file_path: Path) -> str:
        """Detect document type from file path and content."""
        file_name = file_path.name
        relative_path = file_path.relative_to(self.docs_dir)

        # Directory-based detection
        if "stories" in str(relative_path):
            return "user-story"
        elif "adr" in str(relative_path):
            return "technical-decision"
        elif "qa/assessments" in str(relative_path):
            return "qa-assessment"
        elif "architecture" in str(relative_path):
            return "architecture"
        elif "sessions" in str(relative_path):
            return "checkpoint"

        # Filename pattern detection
        if re.match(r'^\d+\.\d+\.', file_name):
            return "user-story"
        elif re.match(r'^ADR-\d{4}-', file_name):
            return "technical-decision"
        elif re.match(r'^\d+\.\d+-(risk|nfr)-\d{8}', file_name):
            return "qa-assessment"

        return "general"

    def assess_document_complexity(self, file_path: Path) -> str:
        """Assess document complexity based on content."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Complexity indicators
            word_count = len(content.split())
            section_count = len(re.findall(r'^#+\s', content, re.MULTILINE))
            code_blocks = len(re.findall(r'```', content))
            links = len(re.findall(r'\[.*\]\(.*\)', content))

            # Complexity scoring
            score = 0
            if word_count > 2000:
                score += 1
            if section_count > 10:
                score += 1
            if code_blocks > 5:
                score += 1
            if links > 20:
                score += 1

            # Determine complexity level
            if score >= 3:
                return "complex"
            elif score >= 1:
                return "standard"
            else:
                return "simple"

        except Exception as e:
            print(f"Error assessing complexity for {file_path}: {e}")
            return "standard"

    def get_required_reviewer_types(self, doc_type: str) -> List[str]:
        """Get required reviewer types based on document type."""
        requirements = {
            "user-story": ["domain", "technical"],
            "technical-decision": ["technical", "domain"],
            "qa-assessment": ["qa", "technical"],
            "architecture": ["technical"],
            "checkpoint": ["domain", "technical"],
            "general": ["technical"]
        }
        return requirements.get(doc_type, ["technical"])

    def select_reviewers(self, doc_type: str, complexity: str) -> Dict[str, List[str]]:
        """Select reviewers based on document type and complexity."""
        required_types = self.get_required_reviewer_types(doc_type)
        selected_reviewers = {}

        for review_type in required_types:
            if review_type in self.config["reviewers"]:
                reviewer_config = self.config["reviewers"][review_type]
                num_required = reviewer_config["required"]

                if complexity == "complex":
                    num_required += 1

                available_reviewers = reviewer_config["assigned_to"]

                if self.config["auto_assignment"]["load_balancing"]:
                    selected_reviewers[review_type] = self._balance_load(
                        available_reviewers, num_required
                    )
                else:
                    selected_reviewers[review_type] = random.sample(
                        available_reviewers,
                        min(num_required, len(available_reviewers))
                    )

        return selected_reviewers

    def _balance_load(self, reviewers: List[str], num_needed: int) -> List[str]:
        """Balance review load among reviewers."""
        # Simple load balancing - in production, this would query actual load
        return random.sample(reviewers, min(num_needed, len(reviewers)))

    def calculate_deadline(self, complexity: str) -> datetime:
        """Calculate review deadline based on complexity."""
        deadline_days = self.config["review_deadlines"].get(complexity, 3)
        return datetime.now() + timedelta(days=deadline_days)

    def create_review_assignment(self, file_path: Path) -> Dict:
        """Create a review assignment for a document."""
        doc_type = self.detect_document_type(file_path)
        complexity = self.assess_document_complexity(file_path)
        reviewers = self.select_reviewers(doc_type, complexity)
        deadline = self.calculate_deadline(complexity)

        assignment = {
            "file_path": str(file_path),
            "document_type": doc_type,
            "complexity": complexity,
            "reviewers": reviewers,
            "deadline": deadline.isoformat(),
            "status": "pending",
            "created_at": datetime.now().isoformat(),
            "reviews": []
        }

        return assignment

    def scan_for_new_documents(self) -> List[Path]:
        """Scan for documents that need review assignment."""
        new_documents = []

        for markdown_file in self.docs_dir.rglob("*.md"):
            # Skip certain files
            if any(pattern in str(markdown_file) for pattern in
                   ["node_modules", ".git", ".DS_Store", "README.md"]):
                continue

            # Check if document already has review assignment
            if not self._has_review_assignment(markdown_file):
                new_documents.append(markdown_file)

        return new_documents

    def _has_review_assignment(self, file_path: Path) -> bool:
        """Check if a document already has a review assignment."""
        # Look for review assignment file
        review_file = file_path.parent / f".{file_path.stem}.review.json"
        return review_file.exists()

    def assign_reviews(self) -> List[Dict]:
        """Assign reviews to new documents."""
        new_documents = self.scan_for_new_documents()
        assignments = []

        for doc_path in new_documents:
            assignment = self.create_review_assignment(doc_path)
            assignments.append(assignment)

            # Save assignment
            self._save_assignment(assignment)

            print(f"Assigned review for {doc_path}: {assignment['reviewers']}")

        return assignments

    def _save_assignment(self, assignment: Dict):
        """Save review assignment to file."""
        doc_path = Path(assignment["file_path"])
        review_file = doc_path.parent / f".{doc_path.stem}.review.json"

        with open(review_file, 'w') as f:
            json.dump(assignment, f, indent=2)

    def generate_review_summary(self) -> Dict:
        """Generate summary of current review assignments."""
        summary = {
            "generated_at": datetime.now().isoformat(),
            "total_assignments": 0,
            "pending_reviews": 0,
            "completed_reviews": 0,
            "overdue_reviews": 0,
            "reviewer_load": {},
            "documents_by_type": {},
            "documents_by_complexity": {}
        }

        # Scan for all review assignments
        for review_file in self.docs_dir.rglob(".*.review.json"):
            try:
                with open(review_file, 'r') as f:
                    assignment = json.load(f)

                summary["total_assignments"] += 1

                # Status counts
                if assignment["status"] == "completed":
                    summary["completed_reviews"] += 1
                else:
                    summary["pending_reviews"] += 1

                # Check for overdue
                deadline = datetime.fromisoformat(assignment["deadline"])
                if deadline < datetime.now() and assignment["status"] != "completed":
                    summary["overdue_reviews"] += 1

                # Reviewer load
                for review_type, reviewers in assignment["reviewers"].items():
                    for reviewer in reviewers:
                        summary["reviewer_load"][reviewer] = summary["reviewer_load"].get(reviewer, 0) + 1

                # Document type breakdown
                doc_type = assignment["document_type"]
                summary["documents_by_type"][doc_type] = summary["documents_by_type"].get(doc_type, 0) + 1

                # Complexity breakdown
                complexity = assignment["complexity"]
                summary["documents_by_complexity"][complexity] = summary["documents_by_complexity"].get(complexity, 0) + 1

            except Exception as e:
                print(f"Error reading review file {review_file}: {e}")

        return summary

def main():
    """Main execution function."""
    engine = ReviewAssignmentEngine()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "assign":
            print("Assigning reviews to new documents...")
            assignments = engine.assign_reviews()
            print(f"Assigned {len(assignments)} reviews")

        elif command == "summary":
            print("Generating review summary...")
            summary = engine.generate_review_summary()
            print(json.dumps(summary, indent=2))

        elif command == "scan":
            print("Scanning for new documents...")
            new_docs = engine.scan_for_new_documents()
            print(f"Found {len(new_docs)} documents needing review:")
            for doc in new_docs:
                print(f"  - {doc}")

        else:
            print(f"Unknown command: {command}")
            print("Available commands: assign, summary, scan")

    else:
        print("Review Assignment Engine")
        print("Usage: python review-assignment.py <command>")
        print("Commands:")
        print("  assign   - Assign reviews to new documents")
        print("  summary  - Generate review summary")
        print("  scan     - Scan for documents needing review")

if __name__ == "__main__":
    main()
```

### Automated Compliance Checking

```bash
#!/bin/bash
# docs/scripts/compliance-check.sh

set -euo pipefail

# Compliance checking script
DOCS_DIR="${DOCS_DIR:-docs}"
COMPLIANCE_CONFIG="${COMPLIANCE_CONFIG:-docs/quality-automation/compliance-rules.json}"
REPORT_FILE="${REPORT_FILE:-docs/quality-automation/compliance-report.json}"

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

# Compliance rules
check_compliance() {
    local file="$1"
    local errors=()
    local warnings=()

    log_info "Checking compliance for $file"

    # Read file content
    local content=$(cat "$file")

    # Check for required compliance markers
    if ! echo "$content" | grep -q "## Compliance Notes"; then
        warnings+=("Missing compliance notes section")
    fi

    # Check security compliance
    if ! echo "$content" | grep -qi "security"; then
        warnings+=("Document does not mention security considerations")
    fi

    # Check accessibility compliance
    if ! echo "$content" | grep -qi "accessibility\|wcag"; then
        warnings+=("Document does not mention accessibility requirements")
    fi

    # Check for privacy considerations
    if ! echo "$content" | grep -qi "privacy\|gdpr\|pii"; then
        warnings+=("Document does not mention privacy considerations")
    fi

    # Check data protection compliance
    if ! echo "$content" | grep -qi "data protection\|encryption"; then
        warnings+=("Document does not mention data protection")
    fi

    # Return results
    if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
        return 0
    else
        {
            printf '%s\n' "${errors[@]}"
            printf '%s\n' "${warnings[@]}"
        } > "/tmp/compliance_issues_$(basename "$file")"
        return 1
    fi
}

# Run compliance checks
run_compliance_checks() {
    local markdown_files=()
    while IFS= read -r -d '' file; do
        markdown_files+=("$file")
    done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)

    local total_files=${#markdown_files[@]}
    local compliant_files=0
    local non_compliant_files=0

    log_info "Running compliance checks on $total_files files"

    for file in "${markdown_files[@]}"; do
        if check_compliance "$file"; then
            ((compliant_files++))
            log_success "✓ $file"
        else
            ((non_compliant_files++))
            log_warning "⚠ $file"
        fi
    done

    # Generate report
    cat > "$REPORT_FILE" << EOF
{
  "compliance_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_files": $total_files,
  "compliant_files": $compliant_files,
  "non_compliant_files": $non_compliant_files,
  "compliance_rate": $((compliant_files * 100 / total_files))
}
EOF

    echo
    log_info "Compliance Summary:"
    echo "  Total files: $total_files"
    echo "  Compliant: $compliant_files"
    echo "  Non-compliant: $non_compliant_files"
    echo "  Compliance rate: $((compliant_files * 100 / total_files))%"

    return $non_compliant_files
}

# Main execution
main() {
    log_info "Starting compliance checks..."

    if ! run_compliance_checks; then
        log_error "Some files failed compliance checks"
        exit 1
    fi

    log_success "All compliance checks passed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Approval Workflow Automation

```yaml
# docs/quality-automation/approval-workflow.yml
name: Documentation Approval Workflow

on:
  pull_request:
    types: [opened, synchronize, labeled, unlabeled]
  push:
    branches: [main, develop]

jobs:
  quality-checks:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Setup tools
      run: |
        sudo apt-get update
        sudo apt-get install -y jq
        chmod +x docs/scripts/validate-documentation.sh
        chmod +x docs/scripts/compliance-check.sh

    - name: Run documentation validation
      run: ./docs/scripts/validate-documentation.sh --no-fail-on-error

    - name: Run compliance checks
      run: ./docs/scripts/compliance-check.sh || true

    - name: Generate quality report
      run: |
        jq -s '.[0] * .[1]' \
          docs/quality-automation/validation-report.json \
          docs/quality-automation/compliance-report.json > \
          docs/quality-automation/quality-report.json

    - name: Upload quality report
      uses: actions/upload-artifact@v3
      with:
        name: quality-report
        path: docs/quality-automation/quality-report.json

    - name: Check approval requirements
      id: approval-check
      run: |
        # Check if document meets quality criteria
        validation_result=$(jq '.failed_files == 0' docs/quality-automation/validation-report.json)
        compliance_result=$(jq '.compliance_rate >= 80' docs/quality-automation/compliance-report.json)

        if [[ "$validation_result" == "true" && "$compliance_result" == "true" ]]; then
          echo "approval-required=false" >> $GITHUB_OUTPUT
          echo "✅ Document meets quality criteria"
        else
          echo "approval-required=true" >> $GITHUB_OUTPUT
          echo "⚠️ Document requires manual review"
        fi

    - name: Request reviews if needed
      if: steps.approval-check.outputs.approval-required == 'true'
      uses: actions/github-script@v6
      with:
        script: |
          const { context } = require('@actions/github');
          const fs = require('fs');

          // Read quality report
          const report = JSON.parse(fs.readFileSync('docs/quality-automation/quality-report.json', 'utf8'));

          // Determine required reviewers based on document type
          const reviewers = ['tech-lead', 'qa-lead', 'product-owner'];

          // Request reviews
          await github.rest.pulls.requestReviewers({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.issue.number,
            reviewers: reviewers
          });

          // Add quality comment
          const comment = `
          ## Quality Review Required

          This document requires manual review due to:
          - Validation failures: ${report.failed_files} files
          - Compliance rate: ${report.compliance_rate}%

          Please review the [quality report](../actions/runs/${process.env.GITHUB_RUN_ID}) for details.
          `;

          await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });

    - name: Approve automatically if criteria met
      if: steps.approval-check.outputs.approval-required == 'false'
      uses: actions/github-script@v6
      with:
        script: |
          const { context } = require('@actions/github');

          // Add approval comment
          const comment = `
          ## Quality Check Passed ✅

          This document has passed all automated quality checks:
          - Validation: No failures
          - Compliance: High compliance rate

          Ready for merge.
          `;

          await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });

  peer-review:
    needs: quality-checks
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
    - name: Wait for reviews
      uses: actions/github-script@v6
      with:
        script: |
          const { context } = require('@actions/github');
          const core = require('@actions/core');

          // Check if required reviews are completed
          const reviews = await github.rest.pulls.listReviews({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.issue.number
          });

          const requiredReviewers = ['tech-lead', 'qa-lead'];
          const approvals = reviews.data.filter(review =>
            review.state === 'APPROVED' &&
            requiredReviewers.includes(review.user.login)
          );

          if (approvals.length >= requiredReviewers.length) {
            core.setOutput('reviews-complete', 'true');
          } else {
            core.setOutput('reviews-complete', 'false');
          }

    - name: Merge when ready
      if: steps.reviews.outputs.reviews-complete == 'true'
      uses: actions/github-script@v6
      with:
        script: |
          const { context } = require('@actions/github');

          await github.rest.pulls.merge({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.issue.number,
            merge_method: 'squash'
          });
```

## Review Tracking Dashboard

```javascript
// docs/quality-automation/review-dashboard.js
class ReviewDashboard {
    constructor() {
        this.apiUrl = '/api/review-data';
        this.dashboardElement = document.getElementById('review-dashboard');
        this.initialize();
    }

    async initialize() {
        await this.loadReviewData();
        this.renderDashboard();
        this.setupRealTimeUpdates();
    }

    async loadReviewData() {
        try {
            const response = await fetch(this.apiUrl);
            this.reviewData = await response.json();
        } catch (error) {
            console.error('Error loading review data:', error);
            this.reviewData = this.getMockData();
        }
    }

    getMockData() {
        return {
            pending_reviews: [
                {
                    id: 1,
                    title: 'User Authentication Flow',
                    type: 'user-story',
                    reviewers: ['tech-lead', 'product-owner'],
                    deadline: '2024-01-15',
                    status: 'pending',
                    priority: 'high'
                },
                {
                    id: 2,
                    title: 'Database Architecture Decision',
                    type: 'technical-decision',
                    reviewers: ['architect', 'tech-lead'],
                    deadline: '2024-01-12',
                    status: 'in_review',
                    priority: 'medium'
                }
            ],
            reviewer_stats: {
                'tech-lead': { assigned: 5, completed: 3, overdue: 1 },
                'product-owner': { assigned: 3, completed: 2, overdue: 0 },
                'architect': { assigned: 2, completed: 1, overdue: 0 }
            },
            metrics: {
                avg_review_time: 2.5,
                completion_rate: 0.85,
                overdue_rate: 0.15
            }
        };
    }

    renderDashboard() {
        this.dashboardElement.innerHTML = `
            <div class="review-dashboard">
                <div class="dashboard-header">
                    <h2>Documentation Review Dashboard</h2>
                    <div class="dashboard-actions">
                        <button onclick="dashboard.refreshDashboard()">Refresh</button>
                        <button onclick="dashboard.exportData()">Export</button>
                    </div>
                </div>

                <div class="dashboard-metrics">
                    ${this.renderMetrics()}
                </div>

                <div class="dashboard-content">
                    <div class="pending-reviews">
                        ${this.renderPendingReviews()}
                    </div>

                    <div class="reviewer-stats">
                        ${this.renderReviewerStats()}
                    </div>
                </div>
            </div>
        `;
    }

    renderMetrics() {
        const metrics = this.reviewData.metrics;
        return `
            <div class="metrics-grid">
                <div class="metric-card">
                    <h3>Average Review Time</h3>
                    <div class="metric-value">${metrics.avg_review_time} days</div>
                </div>
                <div class="metric-card">
                    <h3>Completion Rate</h3>
                    <div class="metric-value">${(metrics.completion_rate * 100).toFixed(0)}%</div>
                </div>
                <div class="metric-card">
                    <h3>Overdue Rate</h3>
                    <div class="metric-value">${(metrics.overdue_rate * 100).toFixed(0)}%</div>
                </div>
            </div>
        `;
    }

    renderPendingReviews() {
        const reviews = this.reviewData.pending_reviews;
        return `
            <div class="section">
                <h3>Pending Reviews</h3>
                <div class="review-list">
                    ${reviews.map(review => this.renderReviewItem(review)).join('')}
                </div>
            </div>
        `;
    }

    renderReviewItem(review) {
        const priorityClass = `priority-${review.priority}`;
        const statusClass = `status-${review.status}`;

        return `
            <div class="review-item ${priorityClass}">
                <div class="review-header">
                    <h4>${review.title}</h4>
                    <span class="review-type">${review.type}</span>
                </div>
                <div class="review-details">
                    <div class="review-meta">
                        <span class="review-deadline">Due: ${review.deadline}</span>
                        <span class="review-status ${statusClass}">${review.status}</span>
                    </div>
                    <div class="review-reviewers">
                        ${review.reviewers.map(reviewer => `<span class="reviewer-tag">${reviewer}</span>`).join('')}
                    </div>
                </div>
            </div>
        `;
    }

    renderReviewerStats() {
        const stats = this.reviewData.reviewer_stats;
        return `
            <div class="section">
                <h3>Reviewer Statistics</h3>
                <div class="reviewer-list">
                    ${Object.entries(stats).map(([reviewer, data]) => `
                        <div class="reviewer-stat">
                            <h4>${reviewer}</h4>
                            <div class="stat-item">
                                <span>Assigned:</span>
                                <span class="stat-value">${data.assigned}</span>
                            </div>
                            <div class="stat-item">
                                <span>Completed:</span>
                                <span class="stat-value">${data.completed}</span>
                            </div>
                            <div class="stat-item">
                                <span>Overdue:</span>
                                <span class="stat-value overdue">${data.overdue}</span>
                            </div>
                            <div class="completion-bar">
                                <div class="completion-progress" style="width: ${(data.completed / data.assigned * 100)}%"></div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    setupRealTimeUpdates() {
        // Set up WebSocket or polling for real-time updates
        setInterval(() => {
            this.loadReviewData();
            this.renderDashboard();
        }, 30000); // Update every 30 seconds
    }

    async refreshDashboard() {
        await this.loadReviewData();
        this.renderDashboard();
    }

    exportData() {
        const dataStr = JSON.stringify(this.reviewData, null, 2);
        const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);

        const exportFileDefaultName = `review-dashboard-${new Date().toISOString().split('T')[0]}.json`;

        const linkElement = document.createElement('a');
        linkElement.setAttribute('href', dataUri);
        linkElement.setAttribute('download', exportFileDefaultName);
        linkElement.click();
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new ReviewDashboard();
});
```

This review automation system provides comprehensive workflow automation, compliance checking, and real-time tracking of documentation reviews.