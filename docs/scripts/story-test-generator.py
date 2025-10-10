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
    # This is a generated template - actual implementation should include:
    # 1. Setup test data and mocks
    # 2. Execute the function/method being tested
    # 3. Assert expected outcomes based on AC
    # Example:
    # mock_service = Mock()
    # result = function_under_test(test_data, mock_service)
    # assert result.expected_property == test['expected_value']
    pytest.skip("Test implementation needed - replace with actual test logic")
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
    # This should test the interaction between multiple components
    # Include setup of test environment, API mocking, database interactions
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
    # This should test complete user workflows through the UI
    # Include browser automation, user interactions, and full stack testing
    pytest.skip("E2E test implementation needed - requires browser/automation setup")
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
    # This should test response times, throughput, and resource usage
    # Include load testing, stress testing, and benchmarking
    pytest.skip("Performance test implementation needed - requires performance testing setup")
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
    # This should test authentication, authorization, input validation, and vulnerabilities
    # Include penetration testing, input fuzzing, and security scan integration
    pytest.skip("Security test implementation needed - requires security testing expertise")
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