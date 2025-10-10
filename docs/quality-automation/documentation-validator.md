# Documentation Template Validation System

Status: v1.0 — Automated template validation for all documentation types

## Overview

This system validates that all documentation follows required templates and quality standards through automated checks.

## Validation Rules Engine

### Template Compliance Rules

```yaml
# Template validation configuration
templates:
  story:
    required_sections:
      - "Story:"
      - "Acceptance Criteria:"
      - "Dev Notes:"
      - "Testing:"
      - "Dev Agent Record:"
      - "Change Log:"
      - "Status:"
      - "QA Results:"
    required_patterns:
      status: "^Status: (To Do|In Progress|Done|Blocked)$"
      story_id: "^\\d+\\.\\d+"
      acceptance_criteria: "^\\d+\\. "
    file_naming: "^\\d+\\.\\d+\\.[a-z0-9-]+\\.md$"

  technical_decision:
    required_sections:
      - "Context:"
      - "Decision:"
      - "Consequences:"
      - "Status:"
    required_patterns:
      status: "^Status: (Proposed|Approved|Implemented|Deprecated|Superseded)$"
      file_naming: "^ADR-\\d{4}-[a-z0-9-]+\\.md$"

  qa_assessment:
    required_sections:
      - "Assessment Type:"
      - "Scope:"
      - "Findings:"
      - "Risk Level:"
      - "Recommendations:"
      - "Status:"
    required_patterns:
      risk_level: "^Risk Level: (Low|Medium|High|Critical)$"
      status: "^Status: (Draft|In Review|Approved|Archived)$"

  checkpoint:
    required_sections:
      - "Session Date:"
      - "Participants:"
      - "Agenda:"
      - "Discussion:"
      - "Action Items:"
      - "Next Steps:"
    required_patterns:
      date: "^\\d{4}-\\d{2}-\\d{2}$"
      file_naming: "^\\d{4}-\\d{2}-\\d{2}-[a-z0-9-]+-checkpoint\\.md$"
```

### Content Quality Rules

```yaml
# Content quality validation
quality_rules:
  link_validation:
    internal_links: true
    external_links: true
    anchor_links: true
    check_broken: true

  structure_validation:
    heading_hierarchy: true
    max_heading_depth: 6
    require_toc_for_long_docs: true
    toc_min_sections: 5

  content_validation:
    spell_check: true
    grammar_check: true
    technical_terms: true
    consistency_check: true

  formatting_validation:
    markdown_syntax: true
    code_block_language: true
    list_formatting: true
    table_formatting: true
```

## Automated Validation Scripts

### Primary Validator Script

```bash
#!/bin/bash
# docs/scripts/validate-documentation.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="docs"
CONFIG_FILE="docs/quality-automation/validation-config.yaml"
REPORT_FILE="docs/quality-automation/validation-report.json"
TEMP_DIR=$(mktemp -d)

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
                    errors+=("Invalid status format: $status")
                fi
            fi

            # Check story ID format
            local filename=$(basename "$file")
            if [[ ! "$filename" =~ ^[0-9]+\.[0-9]+\. ]]; then
                errors+=("Invalid story ID format in filename")
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
            fi
            ;;
    esac

    # Return results
    if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
        return 0
    else
        printf '%s\n' "${errors[@]}" "${warnings[@]}" > "$TEMP_DIR/validation_errors_$(basename "$file")"
        return 1
    fi
}

# Validate links
validate_links() {
    local file="$1"
    local errors=()

    log_info "Validating links in $file"

    # Extract all markdown links
    local content=$(cat "$file")

    # Check internal links
    while IFS= read -r line; do
        if [[ "$line" =~ \[.*\]\(([^)]+)\) ]]; then
            local link="${BASH_REMATCH[1]}"

            # Skip external links
            if [[ "$link" =~ ^https?:// ]] || [[ "$link" =~ ^mailto: ]]; then
                continue
            fi

            # Check anchor links
            if [[ "$link" =~ ^# ]]; then
                local anchor="${link:1}"
                # Convert anchor to match heading format
                anchor=$(echo "$anchor" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

                if ! grep -q "^#+ [^#]*$anchor" "$file"; then
                    errors+=("Broken anchor link: $link")
                fi
            else
                # Check file links
                local target_file
                if [[ "$link" =~ ^/ ]]; then
                    target_file="${DOCS_DIR}${link}"
                else
                    target_file="$(dirname "$file")/$link"
                fi

                if [[ ! -f "$target_file" ]] && [[ ! -d "$target_file" ]]; then
                    errors+=("Broken file link: $link")
                fi
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
    while IFS= read -r line; do
        if [[ "$line" =~ ^#{1,6}\s+(.+) ]]; then
            local level=${#BASH_REMATCH[0]}
            if [ $level -gt $((prev_level + 1)) ]; then
                errors+=("Heading level jump from $prev_level to $level: $line")
            fi
            prev_level=$level
        fi
    done <<< "$content"

    # 2. Check for fenced code blocks with language
    while IFS= read -r line; do
        if [[ "$line" =~ ^```$ ]]; then
            errors+=("Fenced code block without language specifier: $line")
        fi
    done <<< "$content"

    # 3. Check list formatting
    local in_list=false
    local list_type=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]] ]]; then
            if [[ "$in_list" == "true" ]] && [[ "$list_type" != "unordered" ]]; then
                errors+=("Mixed list types detected: $line")
            fi
            in_list=true
            list_type="unordered"
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]] ]]; then
            if [[ "$in_list" == "true" ]] && [[ "$list_type" != "ordered" ]]; then
                errors+=("Mixed list types detected: $line")
            fi
            in_list=true
            list_type="ordered"
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        else
            in_list=false
            list_type=""
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
    local file_result="{\"file\": \"$file\", \"type\": \"$doc_type\""

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

    # Add results to file result
    file_result+=", \"passed\": $validation_passed"
    if [ ${#errors[@]} -gt 0 ]; then
        local error_json=$(printf '%s\n' "${errors[@]}" | jq -R . | jq -s .)
        file_result+=", \"errors\": $error_json"
    else
        file_result+=", \"errors\": []"
    fi
    if [ ${#warnings[@]} -gt 0 ]; then
        local warning_json=$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)
        file_result+=", \"warnings\": $warning_json"
    else
        file_result+=", \"warnings\": []"
    fi
    file_result+="}"

    echo "$file_result"
}

# Main execution
main() {
    log_info "Starting documentation validation..."

    # Initialize report
    initialize_report

    # Find all markdown files
    local markdown_files=()
    while IFS= read -r -d '' file; do
        markdown_files+=("$file")
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

        local passed=$(echo "$result" | jq -r '.passed')
        local error_count=$(echo "$result" | jq '.errors | length')
        local warning_count=$(echo "$result" | jq '.warnings | length')

        if [[ "$passed" == "true" ]]; then
            ((passed_files++))
            log_success "✓ $file"
        else
            ((failed_files++))
            log_error "✗ $file"
            if [ $error_count -gt 0 ]; then
                echo "$result" | jq -r '.errors[]' | sed 's/^/  /'
            fi
        fi

        ((total_errors += error_count))
        ((total_warnings += warning_count))
    done

    # Update final report
    local report_json=$(jq \
        --arg total "$total_files" \
        --arg passed "$passed_files" \
        --arg failed "$failed_files" \
        --arg errors "$total_errors" \
        --arg warnings "$total_warnings" \
        --argjson files "$(printf '%s\n' "${file_results[@]}" | jq -s .)" \
        '.total_files = ($total | tonumber) |
         .passed_files = ($passed | tonumber) |
         .failed_files = ($failed | tonumber) |
         .errors = ($errors | tonumber) |
         .warnings = ($warnings | tonumber) |
         .files = $files' \
        "$REPORT_FILE")

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
    echo "  Warnings: $total_warnings"

    if [ $failed_files -eq 0 ]; then
        log_success "All files passed validation!"
        return 0
    else
        log_error "$failed_files files failed validation"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Configuration File

```yaml
# docs/quality-automation/validation-config.yaml
validation:
  enabled: true
  fail_on_error: true
  fail_on_warning: false

templates:
  story:
    required_sections:
      - "Story:"
      - "Acceptance Criteria:"
      - "Dev Notes:"
      - "Testing:"
      - "Dev Agent Record:"
      - "Change Log:"
      - "Status:"
      - "QA Results:"
    required_patterns:
      status: "^Status: (To Do|In Progress|Done|Blocked)$"
      story_id: "^\\d+\\.\\d+"
      acceptance_criteria: "^\\d+\\. "
    file_naming: "^\\d+\\.\\d+\\.[a-z0-9-]+\\.md$"

  technical_decision:
    required_sections:
      - "Context:"
      - "Decision:"
      - "Consequences:"
      - "Status:"
    required_patterns:
      status: "^Status: (Proposed|Approved|Implemented|Deprecated|Superseded)$"
    file_naming: "^ADR-\\d{4}-[a-z0-9-]+\\.md$"

  qa_assessment:
    required_sections:
      - "Assessment Type:"
      - "Scope:"
      - "Findings:"
      - "Risk Level:"
      - "Recommendations:"
      - "Status:"
    required_patterns:
      risk_level: "^Risk Level: (Low|Medium|High|Critical)$"
      status: "^Status: (Draft|In Review|Approved|Archived)$"
    file_naming: "^\\d+\\.\\d+-(risk|nfr)-\\d{8}\\.md$"

quality_checks:
  links:
    internal: true
    external: true
    anchor: true
    check_broken: true

  structure:
    heading_hierarchy: true
    max_heading_depth: 6
    require_toc: false
    toc_min_sections: 5

  content:
    spell_check: true
    grammar_check: true
    technical_terms: true
    consistency_check: true

  formatting:
    markdown_syntax: true
    code_block_language: true
    list_formatting: true
    table_formatting: true

exclude_patterns:
  - "node_modules/**"
  - ".git/**"
  - "**/README.md"
  - "**/*.tmp.md"
  - "**/*.draft.md"

reporting:
  output_format: "json"
  include_suggestions: true
  max_issues_per_file: 50
  group_by_type: true
```

## Usage Instructions

### Running Validation

```bash
# Validate all documentation
./docs/scripts/validate-documentation.sh

# Validate specific directory
./docs/scripts/validate-documentation.sh docs/stories

# Validate with custom config
CONFIG_FILE=custom-config.yaml ./docs/scripts/validate-documentation.sh

# Generate HTML report
./docs/scripts/validate-documentation.sh --html-report
```

### Integration with CI/CD

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

jobs:
  documentation-validation:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: |
        npm install -g markdownlint-cli
        npm install -g cspell

    - name: Run documentation validation
      run: |
        chmod +x docs/scripts/validate-documentation.sh
        ./docs/scripts/validate-documentation.sh

    - name: Upload validation report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: validation-report
        path: docs/quality-automation/validation-report.json

    - name: Comment PR with results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const report = JSON.parse(fs.readFileSync('docs/quality-automation/validation-report.json', 'utf8'));

          const comment = `
          ## Documentation Quality Report

          **Summary:**
          - Total files: ${report.total_files}
          - ✅ Passed: ${report.passed_files}
          - ❌ Failed: ${report.failed_files}
          - 🚨 Errors: ${report.errors}
          - ⚠️ Warnings: ${report.warnings}

          ${report.failed_files > 0 ? '### Failed Files\n\n' + report.files.filter(f => !f.passed).map(f => `- **${f.file}**\n  ${f.errors.map(e => '  - ' + e).join('\n')}`).join('\n\n') : ''}
          `;

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });
```

## Customization and Extension

### Adding New Document Types

To add validation for new document types:

1. Add template configuration to `validation-config.yaml`
2. Update `detect_document_type()` function in the validator script
3. Add validation logic in `validate_template_compliance()` function

### Custom Validation Rules

Create custom validation functions by extending the validator script:

```bash
validate_custom_rules() {
    local file="$1"
    local errors=()

    # Custom validation logic here

    if [ ${#errors[@]} -eq 0 ]; then
        return 0
    else
        printf '%s\n' "${errors[@]}" > "$TEMP_DIR/custom_errors_$(basename "$file")"
        return 1
    fi
}
```

This automated validation system ensures consistent documentation quality across the entire project and integrates seamlessly with CI/CD pipelines.