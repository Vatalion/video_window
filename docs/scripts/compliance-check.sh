#!/bin/bash
# Compliance checking script for documentation

set -euo pipefail

# Configuration
DOCS_DIR="${DOCS_DIR:-docs}"
COMPLIANCE_CONFIG="${COMPLIANCE_CONFIG:-docs/quality-automation/compliance-rules.json}"
REPORT_FILE="${REPORT_FILE:-docs/quality-automation/compliance-report.json}"

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

# Initialize compliance report
initialize_compliance_report() {
    cat > "$REPORT_FILE" << EOF
{
  "compliance_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_files": 0,
  "compliant_files": 0,
  "non_compliant_files": 0,
  "compliance_rate": 0,
  "compliance_issues": [],
  "compliance_areas": {
    "security": {
      "passed": 0,
      "failed": 0
    },
    "accessibility": {
      "passed": 0,
      "failed": 0
    },
    "privacy": {
      "passed": 0,
      "failed": 0
    },
    "data_protection": {
      "passed": 0,
      "failed": 0
    }
  }
}
EOF
}

# Detect document type
detect_document_type() {
    local file="$1"
    local filename=$(basename "$file")
    local filepath=$(dirname "$file" | sed "s|^$DOCS_DIR/||")

    case "$filepath" in
        "stories"*)
            echo "user-story"
            ;;
        "architecture/adr"*)
            echo "technical-decision"
            ;;
        "qa/assessments"*)
            echo "qa-assessment"
            ;;
        "architecture"*)
            echo "architecture"
            ;;
        "sessions"*)
            echo "checkpoint"
            ;;
        *)
            if [[ "$filename" =~ ^[0-9]+\.[0-9]+\. ]]; then
                echo "user-story"
            elif [[ "$filename" =~ ^ADR-[0-9]{4}- ]]; then
                echo "technical-decision"
            elif [[ "$filename" =~ ^[0-9]+\.[0-9]+-(risk|nfr)-[0-9]{8} ]]; then
                echo "qa-assessment"
            else
                echo "general"
            fi
            ;;
    esac
}

# Check compliance for a specific file
check_compliance() {
    local file="$1"
    local doc_type=$(detect_document_type "$file")
    local errors=()
    local warnings=()
    local compliance_results=()

    log_info "Checking compliance for $file (type: $doc_type)"

    # Read file content
    local content=$(cat "$file")

    # Convert to lowercase for case-insensitive matching
    local content_lower=$(echo "$content" | tr '[:upper:]' '[:lower:]')

    # Security compliance check
    local security_passed=false
    if echo "$content_lower" | grep -q "security\|authentication\|authorization\|encryption"; then
        security_passed=true
        compliance_results+=('{"area": "security", "status": "passed", "reason": "Document mentions security considerations"}')
    else
        errors+=("Document does not mention security considerations")
        compliance_results+=('{"area": "security", "status": "failed", "reason": "Missing security considerations"}')
    fi

    # Accessibility compliance check
    local accessibility_passed=false
    if echo "$content_lower" | grep -q "accessibility\|wcag\|screen reader\|keyboard navigation\|color contrast"; then
        accessibility_passed=true
        compliance_results+=('{"area": "accessibility", "status": "passed", "reason": "Document mentions accessibility requirements"}')
    else
        warnings+=("Document does not mention accessibility requirements")
        compliance_results+=('{"area": "accessibility", "status": "failed", "reason": "Missing accessibility considerations"}')
    fi

    # Privacy compliance check
    local privacy_passed=false
    if echo "$content_lower" | grep -q "privacy\|gdpr\|pii\|personal data\|data protection"; then
        privacy_passed=true
        compliance_results+=('{"area": "privacy", "status": "passed", "reason": "Document mentions privacy considerations"}')
    else
        warnings+=("Document does not mention privacy considerations")
        compliance_results+=('{"area": "privacy", "status": "failed", "reason": "Missing privacy considerations"}')
    fi

    # Data protection compliance check
    local data_protection_passed=false
    if echo "$content_lower" | grep -q "data protection\|encryption\|data security\|backup\|retention"; then
        data_protection_passed=true
        compliance_results+=('{"area": "data_protection", "status": "passed", "reason": "Document mentions data protection"}')
    else
        warnings+=("Document does not mention data protection")
        compliance_results+=('{"area": "data_protection", "status": "failed", "reason": "Missing data protection considerations"}')
    fi

    # Document type specific checks
    case "$doc_type" in
        "user-story")
            # Check for compliance notes section
            if ! echo "$content" | grep -q "## Compliance Notes\|### Compliance"; then
                warnings+=("User story should include compliance notes section")
            fi

            # Check for accessibility requirements in acceptance criteria
            if echo "$content" | grep -q "Acceptance Criteria:"; then
                if ! echo "$content_lower" | grep -q "wcag\|accessible\|screen reader\|keyboard"; then
                    warnings+=("Acceptance criteria should include accessibility requirements")
                fi
            fi
            ;;

        "technical-decision")
            # Check for security impact assessment
            if ! echo "$content_lower" | grep -q "security impact\|security consideration\|risk"; then
                warnings+=("Technical decision should assess security impact")
            fi

            # Check for compliance impact
            if ! echo "$content_lower" | grep -q "compliance\|regulatory\|legal"; then
                warnings+=("Technical decision should consider compliance implications")
            fi
            ;;

        "architecture")
            # Check for security architecture
            if ! echo "$content_lower" | grep -q "security architecture\|security design\|threat model"; then
                warnings+=("Architecture document should include security design")
            fi
            ;;
    esac

    # Calculate compliance score
    local total_checks=4
    local passed_checks=0
    [[ "$security_passed" == "true" ]] && ((passed_checks++))
    [[ "$accessibility_passed" == "true" ]] && ((passed_checks++))
    [[ "$privacy_passed" == "true" ]] && ((passed_checks++))
    [[ "$data_protection_passed" == "true" ]] && ((passed_checks++))

    local compliance_score=$((passed_checks * 100 / total_checks))

    # Return results
    local result="{"
    result+="\"file\": \"$file\","
    result+="\"document_type\": \"$doc_type\","
    result+="\"compliance_score\": $compliance_score,"
    result+="\"errors\": $(printf '%s\n' "${errors[@]}" | sed 's/"/\\"/g' | sed 's/^/"/' | sed 's/$/"/' | tr '\n' ',' | sed 's/,$//'),"
    result+="\"warnings\": $(printf '%s\n' "${warnings[@]}" | sed 's/"/\\"/g' | sed 's/^/"/' | sed 's/$/"/' | tr '\n' ',' | sed 's/,$//'),"
    result+="\"compliance_results\": [$(printf '%s,' "${compliance_results[@]}" | sed 's/,$//')]"
    result+="}"

    echo "$result"
}

# Run compliance checks on all documents
run_compliance_checks() {
    # Initialize report
    initialize_compliance_report

    # Find all markdown files
    local markdown_files=()
    while IFS= read -r -d '' file; do
        # Skip excluded patterns
        local skip=false
        for pattern in "node_modules" ".git" ".DS_Store" "*.tmp.md" "*.draft.md" ".review"; do
            if [[ "$file" =~ $pattern ]]; then
                skip=true
                break
            fi
        done

        if [[ "$skip" == "false" ]]; then
            markdown_files+=("$file")
        fi
    done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)

    local total_files=${#markdown_files[@]}
    local compliant_files=0
    local non_compliant_files=0
    local compliance_issues=()

    # Compliance area counters
    local security_passed=0
    local security_failed=0
    local accessibility_passed=0
    local accessibility_failed=0
    local privacy_passed=0
    local privacy_failed=0
    local data_protection_passed=0
    local data_protection_failed=0

    log_info "Running compliance checks on $total_files files"

    # Check each file
    local file_results=()
    for file in "${markdown_files[@]}"; do
        local result=$(check_compliance "$file")
        file_results+=("$result")

        # Parse result for counters
        local compliance_score=$(echo "$result" | grep -o '"compliance_score": [0-9]*' | cut -d' ' -f2)
        local file_errors=$(echo "$result" | grep -o '"errors": \[[^]]*\]' | grep -o '"[^"]*"' | wc -l || echo "0")

        # Compliance score >= 75% is considered compliant
        if [ "$compliance_score" -ge 75 ]; then
            ((compliant_files++))
            log_success "✓ $file (${compliance_score}%)"
        else
            ((non_compliant_files++))
            log_warning "⚠ $file (${compliance_score}%)"
            if [ "$file_errors" -gt 0 ]; then
                echo "$result" | jq -r '.errors[]' 2>/dev/null | sed 's/^/  /' | head -3
            fi
        fi

        # Update compliance area counters
        if echo "$result" | grep -q '"area": "security", "status": "passed"'; then
            ((security_passed++))
        else
            ((security_failed++))
        fi

        if echo "$result" | grep -q '"area": "accessibility", "status": "passed"'; then
            ((accessibility_passed++))
        else
            ((accessibility_failed++))
        fi

        if echo "$result" | grep -q '"area": "privacy", "status": "passed"'; then
            ((privacy_passed++))
        else
            ((privacy_failed++))
        fi

        if echo "$result" | grep -q '"area": "data_protection", "status": "passed"'; then
            ((data_protection_passed++))
        else
            ((data_protection_failed++))
        fi
    done

    # Calculate overall compliance rate
    local compliance_rate=0
    if [ "$total_files" -gt 0 ]; then
        compliance_rate=$((compliant_files * 100 / total_files))
    fi

    # Update final report
    local files_json=$(printf '%s\n' "${file_results[@]}" | sed ':a;N;$!ba;s/\n/,/g')
    local report_json=$(jq \
        --arg total "$total_files" \
        --arg compliant "$compliant_files" \
        --arg non_compliant "$non_compliant_files" \
        --arg rate "$compliance_rate" \
        --argjson files "[$files_json]" \
        --arg security_passed "$security_passed" \
        --arg security_failed "$security_failed" \
        --arg accessibility_passed "$accessibility_passed" \
        --arg accessibility_failed "$accessibility_failed" \
        --arg privacy_passed "$privacy_passed" \
        --arg privacy_failed "$privacy_failed" \
        --arg data_protection_passed "$data_protection_passed" \
        --arg data_protection_failed "$data_protection_failed" \
        '.total_files = ($total | tonumber) |
         .compliant_files = ($compliant | tonumber) |
         .non_compliant_files = ($non_compliant | tonumber) |
         .compliance_rate = ($rate | tonumber) |
         .files = $files |
         .compliance_areas.security.passed = ($security_passed | tonumber) |
         .compliance_areas.security.failed = ($security_failed | tonumber) |
         .compliance_areas.accessibility.passed = ($accessibility_passed | tonumber) |
         .compliance_areas.accessibility.failed = ($accessibility_failed | tonumber) |
         .compliance_areas.privacy.passed = ($privacy_passed | tonumber) |
         .compliance_areas.privacy.failed = ($privacy_failed | tonumber) |
         .compliance_areas.data_protection.passed = ($data_protection_passed | tonumber) |
         .compliance_areas.data_protection.failed = ($data_protection_failed | tonumber)' \
        "$REPORT_FILE")

    echo "$report_json" > "$REPORT_FILE"

    # Summary
    echo
    log_info "Compliance Summary:"
    echo "  Total files: $total_files"
    echo "  Compliant: $compliant_files"
    echo "  Non-compliant: $non_compliant_files"
    echo "  Compliance rate: ${compliance_rate}%"
    echo
    log_info "Compliance Areas:"
    echo "  Security: $security_passed passed, $security_failed failed"
    echo "  Accessibility: $accessibility_passed passed, $accessibility_failed failed"
    echo "  Privacy: $privacy_passed passed, $privacy_failed failed"
    echo "  Data Protection: $data_protection_passed passed, $data_protection_failed failed"

    return $non_compliant_files
}

# Generate compliance recommendations
generate_recommendations() {
    if [[ ! -f "$REPORT_FILE" ]]; then
        log_error "Compliance report not found. Run compliance checks first."
        return 1
    fi

    log_info "Generating compliance recommendations..."

    # Parse report and generate recommendations
    local compliance_rate=$(jq -r '.compliance_rate' "$REPORT_FILE")
    local non_compliant_files=$(jq -r '.non_compliant_files' "$REPORT_FILE")

    cat > "docs/quality-automation/compliance-recommendations.md" << EOF
# Compliance Recommendations

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Overall Compliance Status

- **Compliance Rate**: ${compliance_rate}%
- **Non-compliant Files**: ${non_compliant_files}

## Priority Areas for Improvement

EOF

    # Add specific recommendations based on failed areas
    local security_failed=$(jq -r '.compliance_areas.security.failed' "$REPORT_FILE")
    local accessibility_failed=$(jq -r '.compliance_areas.accessibility.failed' "$REPORT_FILE")
    local privacy_failed=$(jq -r '.compliance_areas.privacy.failed' "$REPORT_FILE")
    local data_protection_failed=$(jq -r '.compliance_areas.data_protection.failed' "$REPORT_FILE")

    if [ "$security_failed" -gt 0 ]; then
        cat >> "docs/quality-automation/compliance-recommendations.md" << EOF
### Security (High Priority)
- $security_failed documents missing security considerations
- **Action**: Add security sections to all user stories and technical decisions
- **Template requirement**: Include "Security Considerations" section in all document types

EOF
    fi

    if [ "$accessibility_failed" -gt 0 ]; then
        cat >> "docs/quality-automation/compliance-recommendations.md" << EOF
### Accessibility (High Priority)
- $accessibility_failed documents missing accessibility requirements
- **Action**: Add WCAG 2.1 AA compliance requirements to all user stories
- **Template requirement**: Include accessibility criteria in Acceptance Criteria

EOF
    fi

    if [ "$privacy_failed" -gt 0 ]; then
        cat >> "docs/quality-automation/compliance-recommendations.md" << EOF
### Privacy (Medium Priority)
- $privacy_failed documents missing privacy considerations
- **Action**: Add privacy impact assessments to relevant documents
- **Template requirement**: Include "Privacy Impact" section for data handling features

EOF
    fi

    if [ "$data_protection_failed" -gt 0 ]; then
        cat >> "docs/quality-automation/compliance-recommendations.md" << EOF
### Data Protection (Medium Priority)
- $data_protection_failed documents missing data protection measures
- **Action**: Document encryption, backup, and retention policies
- **Template requirement**: Include "Data Protection" section in architecture documents

EOF
    fi

    log_success "Compliance recommendations generated: docs/quality-automation/compliance-recommendations.md"
}

# Main execution
main() {
    case "${1:-check}" in
        "check")
            log_info "Starting compliance checks..."
            if ! run_compliance_checks; then
                log_warning "Some files failed compliance checks"
                if [[ "${FAIL_ON_ERROR:-false}" == "true" ]]; then
                    exit 1
                fi
            fi
            log_success "Compliance checks completed"
            ;;
        "recommendations")
            generate_recommendations
            ;;
        "report")
            if [[ -f "$REPORT_FILE" ]]; then
                cat "$REPORT_FILE" | jq .
            else
                log_error "Compliance report not found. Run compliance checks first."
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo
            echo "Commands:"
            echo "  check           Run compliance checks (default)"
            echo "  recommendations  Generate compliance recommendations"
            echo "  report          Show compliance report"
            echo "  help            Show this help message"
            echo
            echo "Environment Variables:"
            echo "  DOCS_DIR        Documentation directory (default: docs)"
            echo "  FAIL_ON_ERROR   Exit with error if files fail compliance (default: false)"
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

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi