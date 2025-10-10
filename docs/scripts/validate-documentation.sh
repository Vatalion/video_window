#!/bin/bash
# Documentation Quality Validation Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="${DOCS_DIR:-docs}"
CONFIG_FILE="${CONFIG_FILE:-docs/quality-automation/validation-config.yaml}"
REPORT_FILE="${REPORT_FILE:-docs/quality-automation/validation-report.json}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-true}"
TEMP_DIR=$(mktemp -d)

# Ensure required directories exist
mkdir -p "$(dirname "$REPORT_FILE")"
mkdir -p "$TEMP_DIR"

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

# Initialize report
initialize_report() {
    cat > "$REPORT_FILE" << EOF
{
  "validation_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_files": 0,
  "passed_files": 0,
  "failed_files": 0,
  "warnings": 0,
  "errors": 0,
  "files": []
}
EOF
}

# Detect document type
detect_document_type() {
    local file="$1"
    local filename=$(basename "$file")
    local filepath=$(dirname "$file" | sed "s|^$DOCS_DIR/||")

    # Check by directory structure first
    case "$filepath" in
        "stories"*)
            if [[ "$filename" =~ ^[0-9]+\.[0-9]+\.[a-z0-9-]+\.md$ ]]; then
                echo "story"
            else
                echo "general"
            fi
            ;;
        "architecture/adr"*)
            if [[ "$filename" =~ ^ADR-[0-9]{4}-[a-z0-9-]+\.md$ ]]; then
                echo "technical_decision"
            else
                echo "general"
            fi
            ;;
        "qa/assessments"*)
            if [[ "$filename" =~ ^[0-9]+\.[0-9]+-(risk|nfr)-[0-9]{8}\.md$ ]]; then
                echo "qa_assessment"
            else
                echo "general"
            fi
            ;;
        "sessions"*)
            if [[ "$filename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+-checkpoint\.md$ ]]; then
                echo "checkpoint"
            else
                echo "general"
            fi
            ;;
        *)
            # Fallback to filename pattern matching
            if [[ "$filename" =~ ^[0-9]+\.[0-9]+\.[a-z0-9-]+\.md$ ]]; then
                echo "story"
            elif [[ "$filename" =~ ^ADR-[0-9]{4}-[a-z0-9-]+\.md$ ]]; then
                echo "technical_decision"
            elif [[ "$filename" =~ ^[0-9]+\.[0-9]+-(risk|nfr)-[0-9]{8}\.md$ ]]; then
                echo "qa_assessment"
            elif [[ "$filename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+-checkpoint\.md$ ]]; then
                echo "checkpoint"
            else
                echo "general"
            fi
            ;;
    esac
}

# Validate template compliance
validate_template_compliance() {
    local file="$1"
    local doc_type="$2"
    local errors=()
    local warnings=()

    log_info "Validating template compliance for $file (type: $doc_type)"

    # Read file content
    local content=$(cat "$file")

    case "$doc_type" in
        "story")
            # Check required sections
            local required_sections=("Story:" "Acceptance Criteria:" "Dev Notes:" "Testing:" "Dev Agent Record:" "Change Log:" "Status:" "QA Results:")
            for section in "${required_sections[@]}"; do
                if ! echo "$content" | grep -q "^$section"; then
                    errors+=("Missing required section: $section")
                fi
            done

            # Check status format
            if echo "$content" | grep -q "^Status:"; then
                local status=$(echo "$content" | grep "^Status:" | sed 's/^Status: //')
                if [[ ! "$status" =~ ^(To Do|In Progress|Done|Blocked)$ ]]; then
                    errors+=("Invalid status format: $status (expected: To Do, In Progress, Done, or Blocked)")
                fi
            else
                errors+=("Missing Status: section")
            fi

            # Check story ID format
            local filename=$(basename "$file")
            if [[ ! "$filename" =~ ^[0-9]+\.[0-9]+\. ]]; then
                errors+=("Invalid story ID format in filename (expected: X.Y format)")
            fi

            # Check acceptance criteria format
            if echo "$content" | grep -q "^Acceptance Criteria:"; then
                local ac_section=$(echo "$content" | sed -n '/^Acceptance Criteria:/,/^#/p' | sed '$d')
                if ! echo "$ac_section" | grep -q "^[0-9]\+\."; then
                    warnings+=("Acceptance criteria should be numbered (1., 2., etc.)")
                fi
            fi
            ;;

        "technical_decision")
            # Check ADR required sections
            local required_sections=("Context:" "Decision:" "Consequences:" "Status:")
            for section in "${required_sections[@]}"; do
                if ! echo "$content" | grep -q "^$section"; then
                    errors+=("Missing required section: $section")
                fi
            done

            # Check status format
            if echo "$content" | grep -q "^Status:"; then
                local status=$(echo "$content" | grep "^Status:" | sed 's/^Status: //')
                if [[ ! "$status" =~ ^(Proposed|Approved|Implemented|Deprecated|Superseded)$ ]]; then
                    errors+=("Invalid ADR status format: $status")
                fi
            else
                errors+=("Missing Status: section")
            fi
            ;;

        "qa_assessment")
            # Check QA required sections
            local required_sections=("Assessment Type:" "Scope:" "Findings:" "Risk Level:" "Recommendations:" "Status:")
            for section in "${required_sections[@]}"; do
                if ! echo "$content" | grep -q "^$section"; then
                    errors+=("Missing required section: $section")
                fi
            done

            # Check risk level format
            if echo "$content" | grep -q "^Risk Level:"; then
                local risk_level=$(echo "$content" | grep "^Risk Level:" | sed 's/^Risk Level: //')
                if [[ ! "$risk_level" =~ ^(Low|Medium|High|Critical)$ ]]; then
                    errors+=("Invalid risk level format: $risk_level")
                fi
            else
                errors+=("Missing Risk Level: section")
            fi
            ;;

        "checkpoint")
            # Check checkpoint required sections
            local required_sections=("Session Date:" "Participants:" "Agenda:" "Discussion:" "Action Items:" "Next Steps:")
            for section in "${required_sections[@]}"; do
                if ! echo "$content" | grep -q "^$section"; then
                    errors+=("Missing required section: $section")
                fi
            done

            # Check date format
            if echo "$content" | grep -q "^Session Date:"; then
                local date=$(echo "$content" | grep "^Session Date:" | sed 's/^Session Date: //')
                if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    errors+=("Invalid date format: $date (expected: YYYY-MM-DD)")
                fi
            else
                errors+=("Missing Session Date: section")
            fi
            ;;
    esac

    # Return results
    if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
        return 0
    else
        {
            printf '%s\n' "${errors[@]}"
            printf '%s\n' "${warnings[@]}"
        } > "$TEMP_DIR/validation_errors_$(basename "$file")"
        return 1
    fi
}

# Validate links
validate_links() {
    local file="$1"
    local errors=()
    local content=$(cat "$file")

    log_info "Validating links in $file"

    # Extract all markdown links
    while IFS= read -r line; do
        if [[ "$line" =~ \[.*\]\(([^)]+)\) ]]; then
            local link="${BASH_REMATCH[1]}"

            # Skip external links and email links
            if [[ "$link" =~ ^https?:// ]] || [[ "$link" =~ ^mailto: ]] || [[ "$link" =~ ^\# ]]; then
                # Check anchor links
                if [[ "$link" =~ ^# ]]; then
                    local anchor="${link:1}"
                    # Convert anchor to match heading format (basic conversion)
                    anchor=$(echo "$anchor" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

                    if ! grep -qi "^#+ [^#]*${anchor}" "$file"; then
                        errors+=("Broken anchor link: $link")
                    fi
                fi
                continue
            fi

            # Check file links
            local target_file
            if [[ "$link" =~ ^/ ]]; then
                target_file="${link:1}"  # Remove leading slash
            else
                target_file="$(dirname "$file")/$link"
            fi

            # Normalize path
            target_file=$(realpath -m "$target_file" 2>/dev/null || echo "$target_file")

            if [[ ! -f "$target_file" ]] && [[ ! -d "$target_file" ]]; then
                errors+=("Broken file link: $link (resolved to: $target_file)")
            fi
        fi
    done <<< "$content"

    if [ ${#errors[@]} -eq 0 ]; then
        return 0
    else
        printf '%s\n' "${errors[@]}" > "$TEMP_DIR/link_errors_$(basename "$file")"
        return 1
    fi
}

# Validate markdown syntax
validate_markdown_syntax() {
    local file="$1"
    local errors=()
    local content=$(cat "$file")

    log_info "Validating markdown syntax in $file"

    # Check for common markdown issues

    # 1. Check heading hierarchy
    local prev_level=0
    local line_num=0
    while IFS= read -r line; do
        ((line_num++))
        if [[ "$line" =~ ^#{1,6}\s+(.+) ]]; then
            local level=${#BASH_REMATCH[0]}
            if [ $level -gt $((prev_level + 1)) ] && [ $prev_level -gt 0 ]; then
                errors+=("Line $line_num: Heading level jump from $prev_level to $level: $line")
            fi
            prev_level=$level
        fi
    done <<< "$content"

    # 2. Check for fenced code blocks without language
    local line_num=0
    local in_code_block=false
    while IFS= read -r line; do
        ((line_num++))
        if [[ "$line" =~ ^``` ]]; then
            if [[ "$in_code_block" == "false" ]] && [[ "$line" == "```" ]]; then
                errors+=("Line $line_num: Fenced code block without language specifier")
            fi
            in_code_block=$([ "$in_code_block" == "true" ] && echo "false" || echo "true")
        fi
    done <<< "$content"

    # 3. Check list formatting consistency
    local line_num=0
    local in_list=false
    local list_type=""
    local list_start_line=0

    while IFS= read -r line; do
        ((line_num++))
        if [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]] ]]; then
            if [[ "$in_list" == "true" ]] && [[ "$list_type" != "unordered" ]]; then
                errors+=("Line $line_num: Mixed list types detected (started as $list_type at line $list_start_line)")
            fi
            in_list=true
            list_type="unordered"
            list_start_line=$([ "$list_start_line" -eq 0 ] && echo "$line_num" || echo "$list_start_line")
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]] ]]; then
            if [[ "$in_list" == "true" ]] && [[ "$list_type" != "ordered" ]]; then
                errors+=("Line $line_num: Mixed list types detected (started as $list_type at line $list_start_line)")
            fi
            in_list=true
            list_type="ordered"
            list_start_line=$([ "$list_start_line" -eq 0 ] && echo "$line_num" || echo "$list_start_line")
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        elif [[ "$line" =~ ^[[:space:]]*[^-*+0-9[:space:]] ]]; then
            in_list=false
            list_type=""
            list_start_line=0
        fi
    done <<< "$content"

    if [ ${#errors[@]} -eq 0 ]; then
        return 0
    else
        printf '%s\n' "${errors[@]}" > "$TEMP_DIR/syntax_errors_$(basename "$file")"
        return 1
    fi
}

# Run comprehensive validation
validate_file() {
    local file="$1"
    local doc_type=$(detect_document_type "$file")

    local validation_passed=true
    local errors=()
    local warnings=()

    # Template compliance
    if ! validate_template_compliance "$file" "$doc_type"; then
        validation_passed=false
        local error_file="$TEMP_DIR/validation_errors_$(basename "$file")"
        if [[ -f "$error_file" ]]; then
            while IFS= read -r error; do
                errors+=("$error")
            done < "$error_file"
        fi
    fi

    # Link validation
    if ! validate_links "$file"; then
        validation_passed=false
        local error_file="$TEMP_DIR/link_errors_$(basename "$file")"
        if [[ -f "$error_file" ]]; then
            while IFS= read -r error; do
                errors+=("$error")
            done < "$error_file"
        fi
    fi

    # Markdown syntax validation
    if ! validate_markdown_syntax "$file"; then
        validation_passed=false
        local error_file="$TEMP_DIR/syntax_errors_$(basename "$file")"
        if [[ -f "$error_file" ]]; then
            while IFS= read -r error; do
                errors+=("$error")
            done < "$error_file"
        fi
    fi

    # Build JSON result
    local file_result="{"
    file_result+="\"file\": \"$file\","
    file_result+="\"type\": \"$doc_type\","
    file_result+="\"passed\": $validation_passed,"

    # Add errors
    if [ ${#errors[@]} -gt 0 ]; then
        local error_json=$(printf '%s\n' "${errors[@]}" | sed 's/"/\\"/g' | sed 's/^/"/' | sed 's/$/"/' | tr '\n' ',' | sed 's/,$//')
        file_result+="\"errors\": [$error_json]"
    else
        file_result+="\"errors\": []"
    fi

    file_result+="}"

    echo "$file_result"
}

# Main execution
main() {
    log_info "Starting documentation validation..."

    # Initialize report
    initialize_report

    # Find all markdown files (excluding common patterns)
    local markdown_files=()
    while IFS= read -r -d '' file; do
        # Skip excluded patterns
        local skip=false
        for pattern in "node_modules" ".git" ".DS_Store" "*.tmp.md" "*.draft.md"; do
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
    local passed_files=0
    local failed_files=0
    local total_errors=0
    local total_warnings=0

    log_info "Found $total_files markdown files to validate"

    # Validate each file
    local file_results=()
    for file in "${markdown_files[@]}"; do
        log_info "Validating: $file"

        local result=$(validate_file "$file")
        file_results+=("$result")

        # Parse result for summary
        local passed=$(echo "$result" | grep -o '"passed": [^,]*' | cut -d' ' -f2)
        local error_count=$(echo "$result" | grep -o '"errors": \[[^]]*\]' | grep -o '"[^"]*"' | wc -l || echo "0")

        if [[ "$passed" == "true" ]]; then
            ((passed_files++))
            log_success "✓ $file"
        else
            ((failed_files++))
            log_error "✗ $file"
        fi

        ((total_errors += error_count))
    done

    # Update final report
    local files_json=$(printf '%s\n' "${file_results[@]}" | sed ':a;N;$!ba;s/\n/,/g')
    local report_json=$(cat "$REPORT_FILE" | jq \
        --arg total "$total_files" \
        --arg passed "$passed_files" \
        --arg failed "$failed_files" \
        --arg errors "$total_errors" \
        --argjson files "[$files_json]" \
        '.total_files = ($total | tonumber) |
         .passed_files = ($passed | tonumber) |
         .failed_files = ($failed | tonumber) |
         .errors = ($errors | tonumber) |
         .files = $files')

    echo "$report_json" > "$REPORT_FILE"

    # Cleanup
    rm -rf "$TEMP_DIR"

    # Summary
    echo
    log_info "Validation Summary:"
    echo "  Total files: $total_files"
    echo "  Passed: $passed_files"
    echo "  Failed: $failed_files"
    echo "  Errors: $total_errors"

    if [ $failed_files -eq 0 ]; then
        log_success "All files passed validation!"
        return 0
    else
        log_error "$failed_files files failed validation"
        if [[ "$FAIL_ON_ERROR" == "true" ]]; then
            return 1
        else
            log_warning "Continuing despite validation failures (FAIL_ON_ERROR=false)"
            return 0
        fi
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --help, -h              Show this help message"
            echo "  --fail-on-error         Fail script if any files fail validation (default: true)"
            echo "  --no-fail-on-error      Continue script even if files fail validation"
            echo "  --docs-dir DIR          Documentation directory (default: docs)"
            echo "  --config-file FILE      Configuration file (default: docs/quality-automation/validation-config.yaml)"
            echo "  --report-file FILE      Output report file (default: docs/quality-automation/validation-report.json)"
            echo
            exit 0
            ;;
        --fail-on-error)
            export FAIL_ON_ERROR=true
            shift
            ;;
        --no-fail-on-error)
            export FAIL_ON_ERROR=false
            shift
            ;;
        --docs-dir)
            export DOCS_DIR="$2"
            shift 2
            ;;
        --config-file)
            export CONFIG_FILE="$2"
            shift 2
            ;;
        --report-file)
            export REPORT_FILE="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check dependencies
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install jq to continue."
    exit 1
fi

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi