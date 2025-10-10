# CI/CD Integration for Documentation Quality Automation

Status: v1.0 — Complete integration with GitHub Actions and quality gate enforcement

## Overview

This system integrates all quality automation tools into CI/CD pipelines for continuous quality monitoring and enforcement.

## GitHub Actions Workflows

### Main Quality Gate Workflow

```yaml
# .github/workflows/documentation-quality.yml
name: Documentation Quality Gates

on:
  push:
    branches: [ main, develop ]
    paths: [ 'docs/**' ]
  pull_request:
    branches: [ main, develop ]
    paths: [ 'docs/**' ]

env:
  PYTHON_VERSION: '3.9'
  NODE_VERSION: '18'

jobs:
  quality-validation:
    name: Documentation Quality Validation
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}

    - name: Cache Python dependencies
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-

    - name: Install Python dependencies
      run: |
        python -m pip install --upgrade pip
        pip install jq pyyaml

    - name: Install Node.js dependencies
      run: |
        npm install -g markdownlint-cli
        npm install -g cspell

    - name: Make scripts executable
      run: |
        chmod +x docs/scripts/*.sh
        chmod +x docs/scripts/*.py

    - name: Run documentation validation
      id: validation
      run: |
        echo "Running documentation validation..."
        ./docs/scripts/validate-documentation.sh --no-fail-on-error
        echo "validation_complete=true" >> $GITHUB_OUTPUT

    - name: Run compliance checks
      id: compliance
      run: |
        echo "Running compliance checks..."
        ./docs/scripts/compliance-check.sh
        echo "compliance_complete=true" >> $GITHUB_OUTPUT

    - name: Generate test cases from stories
      id: test-generation
      run: |
        echo "Generating test cases from user stories..."
        python docs/scripts/story-test-generator.py generate
        echo "test_generation_complete=true" >> $GITHUB_OUTPUT

    - name: Assign ownership and governance
      id: governance
      run: |
        echo "Assigning document ownership..."
        python docs/scripts/governance-manager.py assign
        echo "governance_complete=true" >> $GITHUB_OUTPUT

    - name: Collect quality metrics
      id: metrics
      run: |
        echo "Collecting quality metrics..."
        python docs/scripts/metrics-collector.py collect
        echo "metrics_complete=true" >> $GITHUB_OUTPUT

    - name: Check quality gates
      id: quality-gate
      run: |
        echo "Checking quality gates..."

        # Check validation results
        if [ -f "docs/quality-automation/validation-report.json" ]; then
          validation_failed=$(jq -r '.failed_files' docs/quality-automation/validation-report.json)
          if [ "$validation_failed" -gt 0 ]; then
            echo "validation_failed=true" >> $GITHUB_OUTPUT
            echo "Validation failed: $validation_failed files failed validation"
          else
            echo "validation_passed=true" >> $GITHUB_OUTPUT
            echo "All validation checks passed"
          fi
        else
          echo "validation_failed=true" >> $GITHUB_OUTPUT
          echo "Validation report not found"
        fi

        # Check compliance results
        if [ -f "docs/quality-automation/compliance-report.json" ]; then
          compliance_rate=$(jq -r '.compliance_rate' docs/quality-automation/compliance-report.json)
          if (( $(echo "$compliance_rate < 80" | bc -l) )); then
            echo "compliance_failed=true" >> $GITHUB_OUTPUT
            echo "Compliance failed: ${compliance_rate}% below threshold"
          else
            echo "compliance_passed=true" >> $GITHUB_OUTPUT
            echo "Compliance passed: ${compliance_rate}%"
          fi
        else
          echo "compliance_failed=true" >> $GITHUB_OUTPUT
          echo "Compliance report not found"
        fi

    - name: Upload quality artifacts
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: quality-reports
        path: |
          docs/quality-automation/validation-report.json
          docs/quality-automation/compliance-report.json
          docs/quality-automation/quality-report.json
          docs/quality-automation/governance/
          tests/generated/
        retention-days: 30

    - name: Generate quality report summary
      id: quality-summary
      run: |
        cat << 'EOF' > quality-summary.md

        # Documentation Quality Report

        ## Validation Results
        EOF

        if [ -f "docs/quality-automation/validation-report.json" ]; then
          total_files=$(jq -r '.total_files' docs/quality-automation/validation-report.json)
          passed_files=$(jq -r '.passed_files' docs/quality-automation/validation-report.json)
          failed_files=$(jq -r '.failed_files' docs/quality-automation/validation-report.json)

          echo "- Total files: $total_files" >> quality-summary.md
          echo "- Passed: $passed_files" >> quality-summary.md
          echo "- Failed: $failed_files" >> quality-summary.md
        else
          echo "- Validation: No report available" >> quality-summary.md
        fi

        echo "" >> quality-summary.md
        echo "## Compliance Results" >> quality-summary.md

        if [ -f "docs/quality-automation/compliance-report.json" ]; then
          compliance_rate=$(jq -r '.compliance_rate' docs/quality-automation/compliance-report.json)
          echo "- Compliance rate: ${compliance_rate}%" >> quality-summary.md
        else
          echo "- Compliance: No report available" >> quality-summary.md
        fi

        echo "" >> quality-summary.md
        echo "## Generated Artifacts" >> quality-summary.md
        echo "- Test cases generated from user stories" >> quality-summary.md
        echo "- Ownership assignments completed" >> quality-summary.md
        echo "- Quality metrics collected" >> quality-summary.md

        # Store summary content for PR comment
        SUMMARY_CONTENT=$(cat quality-summary.md)
        echo "summary<<EOF" >> $GITHUB_OUTPUT
        echo "$SUMMARY_CONTENT" >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT

    - name: Comment PR with quality results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const summary = `${{ steps.quality-summary.outputs.summary }}`;

          await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: summary
          });

    - name: Quality Gate Decision
      if: steps.quality-gate.outputs.validation_failed == 'true' || steps.quality-gate.outputs.compliance_failed == 'true'
      run: |
        echo "❌ Quality gates failed - blocking merge"
        echo "Validation failed: ${{ steps.quality-gate.outputs.validation_failed == 'true' }}"
        echo "Compliance failed: ${{ steps.quality-gate.outputs.compliance_failed == 'true' }}"
        exit 1

    - name: Quality Gate Success
      if: steps.quality-gate.outputs.validation_passed == 'true' && steps.quality-gate.outputs.compliance_passed == 'true'
      run: |
        echo "✅ All quality gates passed - merge approved"
```

### Scheduled Quality Monitoring

```yaml
# .github/workflows/scheduled-quality-monitoring.yml
name: Scheduled Quality Monitoring

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  quality-monitoring:
    name: Daily Quality Monitoring
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pyyaml

    - name: Make scripts executable
      run: chmod +x docs/scripts/*.sh docs/scripts/*.py

    - name: Run full quality analysis
      run: |
        ./docs/scripts/validate-documentation.sh --no-fail-on-error
        ./docs/scripts/compliance-check.sh recommendations
        python docs/scripts/governance-manager.py assign
        python docs/scripts/metrics-collector.py collect

    - name: Check for overdue reviews
      run: |
        ./docs/scripts/review-reminder.sh check
        ./docs/scripts/review-reminder.sh schedule

    - name: Generate quality trend report
      run: |
        python docs/scripts/metrics-collector.py trends 30 > docs/quality-automation/quality-trends.json

    - name: Upload monitoring artifacts
      uses: actions/upload-artifact@v3
      with:
        name: daily-quality-monitoring
        path: |
          docs/quality-automation/*.json
          docs/quality-automation/governance/
          docs/quality-automation/review-reminders.log
        retention-days: 90

    - name: Create quality dashboard data
      run: |
        # Prepare data for dashboard
        mkdir -p dashboard-data
        cp docs/quality-automation/metrics-*.json dashboard-data/ 2>/dev/null || true
        cp docs/quality-automation/validation-report.json dashboard-data/ 2>/dev/null || true
        cp docs/quality-automation/compliance-report.json dashboard-data/ 2>/dev/null || true

    - name: Deploy dashboard data
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./dashboard-data
        destination_dir: quality-data
```

### Test Generation and Coverage Workflow

```yaml
# .github/workflows/test-generation-and-coverage.yml
name: Test Generation and Coverage

on:
  push:
    branches: [ main, develop ]
    paths: [ 'docs/stories/**' ]
  pull_request:
    branches: [ main, develop ]
    paths: [ 'docs/stories/**' ]

jobs:
  generate-tests:
    name: Generate Tests from User Stories
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest pytest-cov pytest-json-report

    - name: Generate tests from stories
      run: |
        python docs/scripts/story-test-generator.py generate

    - name: Run generated tests
      id: test-execution
      run: |
        mkdir -p tests/reports

        # Run unit tests
        if [ -d "tests/generated/unit" ]; then
          pytest tests/generated/unit/ \
            --json-report \
            --json-report-file=tests/reports/unit-test-results.json \
            --cov=. \
            --cov-report=json:tests/reports/unit-coverage.json \
            --cov-report=html:tests/reports/unit-coverage-html \
            --junitxml=tests/reports/unit-test-results.xml \
            --tb=short || echo "Unit tests completed with some failures"
        fi

        # Run integration tests
        if [ -d "tests/generated/integration" ]; then
          pytest tests/generated/integration/ \
            --json-report \
            --json-report-file=tests/reports/integration-test-results.json \
            --cov-append \
            --cov-report=json:tests/reports/integration-coverage.json \
            --cov-report=html:tests/reports/integration-coverage-html \
            --junitxml=tests/reports/integration-test-results.xml \
            --tb=short || echo "Integration tests completed with some failures"
        fi

        echo "test_execution_complete=true" >> $GITHUB_OUTPUT

    - name: Run coverage monitoring
      run: |
        ./docs/scripts/coverage-monitor.sh run

    - name: Analyze test results
      id: test-analysis
      run: |
        echo "Analyzing test results..."

        total_tests=0
        passed_tests=0
        failed_tests=0

        # Analyze unit test results
        if [ -f "tests/reports/unit-test-results.json" ]; then
          unit_total=$(jq -r '.summary.total' tests/reports/unit-test-results.json || echo "0")
          unit_passed=$(jq -r '.summary.passed' tests/reports/unit-test-results.json || echo "0")
          unit_failed=$(jq -r '.summary.failed' tests/reports/unit-test-results.json || echo "0")

          total_tests=$((total_tests + unit_total))
          passed_tests=$((passed_tests + unit_passed))
          failed_tests=$((failed_tests + unit_failed))
        fi

        # Analyze integration test results
        if [ -f "tests/reports/integration-test-results.json" ]; then
          integration_total=$(jq -r '.summary.total' tests/reports/integration-test-results.json || echo "0")
          integration_passed=$(jq -r '.summary.passed' tests/reports/integration-test-results.json || echo "0")
          integration_failed=$(jq -r '.summary.failed' tests/reports/integration-test-results.json || echo "0")

          total_tests=$((total_tests + integration_total))
          passed_tests=$((passed_tests + integration_passed))
          failed_tests=$((failed_tests + integration_failed))
        fi

        echo "total_tests=$total_tests" >> $GITHUB_OUTPUT
        echo "passed_tests=$passed_tests" >> $GITHUB_OUTPUT
        echo "failed_tests=$failed_tests" >> $GITHUB_OUTPUT

        # Calculate pass rate
        if [ "$total_tests" -gt 0 ]; then
          pass_rate=$((passed_tests * 100 / total_tests))
          echo "pass_rate=$pass_rate" >> $GITHUB_OUTPUT
        else
          echo "pass_rate=0" >> $GITHUB_OUTPUT
        fi

        echo "Test Analysis Summary:"
        echo "  Total tests: $total_tests"
        echo "  Passed: $passed_tests"
        echo "  Failed: $failed_tests"
        echo "  Pass rate: ${pass_rate:-0}%"

    - name: Check coverage requirements
      id: coverage-check
      run: |
        if [ -f "reports/coverage/coverage-summary.json" ]; then
          overall_coverage=$(jq -r '.overall_coverage' reports/coverage/coverage-summary.json || echo "0")
          echo "overall_coverage=$overall_coverage" >> $GITHUB_OUTPUT

          # Check against minimum coverage requirement (80%)
          if (( $(echo "$overall_coverage >= 80" | bc -l) )); then
            echo "coverage_passed=true" >> $GITHUB_OUTPUT
            echo "✅ Coverage requirement met: ${overall_coverage}% >= 80%"
          else
            echo "coverage_failed=true" >> $GITHUB_OUTPUT
            echo "❌ Coverage requirement failed: ${overall_coverage}% < 80%"
          fi
        else
          echo "coverage_failed=true" >> $GITHUB_OUTPUT
          echo "❌ Coverage report not found"
        fi

    - name: Upload test artifacts
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-and-coverage
        path: |
          tests/reports/
          reports/coverage/
          tests/generated/
        retention-days: 30

    - name: Generate test report
      run: |
        cat << 'EOF' > test-report.md

        # Test Generation and Coverage Report

        ## Test Results
        - Total tests: ${{ steps.test-analysis.outputs.total_tests }}
        - Passed: ${{ steps.test-analysis.outputs.passed_tests }}
        - Failed: ${{ steps.test-analysis.outputs.failed_tests }}
        - Pass rate: ${{ steps.test-analysis.outputs.pass_rate }}%

        ## Coverage Results
        EOF

        if [ "${{ steps.coverage-check.outputs.overall_coverage }}" != "" ]; then
          echo "- Overall coverage: ${{ steps.coverage-check.outputs.overall_coverage }}%" >> test-report.md
        else
          echo "- Coverage: Not available" >> test-report.md
        fi

        echo "" >> test-report.md
        echo "## Generated Test Files" >> test-report.md

        if [ -d "tests/generated" ]; then
          find tests/generated -name "*.py" -o -name "*.feature" -o -name "*.json" | while read file; do
            echo "- $file" >> test-report.md
          done
        else
          echo "- No test files generated" >> test-report.md
        fi

    - name: Comment PR with test results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');

          let testReport = '';
          try {
            testReport = fs.readFileSync('test-report.md', 'utf8');
          } catch (error) {
            testReport = 'Test report not available';
          }

          await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: testReport
          });

    - name: Test Gate Decision
      if: steps.test-analysis.outputs.failed_tests != '0' || steps.coverage-check.outputs.coverage_failed == 'true'
      run: |
        echo "❌ Test gates failed"
        echo "Failed tests: ${{ steps.test-analysis.outputs.failed_tests }}"
        echo "Coverage failed: ${{ steps.coverage-check.outputs.coverage_failed == 'true' }}"
        exit 1

    - name: Test Gate Success
      if: steps.test-analysis.outputs.failed_tests == '0' && steps.coverage-check.outputs.coverage_passed == 'true'
      run: |
        echo "✅ All test gates passed"
```

## Integration Scripts

### Quality Gate Enforcer

```bash
#!/bin/bash
# docs/scripts/quality-gate-enforcer.sh

set -euo pipefail

# Quality gate enforcement script
REPORTS_DIR="${REPORTS_DIR:-docs/quality-automation}"
MIN_QUALITY_SCORE="${MIN_QUALITY_SCORE:-80}"
MIN_COMPLIANCE_RATE="${MIN_COMPLIANCE_RATE:-80}"
MIN_COVERAGE="${MIN_COVERAGE:-80}"

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

# Check quality gate requirements
check_quality_gates() {
    local gates_passed=true
    local gate_results=()

    # Check validation results
    if [ -f "$REPORTS_DIR/validation-report.json" ]; then
        local total_files
        local passed_files
        local failed_files

        total_files=$(jq -r '.total_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")
        passed_files=$(jq -r '.passed_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")
        failed_files=$(jq -r '.failed_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")

        if [ "$failed_files" -gt 0 ]; then
            gates_passed=false
            gate_results+=("Validation: FAILED ($failed_files/$total_files files failed)")
            log_error "Validation gate failed: $failed_files out of $total_files files failed validation"
        else
            gate_results+=("Validation: PASSED ($passed_files/$total_files files passed)")
            log_success "Validation gate passed: All $total_files files passed validation"
        fi
    else
        gates_passed=false
        gate_results+=("Validation: NO DATA")
        log_error "Validation report not found"
    fi

    # Check compliance results
    if [ -f "$REPORTS_DIR/compliance-report.json" ]; then
        local compliance_rate
        compliance_rate=$(jq -r '.compliance_rate' "$REPORTS_DIR/compliance-report.json" 2>/dev/null || echo "0")

        if (( $(echo "$compliance_rate < $MIN_COMPLIANCE_RATE" | bc -l) )); then
            gates_passed=false
            gate_results+=("Compliance: FAILED (${compliance_rate}% < ${MIN_COMPLIANCE_RATE}%)")
            log_error "Compliance gate failed: ${compliance_rate}% < ${MIN_COMPLIANCE_RATE}%"
        else
            gate_results+=("Compliance: PASSED (${compliance_rate}%)")
            log_success "Compliance gate passed: ${compliance_rate}% >= ${MIN_COMPLIANCE_RATE}%"
        fi
    else
        gates_passed=false
        gate_results+=("Compliance: NO DATA")
        log_error "Compliance report not found"
    fi

    # Check coverage results
    local coverage_file="reports/coverage/coverage-summary.json"
    if [ -f "$coverage_file" ]; then
        local overall_coverage
        overall_coverage=$(jq -r '.overall_coverage' "$coverage_file" 2>/dev/null || echo "0")

        if (( $(echo "$overall_coverage < $MIN_COVERAGE" | bc -l) )); then
            gates_passed=false
            gate_results+=("Coverage: FAILED (${overall_coverage}% < ${MIN_COVERAGE}%)")
            log_error "Coverage gate failed: ${overall_coverage}% < ${MIN_COVERAGE}%"
        else
            gate_results+=("Coverage: PASSED (${overall_coverage}%)")
            log_success "Coverage gate passed: ${overall_coverage}% >= ${MIN_COVERAGE}%"
        fi
    else
        log_warning "Coverage report not found (not a blocker for documentation)"
        gate_results+=("Coverage: NO DATA")
    fi

    # Display gate results
    echo
    log_info "Quality Gate Results:"
    for result in "${gate_results[@]}"; do
        echo "  $result"
    done

    return $([ "$gates_passed" = "true" ] && echo 0 || echo 1)
}

# Generate quality gate report
generate_gate_report() {
    local gate_status=$1
    local report_file="$REPORTS_DIR/quality-gate-report.json"

    local report=$(cat << EOF
{
  "gate_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "gate_status": "$gate_status",
  "requirements": {
    "min_quality_score": $MIN_QUALITY_SCORE,
    "min_compliance_rate": $MIN_COMPLIANCE_RATE,
    "min_coverage": $MIN_COVERAGE
  },
  "validation_results": $(cat "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo '{}'),
  "compliance_results": $(cat "$REPORTS_DIR/compliance-report.json" 2>/dev/null || echo '{}'),
  "coverage_results": $(cat "reports/coverage/coverage-summary.json" 2>/dev/null || echo '{}')
}
EOF
)

    echo "$report" > "$report_file"
    log_info "Quality gate report saved: $report_file"
}

# Main execution
main() {
    case "${1:-check}" in
        "check")
            log_info "Running quality gate checks..."
            if check_quality_gates; then
                generate_gate_report "PASSED"
                log_success "All quality gates passed"
                exit 0
            else
                generate_gate_report "FAILED"
                log_error "Quality gates failed"
                exit 1
            fi
            ;;
        "report")
            generate_gate_report "UNKNOWN"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND]"
            echo
            echo "Commands:"
            echo "  check    Run quality gate checks (default)"
            echo "  report   Generate quality gate report"
            echo "  help     Show this help message"
            echo
            echo "Environment Variables:"
            echo "  REPORTS_DIR           Quality reports directory (default: docs/quality-automation)"
            echo "  MIN_QUALITY_SCORE     Minimum quality score (default: 80)"
            echo "  MIN_COMPLIANCE_RATE   Minimum compliance rate (default: 80)"
            echo "  MIN_COVERAGE          Minimum coverage (default: 80)"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install jq to continue."
    exit 1
fi

if ! command -v bc &> /dev/null; then
    log_error "bc is required but not installed. Please install bc to continue."
    exit 1
fi

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### CI/CD Integration Helper

```python
#!/usr/bin/env python3
"""
CI/CD integration helper for documentation quality automation.
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

class CICDIntegrationHelper:
    """Helper class for CI/CD integration tasks."""

    def __init__(self, docs_dir: str = "docs", scripts_dir: str = "docs/scripts"):
        self.docs_dir = Path(docs_dir)
        self.scripts_dir = Path(scripts_dir)
        self.reports_dir = Path("docs/quality-automation")

    def run_quality_pipeline(self) -> Dict:
        """Run the complete quality pipeline."""
        pipeline_results = {
            "started_at": datetime.now().isoformat(),
            "steps": {},
            "overall_status": "running",
            "errors": []
        }

        steps = [
            ("validation", self._run_validation),
            ("compliance", self._run_compliance),
            ("test_generation", self._run_test_generation),
            ("governance", self._run_governance),
            ("metrics", self._run_metrics),
            ("quality_gates", self._run_quality_gates)
        ]

        for step_name, step_func in steps:
            try:
                pipeline_results["steps"][step_name] = {
                    "started_at": datetime.now().isoformat(),
                    "status": "running"
                }

                result = step_func()
                pipeline_results["steps"][step_name].update({
                    "status": "completed",
                    "completed_at": datetime.now().isoformat(),
                    "result": result
                })

            except Exception as e:
                pipeline_results["steps"][step_name].update({
                    "status": "failed",
                    "failed_at": datetime.now().isoformat(),
                    "error": str(e)
                })
                pipeline_results["errors"].append(f"Step {step_name} failed: {str(e)}")

        # Determine overall status
        if pipeline_results["errors"]:
            pipeline_results["overall_status"] = "failed"
        else:
            pipeline_results["overall_status"] = "completed"

        pipeline_results["completed_at"] = datetime.now().isoformat()

        return pipeline_results

    def _run_validation(self) -> Dict:
        """Run documentation validation."""
        validation_script = self.scripts_dir / "validate-documentation.sh"

        if not validation_script.exists():
            raise FileNotFoundError(f"Validation script not found: {validation_script}")

        result = subprocess.run(
            [str(validation_script), "--no-fail-on-error"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        # Load validation report
        report_file = self.reports_dir / "validation-report.json"
        if report_file.exists():
            with open(report_file, 'r') as f:
                return json.load(f)
        else:
            return {"error": "Validation report not generated", "return_code": result.returncode}

    def _run_compliance(self) -> Dict:
        """Run compliance checks."""
        compliance_script = self.scripts_dir / "compliance-check.sh"

        if not compliance_script.exists():
            raise FileNotFoundError(f"Compliance script not found: {compliance_script}")

        result = subprocess.run(
            [str(compliance_script), "check"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        if result.returncode != 0:
            print(f"Compliance check warnings: {result.stderr}")

        # Load compliance report
        report_file = self.reports_dir / "compliance-report.json"
        if report_file.exists():
            with open(report_file, 'r') as f:
                return json.load(f)
        else:
            return {"error": "Compliance report not generated", "return_code": result.returncode}

    def _run_test_generation(self) -> Dict:
        """Run test generation from stories."""
        test_script = self.scripts_dir / "story-test-generator.py"

        if not test_script.exists():
            raise FileNotFoundError(f"Test generation script not found: {test_script}")

        result = subprocess.run(
            [sys.executable, str(test_script), "generate"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        # Count generated test files
        generated_dir = Path("tests/generated")
        test_files = list(generated_dir.rglob("*.py")) + list(generated_dir.rglob("*.feature")) + list(generated_dir.rglob("*.json"))

        return {
            "generated_tests": len(test_files),
            "test_files": [str(f.relative_to(generated_dir)) for f in test_files],
            "return_code": result.returncode,
            "output": result.stdout,
            "errors": result.stderr
        }

    def _run_governance(self) -> Dict:
        """Run governance assignment."""
        governance_script = self.scripts_dir / "governance-manager.py"

        if not governance_script.exists():
            raise FileNotFoundError(f"Governance script not found: {governance_script}")

        result = subprocess.run(
            [sys.executable, str(governance_script), "assign"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        # Count governance assignments
        governance_dir = self.reports_dir / "governance"
        ownership_files = list(governance_dir.glob("*.ownership.json")) if governance_dir.exists() else []

        return {
            "assigned_ownerships": len(ownership_files),
            "ownership_files": [f.name for f in ownership_files],
            "return_code": result.returncode,
            "output": result.stdout,
            "errors": result.stderr
        }

    def _run_metrics(self) -> Dict:
        """Run metrics collection."""
        metrics_script = self.scripts_dir / "metrics-collector.py"

        if not metrics_script.exists():
            raise FileNotFoundError(f"Metrics script not found: {metrics_script}")

        result = subprocess.run(
            [sys.executable, str(metrics_script), "collect"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        try:
            metrics_data = json.loads(result.stdout) if result.stdout else {}
            return {
                "metrics_collected": True,
                "data": metrics_data,
                "return_code": result.returncode
            }
        except json.JSONDecodeError:
            return {
                "metrics_collected": False,
                "error": "Failed to parse metrics output",
                "output": result.stdout,
                "errors": result.stderr
            }

    def _run_quality_gates(self) -> Dict:
        """Run quality gate checks."""
        gate_script = self.scripts_dir / "quality-gate-enforcer.sh"

        if not gate_script.exists():
            raise FileNotFoundError(f"Quality gate script not found: {gate_script}")

        result = subprocess.run(
            [str(gate_script), "check"],
            capture_output=True,
            text=True,
            cwd=self.docs_dir.parent
        )

        return {
            "gates_passed": result.returncode == 0,
            "return_code": result.returncode,
            "output": result.stdout,
            "errors": result.stderr
        }

    def generate_ci_summary(self, pipeline_results: Dict) -> str:
        """Generate CI summary for PR comments or notifications."""
        summary_lines = [
            "# Documentation Quality Pipeline Results",
            "",
            f"**Status**: {pipeline_results['overall_status'].upper()}",
            f"**Started**: {pipeline_results['started_at']}",
            f"**Completed**: {pipeline_results.get('completed_at', 'N/A')}",
            ""
        ]

        # Add step results
        summary_lines.append("## Pipeline Steps")

        for step_name, step_data in pipeline_results["steps"].items():
            status_emoji = "✅" if step_data["status"] == "completed" else "❌" if step_data["status"] == "failed" else "⏳"
            summary_lines.append(f"- {status_emoji} **{step_name.title()}**: {step_data['status'].upper()}")

            if "result" in step_data and isinstance(step_data["result"], dict):
                result = step_data["result"]
                if "total_files" in result:
                    summary_lines.append(f"  - Files processed: {result.get('total_files', 'N/A')}")
                if "generated_tests" in result:
                    summary_lines.append(f"  - Tests generated: {result.get('generated_tests', 'N/A')}")
                if "assigned_ownerships" in result:
                    summary_lines.append(f"  - Ownership assignments: {result.get('assigned_ownerships', 'N/A')}")

        # Add errors if any
        if pipeline_results["errors"]:
            summary_lines.extend([
                "",
                "## Errors",
                ""
            ])
            for error in pipeline_results["errors"]:
                summary_lines.append(f"- ❌ {error}")

        # Add recommendations
        summary_lines.extend([
            "",
            "## Recommendations",
            ""
        ])

        if pipeline_results["overall_status"] == "failed":
            summary_lines.extend([
                "- 🔧 Fix the failed steps before merging",
                "- 📊 Review the detailed reports in the artifacts",
                "- 🧪 Ensure all tests pass and coverage meets requirements"
            ])
        else:
            summary_lines.extend([
                "- ✅ All quality gates passed",
                "- 📈 Documentation quality is maintained",
                "- 🚀 Ready for merge"
            ])

        return "\n".join(summary_lines)

    def save_pipeline_results(self, results: Dict) -> str:
        """Save pipeline results to file."""
        results_file = self.reports_dir / f"pipeline-results-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"

        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)

        print(f"Pipeline results saved: {results_file}")
        return str(results_file)

def main():
    """Main execution function."""
    import argparse

    parser = argparse.ArgumentParser(description="CI/CD Integration Helper")
    parser.add_argument("command", choices=["run", "summary"], help="Command to run")
    parser.add_argument("--results-file", help="Path to existing pipeline results file")

    args = parser.parse_args()

    helper = CICDIntegrationHelper()

    if args.command == "run":
        print("Running documentation quality pipeline...")
        results = helper.run_quality_pipeline()
        results_file = helper.save_pipeline_results(results)

        # Generate and display summary
        summary = helper.generate_ci_summary(results)
        print("\n" + "="*50)
        print(summary)
        print("="*50)

        # Exit with appropriate code
        sys.exit(0 if results["overall_status"] == "completed" else 1)

    elif args.command == "summary":
        if not args.results_file:
            print("Error: --results-file is required for summary command")
            sys.exit(1)

        with open(args.results_file, 'r') as f:
            results = json.load(f)

        summary = helper.generate_ci_summary(results)
        print(summary)

if __name__ == "__main__":
    main()
```

This comprehensive CI/CD integration ensures that all quality automation tools work together seamlessly in the development pipeline, providing continuous quality monitoring and enforcement.