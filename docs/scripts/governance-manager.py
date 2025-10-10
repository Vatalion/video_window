#!/usr/bin/env python3
"""
Automated ownership assignment and tracking system for documentation governance.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime, timedelta

class GovernanceManager:
    """Manages documentation governance, ownership, and compliance."""

    def __init__(self, config_path: str = "docs/quality-automation/ownership-matrix.yml"):
        self.config_path = config_path
        self.ownership_matrix = self._load_ownership_matrix()
        self.docs_dir = Path("docs")
        self.governance_dir = Path("docs/quality-automation/governance")
        self.governance_dir.mkdir(parents=True, exist_ok=True)

    def _load_ownership_matrix(self) -> Dict:
        """Load ownership matrix from configuration file."""
        try:
            import yaml
            with open(self.config_path, 'r') as f:
                return yaml.safe_load(f)
        except ImportError:
            print("PyYAML not installed, using default configuration")
            return self._get_default_ownership_matrix()
        except FileNotFoundError:
            print(f"Ownership matrix file not found: {self.config_path}")
            return self._get_default_ownership_matrix()

    def _get_default_ownership_matrix(self) -> Dict:
        """Get default ownership matrix configuration."""
        return {
            "ownership_matrix": {
                "document_types": {
                    "user_stories": {
                        "primary_owner": "product-owner",
                        "review_frequency": "bi-weekly",
                        "retention_period": "permanent"
                    },
                    "technical_decisions": {
                        "primary_owner": "architect",
                        "review_frequency": "monthly",
                        "retention_period": "permanent"
                    },
                    "architecture_documents": {
                        "primary_owner": "architect",
                        "review_frequency": "quarterly",
                        "retention_period": "permanent"
                    }
                }
            }
        }

    def detect_document_type(self, file_path: Path) -> str:
        """Detect document type from file path and content."""
        relative_path = file_path.relative_to(self.docs_dir)
        path_str = str(relative_path).lower()
        filename = file_path.name.lower()

        # Directory-based detection
        if "stories" in path_str:
            return "user_stories"
        elif "adr" in path_str or "technical-decisions" in path_str:
            return "technical_decisions"
        elif "architecture" in path_str:
            return "architecture_documents"
        elif "qa/assessments" in path_str:
            return "qa_assessments"
        elif "api" in path_str:
            return "api_documentation"
        elif "user-guide" in path_str or "guides" in path_str:
            return "user_guides"
        elif "compliance" in path_str:
            return "compliance_documents"

        # Filename pattern detection
        if filename.startswith("adr-"):
            return "technical_decisions"
        elif filename.startswith("readme"):
            return "general_documentation"

        return "general_documentation"

    def assign_ownership(self, file_path: Path) -> Dict:
        """Assign ownership based on document type."""
        doc_type = self.detect_document_type(file_path)
        ownership_config = self.ownership_matrix["ownership_matrix"]["document_types"].get(doc_type, {})

        return {
            "file_path": str(file_path),
            "document_type": doc_type,
            "primary_owner": ownership_config.get("primary_owner", "unassigned"),
            "secondary_owners": ownership_config.get("secondary_owners", []),
            "contributors": ownership_config.get("contributors", []),
            "approvers": ownership_config.get("approvers", []),
            "review_frequency": ownership_config.get("review_frequency", "monthly"),
            "retention_period": ownership_config.get("retention_period", "permanent"),
            "assigned_at": datetime.now().isoformat(),
            "last_reviewed": None,
            "next_review": self._calculate_next_review(ownership_config.get("review_frequency", "monthly"))
        }

    def _calculate_next_review(self, frequency: str) -> str:
        """Calculate next review date based on frequency."""
        now = datetime.now()

        if frequency == "weekly":
            next_review = now + timedelta(weeks=1)
        elif frequency == "bi-weekly":
            next_review = now + timedelta(weeks=2)
        elif frequency == "monthly":
            next_review = now + timedelta(days=30)
        elif frequency == "quarterly":
            next_review = now + timedelta(days=90)
        elif frequency == "annually":
            next_review = now + timedelta(days=365)
        else:
            next_review = now + timedelta(days=30)  # Default to monthly

        return next_review.isoformat()

    def save_ownership_record(self, ownership: Dict):
        """Save ownership record for a document."""
        file_path = Path(ownership["file_path"])
        ownership_file = self.governance_dir / f"{file_path.stem}.ownership.json"

        with open(ownership_file, 'w') as f:
            json.dump(ownership, f, indent=2)

    def process_all_documents(self):
        """Process all documents and assign ownership."""
        print("Processing all documentation files...")

        processed_count = 0
        for doc_file in self.docs_dir.rglob("*.md"):
            # Skip system files
            if any(pattern in str(doc_file) for pattern in
                   [".git", "node_modules", ".DS_Store", "quality-automation", "__pycache__"]):
                continue

            ownership = self.assign_ownership(doc_file)
            self.save_ownership_record(ownership)
            processed_count += 1

        print(f"Ownership assignment completed! Processed {processed_count} documents.")

    def generate_ownership_report(self) -> Dict:
        """Generate comprehensive ownership report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "total_documents": 0,
            "documents_by_type": {},
            "ownership_summary": {},
            "review_schedule": [],
            "overdue_reviews": []
        }

        # Process all ownership records
        for ownership_file in self.governance_dir.glob("*.ownership.json"):
            try:
                with open(ownership_file, 'r') as f:
                    ownership = json.load(f)

                report["total_documents"] += 1

                # Count by document type
                doc_type = ownership["document_type"]
                report["documents_by_type"][doc_type] = report["documents_by_type"].get(doc_type, 0) + 1

                # Count by primary owner
                primary_owner = ownership["primary_owner"]
                report["ownership_summary"][primary_owner] = report["ownership_summary"].get(primary_owner, 0) + 1

                # Add to review schedule
                next_review = datetime.fromisoformat(ownership["next_review"])
                report["review_schedule"].append({
                    "file": ownership["file_path"],
                    "document_type": doc_type,
                    "owner": primary_owner,
                    "next_review": ownership["next_review"]
                })

                # Check for overdue reviews
                if next_review < datetime.now():
                    report["overdue_reviews"].append({
                        "file": ownership["file_path"],
                        "document_type": doc_type,
                        "owner": primary_owner,
                        "overdue_since": ownership["next_review"]
                    })

            except Exception as e:
                print(f"Error processing ownership file {ownership_file}: {e}")

        # Sort review schedule by next review date
        report["review_schedule"].sort(key=lambda x: x["next_review"])

        return report

    def save_ownership_report(self, report: Dict):
        """Save ownership report to file."""
        report_file = self.governance_dir / f"ownership-report-{datetime.now().strftime('%Y%m%d')}.json"

        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Ownership report saved: {report_file}")
        return report_file

    def check_governance_compliance(self) -> Dict:
        """Check governance compliance across all documents."""
        compliance_report = {
            "checked_at": datetime.now().isoformat(),
            "compliance_score": 0,
            "issues": [],
            "recommendations": []
        }

        total_checks = 0
        passed_checks = 0

        # Check ownership assignment
        ownership_files = list(self.governance_dir.glob("*.ownership.json"))
        if not ownership_files:
            compliance_report["issues"].append({
                "severity": "high",
                "category": "ownership",
                "description": "No ownership records found"
            })
        else:
            passed_checks += 1
        total_checks += 1

        # Check overdue reviews
        for ownership_file in ownership_files:
            try:
                with open(ownership_file, 'r') as f:
                    ownership = json.load(f)

                next_review = datetime.fromisoformat(ownership["next_review"])
                if next_review < datetime.now():
                    compliance_report["issues"].append({
                        "severity": "medium",
                        "category": "review",
                        "description": f"Overdue review: {ownership['file_path']}",
                        "overdue_days": (datetime.now() - next_review).days
                    })
                else:
                    passed_checks += 1
                total_checks += 1

            except Exception as e:
                compliance_report["issues"].append({
                    "severity": "low",
                    "category": "data",
                    "description": f"Error reading ownership file: {ownership_file}"
                })

        # Calculate compliance score
        if total_checks > 0:
            compliance_report["compliance_score"] = (passed_checks / total_checks) * 100

        # Generate recommendations
        if compliance_report["compliance_score"] < 80:
            compliance_report["recommendations"].append("Overall compliance score is below 80% - immediate attention required")

        overdue_count = len([issue for issue in compliance_report["issues"] if issue["category"] == "review"])
        if overdue_count > 5:
            compliance_report["recommendations"].append(f"High number of overdue reviews ({overdue_count}) - consider scheduling catch-up")

        return compliance_report

def main():
    """Main execution function."""
    import sys

    manager = GovernanceManager()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "assign":
            manager.process_all_documents()

        elif command == "report":
            report = manager.generate_ownership_report()
            report_file = manager.save_ownership_report(report)
            print(json.dumps(report, indent=2))

        elif command == "compliance":
            compliance = manager.check_governance_compliance()
            print(json.dumps(compliance, indent=2))

        elif command == "help":
            print("Documentation Governance Manager")
            print("Usage: python governance-manager.py <command>")
            print("Commands:")
            print("  assign      Assign ownership to all documents")
            print("  report      Generate ownership report")
            print("  compliance  Check governance compliance")
            print("  help        Show this help message")

        else:
            print(f"Unknown command: {command}")
            print("Use 'help' for usage information")

    else:
        print("Documentation Governance Manager")
        print("Usage: python governance-manager.py <command>")
        print("Commands:")
        print("  assign      Assign ownership to all documents")
        print("  report      Generate ownership report")
        print("  compliance  Check governance compliance")
        print("  help        Show this help message")

if __name__ == "__main__":
    main()