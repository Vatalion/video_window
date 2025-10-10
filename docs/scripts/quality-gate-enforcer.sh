#!/bin/bash
# Quality gate enforcement script for CI/CD integration

set -euo pipefail

# Configuration
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

# Check quality gate requirements
check_quality_gates() {
    local gates_passed=true
    local gate_results=()

    # Ensure reports directory exists
    mkdir -p "$REPORTS_DIR"

    # Check validation results
    if [ -f "$REPORTS_DIR/validation-report.json" ]; then
        local total_files
        local passed_files
        local failed_files

        if command -v jq &> /dev/null; then
            total_files=$(jq -r '.total_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")
            passed_files=$(jq -r '.passed_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")
            failed_files=$(jq -r '.failed_files' "$REPORTS_DIR/validation-report.json" 2>/dev/null || echo "0")
        else
            log_warning "jq not available - skipping detailed validation analysis"
            total_files=0
            passed_files=0
            failed_files=0
        fi

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
        if command -v jq &> /dev/null && command -v bc &> /dev/null; then
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
            log_warning "jq or bc not available - skipping compliance analysis"
            gate_results+=("Compliance: SKIPPED (tools not available)")
        fi
    else
        gates_passed=false
        gate_results+=("Compliance: NO DATA")
        log_error "Compliance report not found"
    fi

    # Check coverage results (non-blocking for documentation)
    local coverage_file="reports/coverage/coverage-summary.json"
    if [ -f "$coverage_file" ]; then
        local overall_coverage
        if command -v jq &> /dev/null && command -v bc &> /dev/null; then
            overall_coverage=$(jq -r '.overall_coverage' "$coverage_file" 2>/dev/null || echo "0")

            if (( $(echo "$overall_coverage < $MIN_COVERAGE" | bc -l) )); then
                gate_results+=("Coverage: FAILED (${overall_coverage}% < ${MIN_COVERAGE}%)")
                log_error "Coverage gate failed: ${overall_coverage}% < ${MIN_COVERAGE}%"
                # Note: Coverage failure doesn't block documentation gates
            else
                gate_results+=("Coverage: PASSED (${overall_coverage}%)")
                log_success "Coverage gate passed: ${overall_coverage}% >= ${MIN_COVERAGE}%"
            fi
        else
            log_warning "jq or bc not available - skipping coverage analysis"
            gate_results+=("Coverage: SKIPPED (tools not available)")
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
    local gate_status="$1"
    local report_file="$REPORTS_DIR/quality-gate-report.json"

    # Create report data
    local validation_data="{}"
    local compliance_data="{}"
    local coverage_data="{}"

    if [ -f "$REPORTS_DIR/validation-report.json" ] && command -v jq &> /dev/null; then
        validation_data=$(cat "$REPORTS_DIR/validation-report.json")
    fi

    if [ -f "$REPORTS_DIR/compliance-report.json" ] && command -v jq &> /dev/null; then
        compliance_data=$(cat "$REPORTS_DIR/compliance-report.json")
    fi

    if [ -f "reports/coverage/coverage-summary.json" ] && command -v jq &> /dev/null; then
        coverage_data=$(cat "reports/coverage/coverage-summary.json")
    fi

    # Generate JSON report
    local report
    if command -v jq &> /dev/null; then
        report=$(jq -n \
            --arg gate_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg gate_status "$gate_status" \
            --argjson min_quality_score "$MIN_QUALITY_SCORE" \
            --argjson min_compliance_rate "$MIN_COMPLIANCE_RATE" \
            --argjson min_coverage "$MIN_COVERAGE" \
            --argjson validation_results "$validation_data" \
            --argjson compliance_results "$compliance_data" \
            --argjson coverage_results "$coverage_data" \
            '{
              gate_timestamp: $gate_timestamp,
              gate_status: $gate_status,
              requirements: {
                min_quality_score: $min_quality_score,
                min_compliance_rate: $min_compliance_rate,
                min_coverage: $min_coverage
              },
              validation_results: $validation_results,
              compliance_results: $compliance_results,
              coverage_results: $coverage_results
            }')
    else
        # Fallback without jq
        report=$(cat << EOF
{
  "gate_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "gate_status": "$gate_status",
  "requirements": {
    "min_quality_score": $MIN_QUALITY_SCORE,
    "min_compliance_rate": $MIN_COMPLIANCE_RATE,
    "min_coverage": $MIN_COVERAGE
  },
  "validation_results": $validation_data,
  "compliance_results": $compliance_data,
  "coverage_results": $coverage_data
}
EOF
)
    fi

    echo "$report" > "$report_file"
    log_info "Quality gate report saved: $report_file"
}

# Check for available tools
check_dependencies() {
    local missing_tools=()

    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
        log_warning "jq is not available - some features will be limited"
    fi

    if ! command -v bc &> /dev/null; then
        missing_tools+=("bc")
        log_warning "bc is not available - numeric comparisons will be limited"
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_info "Missing tools: ${missing_tools[*]}"
        log_info "Install missing tools for full functionality:"
        echo "  Ubuntu/Debian: sudo apt-get install jq bc"
        echo "  macOS: brew install jq"
        echo "  CentOS/RHEL: sudo yum install jq bc"
    fi
}

# Main execution
main() {
    case "${1:-check}" in
        "check")
            log_info "Running quality gate checks..."
            check_dependencies
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
            check_dependencies
            generate_gate_report "UNKNOWN"
            ;;
        "deps")
            check_dependencies
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND]"
            echo
            echo "Commands:"
            echo "  check    Run quality gate checks (default)"
            echo "  report   Generate quality gate report"
            echo "  deps     Check for required dependencies"
            echo "  help     Show this help message"
            echo
            echo "Environment Variables:"
            echo "  REPORTS_DIR           Quality reports directory (default: docs/quality-automation)"
            echo "  MIN_QUALITY_SCORE     Minimum quality score (default: 80)"
            echo "  MIN_COMPLIANCE_RATE   Minimum compliance rate (default: 80)"
            echo "  MIN_COVERAGE          Minimum coverage (default: 80)"
            echo
            echo "Examples:"
            echo "  $0 check                    # Run all quality gate checks"
            echo "  $0 check                     # Same as above (default)"
            echo "  REPORTS_DIR=./reports $0   # Use custom reports directory"
            echo "  MIN_COMPLIANCE_RATE=90 $0  # Use higher compliance threshold"
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