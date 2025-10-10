#!/bin/bash
# Coverage monitoring script for automated testing

set -euo pipefail

# Configuration
PROJECT_DIR="${PROJECT_DIR:-.}"
TEST_DIR="${TEST_DIR:-tests}"
REPORT_DIR="${REPORT_DIR:-reports/coverage}"
MIN_COVERAGE="${MIN_COVERAGE:-80}"

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

# Initialize coverage report
initialize_coverage_report() {
    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_DIR/coverage-summary.json" << EOF
{
  "coverage_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_tests": 0,
  "passed_tests": 0,
  "failed_tests": 0,
  "skipped_tests": 0,
  "overall_coverage": 0,
  "coverage_by_type": {
    "unit": 0,
    "integration": 0,
    "e2e": 0
  },
  "coverage_by_file": {},
  "trend_data": []
}
EOF
}

# Run tests and collect coverage
run_coverage_tests() {
    log_info "Running tests with coverage analysis..."

    # Create coverage directory
    mkdir -p "$REPORT_DIR"

    # Run unit tests with coverage
    log_info "Running unit tests..."
    if command -v pytest &> /dev/null; then
        if [ -d "$TEST_DIR/unit" ]; then
            pytest "$TEST_DIR/unit" --cov="$PROJECT_DIR" --cov-report=json:"$REPORT_DIR/unit-coverage.json" --cov-report=html:"$REPORT_DIR/unit-html" --cov-report=term --tb=short || log_warning "Unit tests completed with some failures"
        else
            log_warning "Unit test directory not found: $TEST_DIR/unit"
        fi
    else
        log_warning "pytest not found, skipping unit tests"
    fi

    # Run integration tests with coverage
    log_info "Running integration tests..."
    if command -v pytest &> /dev/null; then
        if [ -d "$TEST_DIR/integration" ]; then
            pytest "$TEST_DIR/integration" --cov="$PROJECT_DIR" --cov-report=json:"$REPORT_DIR/integration-coverage.json" --cov-append --cov-report=html:"$REPORT_DIR/integration-html" --cov-report=term --tb=short || log_warning "Integration tests completed with some failures"
        else
            log_warning "Integration test directory not found: $TEST_DIR/integration"
        fi
    fi

    # Run E2E tests (if available)
    log_info "Running E2E tests..."
    if [ -d "$TEST_DIR/e2e" ]; then
        if command -v pytest &> /dev/null; then
            pytest "$TEST_DIR/e2e" --junitxml="$REPORT_DIR/e2e-results.xml" --cov-report=html:"$REPORT_DIR/e2e-html" --cov-report=term --tb=short || log_warning "E2E tests completed with some failures"
        fi
    else
        log_warning "E2E test directory not found: $TEST_DIR/e2e"
    fi

    log_success "Test execution completed"
}

# Analyze coverage results
analyze_coverage() {
    log_info "Analyzing coverage results..."

    local total_coverage=0
    local unit_coverage=0
    local integration_coverage=0
    local e2e_coverage=0
    local coverage_by_file="{}"

    # Analyze unit test coverage
    if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
        unit_coverage=$(jq -r '.totals.percent_covered // 0' "$REPORT_DIR/unit-coverage.json" 2>/dev/null || echo "0")
        log_info "Unit test coverage: ${unit_coverage}%"
    else
        log_warning "Unit coverage report not found"
    fi

    # Analyze integration test coverage
    if [ -f "$REPORT_DIR/integration-coverage.json" ]; then
        integration_coverage=$(jq -r '.totals.percent_covered // 0' "$REPORT_DIR/integration-coverage.json" 2>/dev/null || echo "0")
        log_info "Integration test coverage: ${integration_coverage}%"
    else
        log_warning "Integration coverage report not found"
    fi

    # Calculate overall coverage (weighted average)
    if [ "$unit_coverage" -gt 0 ] || [ "$integration_coverage" -gt 0 ]; then
        total_coverage=$(( (unit_coverage * 2 + integration_coverage) / 3 ))
        log_info "Overall coverage: ${total_coverage}%"
    else
        log_warning "No coverage data available"
    fi

    # Generate coverage by file report
    if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
        coverage_by_file=$(jq '.files | to_entries | map({file: .key, coverage: .value.summary.percent_covered}) // []' "$REPORT_DIR/unit-coverage.json" 2>/dev/null || echo "[]")
    fi

    # Update coverage summary
    local summary_json
    if command -v jq &> /dev/null; then
        summary_json=$(jq \
            --arg total_coverage "$total_coverage" \
            --arg unit_coverage "$unit_coverage" \
            --arg integration_coverage "$integration_coverage" \
            --arg e2e_coverage "$e2e_coverage" \
            --argjson coverage_by_file "$coverage_by_file" \
            '.overall_coverage = ($total_coverage | tonumber) |
             .coverage_by_type.unit = ($unit_coverage | tonumber) |
             .coverage_by_type.integration = ($integration_coverage | tonumber) |
             .coverage_by_type.e2e = ($e2e_coverage | tonumber) |
             .coverage_by_file = $coverage_by_file' \
            "$REPORT_DIR/coverage-summary.json" 2>/dev/null || echo "{}")

        echo "$summary_json" > "$REPORT_DIR/coverage-summary.json"
    fi

    # Check if coverage meets minimum requirements
    if [ "$total_coverage" -ge "$MIN_COVERAGE" ]; then
        log_success "Coverage meets minimum requirement: ${total_coverage}% >= ${MIN_COVERAGE}%"
        return 0
    else
        log_error "Coverage below minimum requirement: ${total_coverage}% < ${MIN_COVERAGE}%"
        return 1
    fi
}

# Generate coverage report
generate_coverage_report() {
    log_info "Generating detailed coverage report..."

    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_DIR/coverage-report.md" << EOF
# Test Coverage Report

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Minimum Required Coverage: ${MIN_COVERAGE}%

## Coverage Summary

EOF

    if [ -f "$REPORT_DIR/coverage-summary.json" ]; then
        local overall_coverage
        local unit_coverage
        local integration_coverage

        if command -v jq &> /dev/null; then
            overall_coverage=$(jq -r '.overall_coverage // 0' "$REPORT_DIR/coverage-summary.json")
            unit_coverage=$(jq -r '.coverage_by_type.unit // 0' "$REPORT_DIR/coverage-summary.json")
            integration_coverage=$(jq -r '.coverage_by_type.integration // 0' "$REPORT_DIR/coverage-summary.json")
        else
            overall_coverage=0
            unit_coverage=0
            integration_coverage=0
        fi

        cat >> "$REPORT_DIR/coverage-report.md" << EOF
- **Overall Coverage**: ${overall_coverage}%
- **Unit Test Coverage**: ${unit_coverage}%
- **Integration Test Coverage**: ${integration_coverage}%

EOF

        # Add coverage status
        if [ "$overall_coverage" -ge "$MIN_COVERAGE" ]; then
            echo "✅ **Status**: PASSED - Coverage meets requirements" >> "$REPORT_DIR/coverage-report.md"
        else
            echo "❌ **Status**: FAILED - Coverage below requirements" >> "$REPORT_DIR/coverage-report.md"
        fi
    else
        echo "❌ **Status**: No coverage data available" >> "$REPORT_DIR/coverage-report.md"
    fi

    cat >> "$REPORT_DIR/coverage-report.md" << EOF

## Coverage by File

EOF

    # Add file-level coverage details
    if [ -f "$REPORT_DIR/unit-coverage.json" ] && command -v jq &> /dev/null; then
        jq -r '.files | to_entries | sort_by(-.value.summary.percent_covered) | .[] | "- **\(.key)**: \(.value.summary.percent_covered)%"' "$REPORT_DIR/unit-coverage.json" 2>/dev/null >> "$REPORT_DIR/coverage-report.md" || echo "No file coverage data available" >> "$REPORT_DIR/coverage-report.md"
    else
        echo "No file coverage data available" >> "$REPORT_DIR/coverage-report.md"
    fi

    cat >> "$REPORT_DIR/coverage-report.md" << EOF

## Coverage Reports

- [Unit Test HTML Report](unit-html/index.html)
- [Integration Test HTML Report](integration-html/index.html)
- [E2E Test HTML Report](e2e-html/index.html) (if available)

## Recommendations

EOF

    # Generate recommendations based on coverage
    if [ -f "$REPORT_DIR/coverage-summary.json" ] && command -v jq &> /dev/null; then
        local overall_coverage
        overall_coverage=$(jq -r '.overall_coverage // 0' "$REPORT_DIR/coverage-summary.json")

        if [ "$overall_coverage" -lt "$MIN_COVERAGE" ]; then
            cat >> "$REPORT_DIR/coverage-report.md" << EOF
- **Urgent**: Coverage is below minimum requirements. Add more tests to reach ${MIN_COVERAGE}% coverage.
EOF
        fi

        # Find files with low coverage
        if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
            local low_coverage_files
            low_coverage_files=$(jq -r '.files | to_entries | map(select(.value.summary.percent_covered < 80)) | .[] | "- \(.key) (\(.value.summary.percent_covered)%)"' "$REPORT_DIR/unit-coverage.json" 2>/dev/null || echo "")
            if [ -n "$low_coverage_files" ]; then
                echo "- **Low Coverage Files**: Consider adding tests for these files:" >> "$REPORT_DIR/coverage-report.md"
                echo "$low_coverage_files" >> "$REPORT_DIR/coverage-report.md"
            fi
        fi
    else
        echo "- Run tests to generate coverage data" >> "$REPORT_DIR/coverage-report.md"
    fi

    log_success "Coverage report generated: $REPORT_DIR/coverage-report.md"
}

# Quality gate enforcement
enforce_quality_gate() {
    log_info "Enforcing quality gates..."

    local gate_passed=true

    # Check coverage gate
    if [ -f "$REPORT_DIR/coverage-summary.json" ] && command -v jq &> /dev/null; then
        local overall_coverage
        overall_coverage=$(jq -r '.overall_coverage // 0' "$REPORT_DIR/coverage-summary.json")

        if [ "$overall_coverage" -lt "$MIN_COVERAGE" ]; then
            log_error "Coverage gate failed: ${overall_coverage}% < ${MIN_COVERAGE}%"
            gate_passed=false
        else
            log_success "Coverage gate passed: ${overall_coverage}% >= ${MIN_COVERAGE}%"
        fi
    else
        log_error "Coverage report not found or jq not available"
        gate_passed=false
    fi

    # Check test results gate (if pytest results are available)
    local pytest_results
    pytest_results=$(find "$REPORT_DIR" -name "*.xml" -o -name "pytest.log" | wc -l || echo "0")
    if [ "$pytest_results" -gt 0 ]; then
        # Could parse pytest results for failures here
        log_info "Test results found: $pytest_results result files"
    fi

    if [ "$gate_passed" = "true" ]; then
        log_success "All quality gates passed"
        return 0
    else
        log_error "Quality gates failed"
        return 1
    fi
}

# Main execution
main() {
    case "${1:-run}" in
        "run")
            initialize_coverage_report
            run_coverage_tests
            analyze_coverage || true
            generate_coverage_report
            enforce_quality_gate || true
            ;;
        "analyze")
            analyze_coverage || true
            generate_coverage_report
            ;;
        "report")
            generate_coverage_report
            ;;
        "gate")
            enforce_quality_gate
            ;;
        "init")
            initialize_coverage_report
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo
            echo "Commands:"
            echo "  run       Run tests and analyze coverage (default)"
            echo "  analyze   Analyze existing coverage results"
            echo "  report    Generate coverage report"
            echo "  gate      Enforce quality gates only"
            echo "  init      Initialize coverage report structure"
            echo "  help      Show this help message"
            echo
            echo "Environment Variables:"
            echo "  PROJECT_DIR     Project directory (default: .)"
            echo "  TEST_DIR        Test directory (default: tests)"
            echo "  REPORT_DIR      Coverage report directory (default: reports/coverage)"
            echo "  MIN_COVERAGE    Minimum coverage percentage (default: 80)"
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
    log_warning "jq not found - some features may not work properly"
fi

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi