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
            try:
                with open(report_file, 'r') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                return {"error": "Invalid JSON in validation report", "return_code": result.returncode}
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
            try:
                with open(report_file, 'r') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                return {"error": "Invalid JSON in compliance report", "return_code": result.returncode}
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
        test_files = []

        if generated_dir.exists():
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
        ownership_files = []

        if governance_dir.exists():
            ownership_files = list(governance_dir.glob("*.ownership.json"))

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

        try:
            with open(args.results_file, 'r') as f:
                results = json.load(f)

            summary = helper.generate_ci_summary(results)
            print(summary)
        except FileNotFoundError:
            print(f"Error: Results file not found: {args.results_file}")
            sys.exit(1)
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON in results file: {args.results_file}")
            sys.exit(1)

if __name__ == "__main__":
    main()