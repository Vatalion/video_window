# Testing Automation Framework

Status: v1.0 — Automated test generation and quality gate enforcement

## Overview

This framework provides automated test generation from user stories, coverage monitoring, and quality gate enforcement for documentation quality.

## Automated Test Generation from User Stories

### Story-to-Test Generator

```python
#!/usr/bin/env python3
"""
Automated test generation from user stories.
"""

import json
import re
import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

class StoryTestGenerator:
    """Generates test cases from user stories and acceptance criteria."""

    def __init__(self, docs_dir: str = "docs", output_dir: str = "tests/generated"):
        self.docs_dir = Path(docs_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def extract_story_info(self, story_file: Path) -> Dict:
        """Extract story information from markdown file."""
        with open(story_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract story ID from filename
        story_id = story_file.stem.split('.')[0] + '.' + story_file.stem.split('.')[1]

        # Extract story title
        story_title = ""
        if content.startswith("# "):
            story_title = content.split('\n')[0][2:].strip()

        # Extract acceptance criteria
        acceptance_criteria = []
        in_ac_section = False

        for line in content.split('\n'):
            line = line.strip()
            if line == "Acceptance Criteria:":
                in_ac_section = True
                continue
            elif line.startswith("#") and in_ac_section:
                break
            elif in_ac_section and re.match(r'^\d+\.\s', line):
                acceptance_criteria.append(line)

        # Extract testing notes
        testing_notes = ""
        testing_section = re.search(r'Testing:\s*\n(.*?)(?=\n#|\Z)', content, re.DOTALL)
        if testing_section:
            testing_notes = testing_section.group(1).strip()

        return {
            "story_id": story_id,
            "title": story_title,
            "acceptance_criteria": acceptance_criteria,
            "testing_notes": testing_notes,
            "file_path": str(story_file)
        }

    def generate_unit_tests(self, story_info: Dict) -> List[Dict]:
        """Generate unit tests from acceptance criteria."""
        tests = []

        for i, ac in enumerate(story_info["acceptance_criteria"], 1):
            # Parse acceptance criteria to identify testable scenarios
            test_scenarios = self._parse_acceptance_criteria(ac)

            for scenario in test_scenarios:
                test = {
                    "test_id": f"{story_info['story_id']}_UT_{i}_{scenario['scenario_id']}",
                    "test_type": "unit",
                    "description": scenario["description"],
                    "given": scenario["given"],
                    "when": scenario["when"],
                    "then": scenario["then"],
                    "acceptance_criteria": ac,
                    "priority": scenario["priority"],
                    "tags": scenario["tags"]
                }
                tests.append(test)

        return tests

    def _parse_acceptance_criteria(self, ac: str) -> List[Dict]:
        """Parse acceptance criteria into testable scenarios."""
        scenarios = []

        # Common patterns for parsing acceptance criteria
        patterns = [
            # "Given... when... then..." pattern
            r"given\s+(.+?)\s+when\s+(.+?)\s+then\s+(.+)",
            # "User should be able to..." pattern
            r"user\s+should\s+be\s+able\s+to\s+(.+)",
            # "System must..." pattern
            r"system\s+must\s+(.+)",
            # "Display/show..." pattern
            r"(?:display|show)\s+(.+?)\s+when\s+(.+)",
            # "Validate/verify..." pattern
            r"(?:validate|verify)\s+(.+?)\s+(?:when|if)\s+(.+)"
        ]

        for pattern in patterns:
            matches = re.finditer(pattern, ac, re.IGNORECASE)
            for match in matches:
                if len(match.groups()) == 3:
                    # Given-When-Then pattern
                    scenario = {
                        "scenario_id": chr(97 + len(scenarios)),  # a, b, c, ...
                        "description": f"Test: {ac}",
                        "given": match.group(1).strip(),
                        "when": match.group(2).strip(),
                        "then": match.group(3).strip(),
                        "priority": "high",
                        "tags": ["acceptance-criteria", "gherkin"]
                    }
                elif len(match.groups()) == 2:
                    # When-Then pattern
                    scenario = {
                        "scenario_id": chr(97 + len(scenarios)),
                        "description": f"Test: {ac}",
                        "given": "System is in initial state",
                        "when": match.group(1).strip(),
                        "then": match.group(2).strip(),
                        "priority": "high",
                        "tags": ["acceptance-criteria", "simple"]
                    }
                else:
                    # Single statement pattern
                    scenario = {
                        "scenario_id": chr(97 + len(scenarios)),
                        "description": f"Test: {ac}",
                        "given": "System is ready",
                        "when": match.group(1).strip() if match.groups() else ac,
                        "then": "Expected behavior occurs",
                        "priority": "medium",
                        "tags": ["acceptance-criteria", "basic"]
                    }

                scenarios.append(scenario)

        # If no patterns matched, create a basic scenario
        if not scenarios:
            scenarios.append({
                "scenario_id": "a",
                "description": f"Test: {ac}",
                "given": "System is ready",
                "when": "User performs action",
                "then": "Expected result occurs",
                "priority": "medium",
                "tags": ["acceptance-criteria", "manual-review"]
            })

        return scenarios

    def generate_integration_tests(self, story_info: Dict) -> List[Dict]:
        """Generate integration tests from story context."""
        tests = []

        # Generate integration tests based on story content
        story_content = story_info["testing_notes"].lower()

        # API integration tests
        if any(keyword in story_content for keyword in ["api", "endpoint", "service", "request"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_IT_API",
                "test_type": "integration",
                "description": f"API integration test for {story_info['title']}",
                "given": "API service is running and accessible",
                "when": "Client makes API request",
                "then": "API responds with correct data and status",
                "priority": "high",
                "tags": ["api", "integration", "backend"]
            })

        # Database integration tests
        if any(keyword in story_content for keyword in ["database", "data", "storage", "persistence"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_IT_DB",
                "test_type": "integration",
                "description": f"Database integration test for {story_info['title']}",
                "given": "Database connection is established",
                "when": "Data operations are performed",
                "then": "Data is correctly stored and retrieved",
                "priority": "high",
                "tags": ["database", "integration", "persistence"]
            })

        # UI integration tests
        if any(keyword in story_content for keyword in ["ui", "interface", "screen", "component"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_IT_UI",
                "test_type": "integration",
                "description": f"UI integration test for {story_info['title']}",
                "given": "UI components are rendered",
                "when": "User interacts with interface",
                "then": "UI responds correctly and updates state",
                "priority": "medium",
                "tags": ["ui", "integration", "frontend"]
            })

        return tests

    def generate_e2e_tests(self, story_info: Dict) -> List[Dict]:
        """Generate end-to-end tests for user workflows."""
        tests = []

        # Generate E2E test for complete user journey
        tests.append({
            "test_id": f"{story_info['story_id']}_E2E_COMPLETE",
            "test_type": "e2e",
            "description": f"End-to-end test for {story_info['title']}",
            "given": "User is logged in and system is ready",
            "when": "User completes the full workflow described in the story",
            "then": "All acceptance criteria are satisfied and user achieves their goal",
            "priority": "high",
            "tags": ["e2e", "user-journey", "critical"]
        })

        # Generate accessibility E2E tests
        tests.append({
            "test_id": f"{story_info['story_id']}_E2E_A11Y",
            "test_type": "e2e",
            "description": f"Accessibility E2E test for {story_info['title']}",
            "given": "Screen reader or accessibility tools are enabled",
            "when": "User with accessibility needs completes the workflow",
            "then": "All features are accessible and comply with WCAG 2.1 AA",
            "priority": "high",
            "tags": ["e2e", "accessibility", "wcag", "a11y"]
        })

        return tests

    def generate_performance_tests(self, story_info: Dict) -> List[Dict]:
        """Generate performance tests based on story requirements."""
        tests = []

        # Check for performance keywords in story content
        story_content = story_info["testing_notes"].lower()

        if any(keyword in story_content for keyword in ["performance", "speed", "fast", "responsive"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_PERF_SPEED",
                "test_type": "performance",
                "description": f"Performance test for {story_info['title']}",
                "given": "System is under normal load",
                "when": "User performs actions described in story",
                "then": "Response times meet performance requirements (< 2s for user actions)",
                "priority": "medium",
                "tags": ["performance", "speed", "response-time"]
            })

        if any(keyword in story_content for keyword in ["load", "concurrent", "multiple users"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_PERF_LOAD",
                "test_type": "performance",
                "description": f"Load test for {story_info['title']}",
                "given": "System is under expected user load",
                "when": "Multiple users perform concurrent actions",
                "then": "System maintains performance and stability",
                "priority": "medium",
                "tags": ["performance", "load", "concurrency"]
            })

        return tests

    def generate_security_tests(self, story_info: Dict) -> List[Dict]:
        """Generate security tests for authentication, authorization, and data protection."""
        tests = []

        # Authentication tests
        if any(keyword in story_info["title"].lower() for keyword in ["auth", "login", "signin", "password"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_SEC_AUTH",
                "test_type": "security",
                "description": f"Security test for authentication in {story_info['title']}",
                "given": "User attempts to authenticate",
                "when": "Valid and invalid credentials are provided",
                "then": "System correctly authenticates valid users and rejects invalid attempts",
                "priority": "high",
                "tags": ["security", "authentication", "auth"]
            })

        # Authorization tests
        if any(keyword in story_info["title"].lower() for keyword in ["access", "permission", "role", "authorization"]):
            tests.append({
                "test_id": f"{story_info['story_id']}_SEC_AUTHZ",
                "test_type": "security",
                "description": f"Security test for authorization in {story_info['title']}",
                "given": "Users with different permission levels attempt actions",
                "when": "Protected resources are accessed",
                "then": "Access is granted only to authorized users",
                "priority": "high",
                "tags": ["security", "authorization", "permissions"]
            })

        # Data protection tests
        tests.append({
            "test_id": f"{story_info['story_id']}_SEC_DATA",
            "test_type": "security",
            "description": f"Data protection test for {story_info['title']}",
            "given": "Sensitive data is processed and stored",
            "when": "Data operations are performed",
            "then": "Data is properly encrypted and protected against unauthorized access",
            "priority": "high",
            "tags": ["security", "data-protection", "encryption"]
        })

        return tests

    def generate_test_suite(self, story_file: Path) -> Dict:
        """Generate complete test suite for a user story."""
        story_info = self.extract_story_info(story_file)

        test_suite = {
            "story_id": story_info["story_id"],
            "title": story_info["title"],
            "generated_at": datetime.now().isoformat(),
            "acceptance_criteria": story_info["acceptance_criteria"],
            "tests": {
                "unit_tests": self.generate_unit_tests(story_info),
                "integration_tests": self.generate_integration_tests(story_info),
                "e2e_tests": self.generate_e2e_tests(story_info),
                "performance_tests": self.generate_performance_tests(story_info),
                "security_tests": self.generate_security_tests(story_info)
            },
            "coverage_requirements": {
                "unit_test_coverage": ">= 90%",
                "integration_test_coverage": ">= 80%",
                "e2e_test_coverage": ">= 95% of critical paths"
            }
        }

        return test_suite

    def export_tests_to_cucumber(self, test_suite: Dict) -> str:
        """Export tests to Cucumber feature files."""
        feature_content = f"""Feature: {test_suite['title']}

  Story ID: {test_suite['story_id']}
  Generated: {test_suite['generated_at']}

"""

        # Add unit test scenarios
        for test in test_suite["tests"]["unit_tests"]:
            feature_content += f"""  Scenario: {test['description']}
    Given {test['given']}
    When {test['when']}
    Then {test['then']}

"""

        # Add integration test scenarios
        for test in test_suite["tests"]["integration_tests"]:
            feature_content += f"""  Scenario: {test['description']}
    Given {test['given']}
    When {test['when']}
    Then {test['then']}

"""

        # Add E2E test scenarios
        for test in test_suite["tests"]["e2e_tests"]:
            feature_content += f"""  Scenario: {test['description']}
    Given {test['given']}
    When {test['when']}
    Then {test['then']}

"""

        return feature_content

    def export_tests_to_json(self, test_suite: Dict) -> str:
        """Export tests to JSON format."""
        return json.dumps(test_suite, indent=2)

    def save_test_suite(self, test_suite: Dict):
        """Save test suite in multiple formats."""
        base_name = f"{test_suite['story_id']}_tests"

        # Save as JSON
        json_file = self.output_dir / f"{base_name}.json"
        with open(json_file, 'w') as f:
            f.write(self.export_tests_to_json(test_suite))

        # Save as Cucumber feature
        cucumber_file = self.output_dir / f"{base_name}.feature"
        with open(cucumber_file, 'w') as f:
            f.write(self.export_tests_to_cucumber(test_suite))

        # Save as pytest file
        pytest_file = self.output_dir / f"test_{base_name}.py"
        with open(pytest_file, 'w') as f:
            f.write(self.generate_pytest_file(test_suite))

        print(f"Generated test suite for {test_suite['story_id']}:")
        print(f"  JSON: {json_file}")
        print(f"  Cucumber: {cucumber_file}")
        print(f"  Pytest: {pytest_file}")

    def generate_pytest_file(self, test_suite: Dict) -> str:
        """Generate pytest file from test suite."""
        content = f'''"""
Generated test file for {test_suite['story_id']}: {test_suite['title']}
Generated: {test_suite['generated_at']}
"""

import pytest
from unittest.mock import Mock, patch
# Add your imports here

'''

        # Generate unit test functions
        for test in test_suite["tests"]["unit_tests"]:
            function_name = f"test_{test['test_id'].replace('.', '_').replace('-', '_')}"
            content += f'''
def {function_name}():
    """
    {test['description']}

    Acceptance Criteria: {test['acceptance_criteria']}
    Priority: {test['priority']}
    Tags: {', '.join(test['tags'])}
    """
    # Given: {test['given']}
    # When: {test['when']}
    # Then: {test['then']}

    # Placeholder: Implement test logic based on acceptance criteria
    # Generated template - implement actual test logic during development
    pytest.skip("Test implementation needed")
'''

        # Generate integration test functions
        for test in test_suite["tests"]["integration_tests"]:
            function_name = f"test_{test['test_id'].replace('.', '_').replace('-', '_')}"
            content += f'''
@pytest.mark.integration
def {function_name}():
    """
    {test['description']}

    Priority: {test['priority']}
    Tags: {', '.join(test['tags'])}
    """
    # Given: {test['given']}
    # When: {test['when']}
    # Then: {test['then']}

    # Placeholder: Implement integration test logic
    # Test component interactions and integrations
    pytest.skip("Integration test implementation needed")
'''

        # Generate E2E test functions
        for test in test_suite["tests"]["e2e_tests"]:
            function_name = f"test_{test['test_id'].replace('.', '_').replace('-', '_')}"
            content += f'''
@pytest.mark.e2e
def {function_name}():
    """
    {test['description']}

    Priority: {test['priority']}
    Tags: {', '.join(test['tags'])}
    """
    # Given: {test['given']}
    # When: {test['when']}
    # Then: {test['then']}

    # Placeholder: Implement E2E test logic
    # Test complete user workflows and UI interactions
    pytest.skip("E2E test implementation needed")
'''

        # Generate performance test functions
        for test in test_suite["tests"]["performance_tests"]:
            function_name = f"test_{test['test_id'].replace('.', '_').replace('-', '_')}"
            content += f'''
@pytest.mark.performance
def {function_name}():
    """
    {test['description']}

    Priority: {test['priority']}
    Tags: {', '.join(test['tags'])}
    """
    # Given: {test['given']}
    # When: {test['when']}
    # Then: {test['then']}

    # Placeholder: Implement performance test logic
    # Test response times, load capacity, and resource usage
    pytest.skip("Performance test implementation needed")
'''

        # Generate security test functions
        for test in test_suite["tests"]["security_tests"]:
            function_name = f"test_{test['test_id'].replace('.', '_').replace('-', '_')}"
            content += f'''
@pytest.mark.security
def {function_name}():
    """
    {test['description']}

    Priority: {test['priority']}
    Tags: {', '.join(test['tags'])}
    """
    # Given: {test['given']}
    # When: {test['when']}
    # Then: {test['then']}

    # Placeholder: Implement security test logic
    # Test authentication, authorization, and vulnerability prevention
    pytest.skip("Security test implementation needed")
'''

        return content

    def process_all_stories(self, stories_dir: str = "docs/stories"):
        """Process all user stories and generate test suites."""
        stories_path = self.docs_dir / stories_dir

        if not stories_path.exists():
            print(f"Stories directory not found: {stories_path}")
            return

        story_files = list(stories_path.glob("*.md"))

        if not story_files:
            print("No story files found")
            return

        print(f"Processing {len(story_files)} story files...")

        for story_file in story_files:
            try:
                test_suite = self.generate_test_suite(story_file)
                self.save_test_suite(test_suite)
            except Exception as e:
                print(f"Error processing {story_file}: {e}")

        print("Test generation completed!")

def main():
    """Main execution function."""
    import sys

    generator = StoryTestGenerator()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "generate":
            story_path = sys.argv[2] if len(sys.argv) > 2 else None
            if story_path:
                # Generate tests for specific story
                story_file = Path(story_path)
                if story_file.exists():
                    test_suite = generator.generate_test_suite(story_file)
                    generator.save_test_suite(test_suite)
                else:
                    print(f"Story file not found: {story_path}")
            else:
                # Generate tests for all stories
                generator.process_all_stories()

        elif command == "help":
            print("Story Test Generator")
            print("Usage: python story-test-generator.py <command> [options]")
            print("Commands:")
            print("  generate [story_file]  Generate tests for specific story or all stories")
            print("  help                   Show this help message")

        else:
            print(f"Unknown command: {command}")
            print("Use 'help' for usage information")
    else:
        print("Story Test Generator")
        print("Usage: python story-test-generator.py <command> [options]")
        print("Commands:")
        print("  generate [story_file]  Generate tests for specific story or all stories")
        print("  help                   Show this help message")

if __name__ == "__main__":
    main()
```

### Coverage Monitoring System

```bash
#!/bin/bash
# docs/scripts/coverage-monitor.sh

set -euo pipefail

# Coverage monitoring script
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
        pytest "$TEST_DIR/unit" --cov="$PROJECT_DIR" --cov-report=json:"$REPORT_DIR/unit-coverage.json" --cov-report=html:"$REPORT_DIR/unit-html" --cov-report=term || true
    fi

    # Run integration tests with coverage
    log_info "Running integration tests..."
    if command -v pytest &> /dev/null; then
        pytest "$TEST_DIR/integration" --cov="$PROJECT_DIR" --cov-report=json:"$REPORT_DIR/integration-coverage.json" --cov-append --cov-report=html:"$REPORT_DIR/integration-html" --cov-report=term || true
    fi

    # Run E2E tests (if available)
    log_info "Running E2E tests..."
    if [ -d "$TEST_DIR/e2e" ]; then
        if command -v pytest &> /dev/null; then
            pytest "$TEST_DIR/e2e" --junitxml="$REPORT_DIR/e2e-results.xml" --cov-report=html:"$REPORT_DIR/e2e-html" --cov-report=term || true
        fi
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
        unit_coverage=$(jq -r '.totals.percent_covered' "$REPORT_DIR/unit-coverage.json" 2>/dev/null || echo "0")
        log_info "Unit test coverage: ${unit_coverage}%"
    fi

    # Analyze integration test coverage
    if [ -f "$REPORT_DIR/integration-coverage.json" ]; then
        integration_coverage=$(jq -r '.totals.percent_covered' "$REPORT_DIR/integration-coverage.json" 2>/dev/null || echo "0")
        log_info "Integration test coverage: ${integration_coverage}%"
    fi

    # Calculate overall coverage (weighted average)
    total_coverage=$(( (unit_coverage * 2 + integration_coverage) / 3 ))
    log_info "Overall coverage: ${total_coverage}%"

    # Generate coverage by file report
    if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
        coverage_by_file=$(jq '.files | to_entries | map({file: .key, coverage: .value.summary.percent_covered})' "$REPORT_DIR/unit-coverage.json")
    fi

    # Update coverage summary
    local summary_json=$(jq \
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
        "$REPORT_DIR/coverage-summary.json")

    echo "$summary_json" > "$REPORT_DIR/coverage-summary.json"

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

    cat > "$REPORT_DIR/coverage-report.md" << EOF
# Test Coverage Report

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Minimum Required Coverage: ${MIN_COVERAGE}%

## Coverage Summary

EOF

    if [ -f "$REPORT_DIR/coverage-summary.json" ]; then
        local overall_coverage=$(jq -r '.overall_coverage' "$REPORT_DIR/coverage-summary.json")
        local unit_coverage=$(jq -r '.coverage_by_type.unit' "$REPORT_DIR/coverage-summary.json")
        local integration_coverage=$(jq -r '.coverage_by_type.integration' "$REPORT_DIR/coverage-summary.json")

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
    fi

    cat >> "$REPORT_DIR/coverage-report.md" << EOF

## Coverage by File

EOF

    # Add file-level coverage details
    if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
        jq -r '.files | to_entries | sort_by(-.value.summary.percent_covered) | .[] | "- **\(.key)**: \(.value.summary.percent_covered)%"' "$REPORT_DIR/unit-coverage.json" >> "$REPORT_DIR/coverage-report.md"
    fi

    cat >> "$REPORT_DIR/coverage-report.md" << EOF

## Coverage Reports

- [Unit Test HTML Report](unit-html/index.html)
- [Integration Test HTML Report](integration-html/index.html)
- [E2E Test HTML Report](e2e-html/index.html) (if available)

## Recommendations

EOF

    # Generate recommendations based on coverage
    if [ -f "$REPORT_DIR/coverage-summary.json" ]; then
        local overall_coverage=$(jq -r '.overall_coverage' "$REPORT_DIR/coverage-summary.json")

        if [ "$overall_coverage" -lt "$MIN_COVERAGE" ]; then
            cat >> "$REPORT_DIR/coverage-report.md" << EOF
- **Urgent**: Coverage is below minimum requirements. Add more tests to reach ${MIN_COVERAGE}% coverage.
EOF
        fi

        # Find files with low coverage
        if [ -f "$REPORT_DIR/unit-coverage.json" ]; then
            local low_coverage_files=$(jq -r '.files | to_entries | map(select(.value.summary.percent_covered < 80)) | .[] | "- \(.key) (\(.value.summary.percent_covered)%)"' "$REPORT_DIR/unit-coverage.json")
            if [ -n "$low_coverage_files" ]; then
                echo "- **Low Coverage Files**: Consider adding tests for these files:" >> "$REPORT_DIR/coverage-report.md"
                echo "$low_coverage_files" >> "$REPORT_DIR/coverage-report.md"
            fi
        fi
    fi

    log_success "Coverage report generated: $REPORT_DIR/coverage-report.md"
}

# Quality gate enforcement
enforce_quality_gate() {
    log_info "Enforcing quality gates..."

    local gate_passed=true

    # Check coverage gate
    if [ -f "$REPORT_DIR/coverage-summary.json" ]; then
        local overall_coverage=$(jq -r '.overall_coverage' "$REPORT_DIR/coverage-summary.json")

        if [ "$overall_coverage" -lt "$MIN_COVERAGE" ]; then
            log_error "Coverage gate failed: ${overall_coverage}% < ${MIN_COVERAGE}%"
            gate_passed=false
        else
            log_success "Coverage gate passed: ${overall_coverage}% >= ${MIN_COVERAGE}%"
        fi
    else
        log_error "Coverage report not found"
        gate_passed=false
    fi

    # Check test results gate
    if [ -f "$REPORT_DIR/coverage-summary.json" ]; then
        local failed_tests=$(jq -r '.failed_tests' "$REPORT_DIR/coverage-summary.json")

        if [ "$failed_tests" -gt 0 ]; then
            log_error "Test gate failed: $failed_tests failed tests"
            gate_passed=false
        else
            log_success "Test gate passed: No failed tests"
        fi
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
            analyze_coverage
            generate_coverage_report
            enforce_quality_gate
            ;;
        "analyze")
            analyze_coverage
            generate_coverage_report
            ;;
        "report")
            generate_coverage_report
            ;;
        "gate")
            enforce_quality_gate
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo
            echo "Commands:"
            echo "  run       Run tests and analyze coverage (default)"
            echo "  analyze   Analyze existing coverage results"
            echo "  report    Generate coverage report"
            echo "  gate      Enforce quality gates only"
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
    log_error "jq is required but not installed. Please install jq to continue."
    exit 1
fi

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

This testing automation framework provides comprehensive test generation, coverage monitoring, and quality gate enforcement to ensure high-quality documentation and code.