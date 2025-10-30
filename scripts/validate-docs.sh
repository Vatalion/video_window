#!/bin/bash

# Documentation Validation Script
# Purpose: Automated checks for documentation consistency and quality
# Usage: ./scripts/validate-docs.sh

set -euo pipefail

echo "🔍 Starting Documentation Validation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

# Helper functions
error() {
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}" >&2
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "melos.yaml" ]]; then
    error "Must run from project root (melos.yaml not found)"
    exit 1
fi

echo
echo "📋 Running Documentation Validation Checks..."
echo "=============================================="

# 1. Epic Numbering Consistency Check
echo
info "1. Checking Epic Numbering Consistency..."

# Check tech-spec-epic files follow non-padded naming
echo "   📝 Validating tech-spec-epic file naming..."
for file in docs/tech-spec-epic-*.md; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        # Extract number from filename
        if [[ $filename =~ tech-spec-epic-([0-9]+)\.md ]]; then
            number="${BASH_REMATCH[1]}"
            # Check if number is zero-padded
            if [[ $number =~ ^0[0-9] ]]; then
                error "Found zero-padded epic file: $filename (should be tech-spec-epic-${number#0}.md)"
            fi
        else
            warning "Found malformed tech-spec-epic filename: $filename"
        fi
    fi
done

# Check for duplicate epic numbers
echo "   🔍 Checking for duplicate epic numbers..."
epic_numbers=()
for file in docs/tech-spec-epic-*.md; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        if [[ $filename =~ tech-spec-epic-([0-9]+)\.md ]]; then
            number="${BASH_REMATCH[1]}"
            epic_numbers+=("$number")
        fi
    fi
done

# Check for duplicates
if [[ ${#epic_numbers[@]} -gt 0 ]]; then
    duplicates=$(printf '%s\n' "${epic_numbers[@]}" | sort | uniq -d)
    if [[ -n "$duplicates" ]]; then
        error "Found duplicate epic numbers: $duplicates"
    fi
fi

# 2. Cross-Reference Validation
echo
info "2. Validating Cross-References..."

# Check tech-spec.md references
echo "   📖 Checking tech-spec.md epic references..."
if [[ -f "docs/tech-spec.md" ]]; then
    # Extract epic references from tech-spec.md
    while IFS= read -r line; do
        if [[ $line =~ \[tech-spec-epic-([0-9]+)\.md\] ]]; then
            epic_num="${BASH_REMATCH[1]}"
            expected_file="docs/tech-spec-epic-${epic_num}.md"
            if [[ ! -f "$expected_file" ]]; then
                error "tech-spec.md references non-existent file: tech-spec-epic-${epic_num}.md"
            fi
        fi
    done < docs/tech-spec.md
else
    error "Missing required file: docs/tech-spec.md"
fi

# Check story file references
echo "   📚 Checking story file epic alignment..."
if [[ -d "docs/stories" ]]; then
    for story_file in docs/stories/*.md; do
        if [[ -f "$story_file" ]]; then
            filename=$(basename "$story_file")
            # Extract epic number from story filename  
            if [[ $filename =~ ^([0-9]+)[\.\-]([0-9]+)[\.\-].*\.md$ ]]; then
                epic_part="${BASH_REMATCH[1]}"
                # Get base epic number
                base_epic="$epic_part"
                
                # Check if corresponding tech-spec exists
                tech_spec_file="docs/tech-spec-epic-${base_epic}.md"
                if [[ ! -f "$tech_spec_file" ]]; then
                    warning "Story $filename references epic $base_epic but no tech-spec-epic-${base_epic}.md exists"
                fi
            else
                warning "Story filename doesn't follow expected pattern: $filename"
            fi
        fi
    done
else
    warning "Stories directory not found: docs/stories/"
fi

# 3. Dead Link Detection
echo
info "3. Checking for Dead Links..."

echo "   🔗 Scanning for broken internal links..."
# Find all markdown files
find docs -name "*.md" -type f | while read -r file; do
    # Extract markdown links [text](path)
    grep -n '\[.*\](.*\.md)' "$file" | while IFS=: read -r line_num link; do
        # Extract the path from the link using simpler approach
        if echo "$link" | grep -q '](.*\.md)'; then
            link_path=$(echo "$link" | sed 's/.*](\([^)]*\.md\)).*/\1/')
            
            # Resolve relative path
            file_dir=$(dirname "$file")
            if [[ $link_path == /* ]]; then
                # Absolute path from project root
                resolved_path="${link_path#/}"
            else
                # Relative path
                resolved_path="$file_dir/$link_path"
            fi
            
            # Normalize path
            resolved_path=$(realpath -m "$resolved_path" 2>/dev/null || echo "$resolved_path")
            
            # Check if file exists
            if [[ ! -f "$resolved_path" ]]; then
                error "Dead link in $file:$line_num -> $link_path (resolved: $resolved_path)"
            fi
        fi
    done
done

# 4. Orphaned File Detection
echo
info "4. Checking for Orphaned Files..."

echo "   🗂️  Scanning for unreferenced files..."
# Get all markdown files in docs/
all_docs=($(find docs -name "*.md" -type f))

# Files that should always exist (never orphaned)
critical_files=(
    "docs/prd.md"
    "docs/tech-spec.md"
    "docs/brief.md"
)

# Check each file for references
for doc_file in "${all_docs[@]}"; do
    filename=$(basename "$doc_file")
    file_path="$doc_file"
    
    # Skip critical files
    is_critical=false
    for critical in "${critical_files[@]}"; do
        if [[ "$file_path" == "$critical" ]]; then
            is_critical=true
            break
        fi
    done
    
    if [[ $is_critical == true ]]; then
        continue
    fi
    
    # Check if file is referenced anywhere
    referenced=false
    
    # Search for references in all markdown files
    for search_file in "${all_docs[@]}"; do
        if [[ "$search_file" != "$doc_file" ]]; then
            # Look for references to this file
            if grep -q "$filename\|$(basename "$doc_file" .md)" "$search_file" 2>/dev/null; then
                referenced=true
                break
            fi
        fi
    done
    
    # Special cases - some files are entry points
    case "$filename" in
        "README.md"|"*-template.md"|"*-example.md")
            referenced=true
            ;;
    esac
    
    if [[ $referenced == false ]]; then
        warning "Potentially orphaned file: $doc_file"
    fi
done

# 5. Story Structure Validation
echo
info "5. Validating Story Structure..."

if [[ -d "docs/stories" ]]; then
    echo "   📋 Checking story file structure..."
    
    required_sections=("## Status" "## Story" "## Acceptance Criteria" "## Tasks" "## Dev Notes")
    
    for story_file in docs/stories/*.md; do
        if [[ -f "$story_file" ]]; then
            filename=$(basename "$story_file")
            
            # Check for required sections
            for section in "${required_sections[@]}"; do
                if ! grep -q "^$section" "$story_file"; then
                    error "Story $filename missing required section: $section"
                fi
            done
            
            # Check status format
            status_line=$(grep "^**Status:**" "$story_file" | head -1)
            if [[ -n "$status_line" ]]; then
                # Check for consistent status format
                if [[ ! $status_line =~ \*\*Status:\*\*[[:space:]]+(Ready for Dev|In Development|Ready for Review|Completed) ]]; then
                    warning "Story $filename has non-standard status format: $status_line"
                fi
            else
                error "Story $filename missing status line"
            fi
        fi
    done
fi

# 6. Process Document Validation
echo
info "6. Validating Process Documents..."

# Check for required process documents
required_process_docs=(
    "docs/process/definition-of-ready.md"
    "docs/process/definition-of-done.md"
    "docs/process/story-approval-workflow.md"
    "docs/process/epic-validation-backlog.md"
)

for doc in "${required_process_docs[@]}"; do
    if [[ ! -f "$doc" ]]; then
        error "Missing required process document: $doc"
    fi
done

# Check BMAD template references
echo "   🔧 Checking BMAD template references..."
if [[ -f "docs/process/definition-of-ready.md" ]]; then
    if grep -q "\.bmad-core" "docs/process/definition-of-ready.md"; then
        error "Found obsolete .bmad-core reference in definition-of-ready.md (should use bmad/bmm/workflows/)"
    fi
fi

# 7. Epic Validation Status Check
echo
info "7. Checking Epic Validation Status..."

if [[ -f "docs/process/epic-validation-backlog.md" ]]; then
    echo "   📊 Validating epic status consistency..."
    
    # Check that all tech-spec epics have entries in validation backlog
    for tech_spec in docs/tech-spec-epic-*.md; do
        if [[ -f "$tech_spec" ]]; then
            filename=$(basename "$tech_spec")
            if [[ $filename =~ tech-spec-epic-([0-9]+)\.md ]]; then
                epic_num="${BASH_REMATCH[1]}"
                
                # Check if epic is mentioned in validation backlog
                if ! grep -q "| $epic_num " "docs/process/epic-validation-backlog.md"; then
                    warning "Epic $epic_num has tech spec but no validation backlog entry"
                fi
            fi
        fi
    done
fi

# Summary
echo
echo "📊 Documentation Validation Summary"
echo "=================================="
echo

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    success "All documentation validation checks passed! 🎉"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Validation completed with $WARNINGS warnings${NC}"
    echo
    echo "Consider addressing warnings to improve documentation quality."
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS errors and $WARNINGS warnings${NC}"
    echo
    echo "Please fix all errors before proceeding."
    exit 1
fi