#!/usr/bin/env python3
"""
Automated review assignment system for documentation.
"""

import json
import os
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import random

class ReviewAssignmentEngine:
    """Automated review assignment based on expertise and availability."""

    def __init__(self, config_path: str = "docs/quality-automation/review-config.json"):
        self.config_path = config_path
        self.config = self._load_config()
        self.docs_dir = Path(self.config.get("docs_directory", "docs"))

    def _load_config(self) -> Dict:
        """Load review configuration."""
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                return json.load(f)
        return self._get_default_config()

    def _get_default_config(self) -> Dict:
        """Get default configuration."""
        return {
            "docs_directory": "docs",
            "reviewers": {
                "technical": {
                    "required": 1,
                    "expertise": ["architecture", "technical-decisions", "coding-standards"],
                    "assigned_to": ["tech-lead", "architect"]
                },
                "domain": {
                    "required": 1,
                    "expertise": ["user-stories", "acceptance-criteria", "business-logic"],
                    "assigned_to": ["product-owner", "business-analyst"]
                },
                "qa": {
                    "required": 1,
                    "expertise": ["testing", "quality-assurance", "validation"],
                    "assigned_to": ["qa-lead", "test-engineer"]
                }
            },
            "auto_assignment": {
                "enabled": True,
                "load_balancing": True,
                "consider_expertise": True,
                "avoid_conflicts": True
            },
            "review_deadlines": {
                "standard": 3,  # days
                "urgent": 1,   # days
                "complex": 5    # days
            }
        }

    def detect_document_type(self, file_path: Path) -> str:
        """Detect document type from file path and content."""
        file_name = file_path.name
        relative_path = file_path.relative_to(self.docs_dir)

        # Directory-based detection
        if "stories" in str(relative_path):
            return "user-story"
        elif "adr" in str(relative_path):
            return "technical-decision"
        elif "qa/assessments" in str(relative_path):
            return "qa-assessment"
        elif "architecture" in str(relative_path):
            return "architecture"
        elif "sessions" in str(relative_path):
            return "checkpoint"

        # Filename pattern detection
        if re.match(r'^\d+\.\d+\.', file_name):
            return "user-story"
        elif re.match(r'^ADR-\d{4}-', file_name):
            return "technical-decision"
        elif re.match(r'^\d+\.\d+-(risk|nfr)-\d{8}', file_name):
            return "qa-assessment"

        return "general"

    def assess_document_complexity(self, file_path: Path) -> str:
        """Assess document complexity based on content."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Complexity indicators
            word_count = len(content.split())
            section_count = len(re.findall(r'^#+\s', content, re.MULTILINE))
            code_blocks = len(re.findall(r'```', content))
            links = len(re.findall(r'\[.*\]\(.*\)', content))

            # Complexity scoring
            score = 0
            if word_count > 2000:
                score += 1
            if section_count > 10:
                score += 1
            if code_blocks > 5:
                score += 1
            if links > 20:
                score += 1

            # Determine complexity level
            if score >= 3:
                return "complex"
            elif score >= 1:
                return "standard"
            else:
                return "simple"

        except Exception as e:
            print(f"Error assessing complexity for {file_path}: {e}")
            return "standard"

    def get_required_reviewer_types(self, doc_type: str) -> List[str]:
        """Get required reviewer types based on document type."""
        requirements = {
            "user-story": ["domain", "technical"],
            "technical-decision": ["technical", "domain"],
            "qa-assessment": ["qa", "technical"],
            "architecture": ["technical"],
            "checkpoint": ["domain", "technical"],
            "general": ["technical"]
        }
        return requirements.get(doc_type, ["technical"])

    def select_reviewers(self, doc_type: str, complexity: str) -> Dict[str, List[str]]:
        """Select reviewers based on document type and complexity."""
        required_types = self.get_required_reviewer_types(doc_type)
        selected_reviewers = {}

        for review_type in required_types:
            if review_type in self.config["reviewers"]:
                reviewer_config = self.config["reviewers"][review_type]
                num_required = reviewer_config["required"]

                if complexity == "complex":
                    num_required += 1

                available_reviewers = reviewer_config["assigned_to"]

                if self.config["auto_assignment"]["load_balancing"]:
                    selected_reviewers[review_type] = self._balance_load(
                        available_reviewers, num_required
                    )
                else:
                    selected_reviewers[review_type] = random.sample(
                        available_reviewers,
                        min(num_required, len(available_reviewers))
                    )

        return selected_reviewers

    def _balance_load(self, reviewers: List[str], num_needed: int) -> List[str]:
        """Balance review load among reviewers."""
        # Simple load balancing - in production, this would query actual load
        return random.sample(reviewers, min(num_needed, len(reviewers)))

    def calculate_deadline(self, complexity: str) -> datetime:
        """Calculate review deadline based on complexity."""
        deadline_days = self.config["review_deadlines"].get(complexity, 3)
        return datetime.now() + timedelta(days=deadline_days)

    def create_review_assignment(self, file_path: Path) -> Dict:
        """Create a review assignment for a document."""
        doc_type = self.detect_document_type(file_path)
        complexity = self.assess_document_complexity(file_path)
        reviewers = self.select_reviewers(doc_type, complexity)
        deadline = self.calculate_deadline(complexity)

        assignment = {
            "file_path": str(file_path),
            "document_type": doc_type,
            "complexity": complexity,
            "reviewers": reviewers,
            "deadline": deadline.isoformat(),
            "status": "pending",
            "created_at": datetime.now().isoformat(),
            "reviews": []
        }

        return assignment

    def scan_for_new_documents(self) -> List[Path]:
        """Scan for documents that need review assignment."""
        new_documents = []

        for markdown_file in self.docs_dir.rglob("*.md"):
            # Skip certain files
            if any(pattern in str(markdown_file) for pattern in
                   ["node_modules", ".git", ".DS_Store", "README.md", ".review"]):
                continue

            # Check if document already has review assignment
            if not self._has_review_assignment(markdown_file):
                new_documents.append(markdown_file)

        return new_documents

    def _has_review_assignment(self, file_path: Path) -> bool:
        """Check if a document already has a review assignment."""
        # Look for review assignment file
        review_file = file_path.parent / f".{file_path.stem}.review.json"
        return review_file.exists()

    def assign_reviews(self) -> List[Dict]:
        """Assign reviews to new documents."""
        new_documents = self.scan_for_new_documents()
        assignments = []

        for doc_path in new_documents:
            assignment = self.create_review_assignment(doc_path)
            assignments.append(assignment)

            # Save assignment
            self._save_assignment(assignment)

            print(f"Assigned review for {doc_path}: {assignment['reviewers']}")

        return assignments

    def _save_assignment(self, assignment: Dict):
        """Save review assignment to file."""
        doc_path = Path(assignment["file_path"])
        review_file = doc_path.parent / f".{doc_path.stem}.review.json"

        with open(review_file, 'w') as f:
            json.dump(assignment, f, indent=2)

    def generate_review_summary(self) -> Dict:
        """Generate summary of current review assignments."""
        summary = {
            "generated_at": datetime.now().isoformat(),
            "total_assignments": 0,
            "pending_reviews": 0,
            "completed_reviews": 0,
            "overdue_reviews": 0,
            "reviewer_load": {},
            "documents_by_type": {},
            "documents_by_complexity": {}
        }

        # Scan for all review assignments
        for review_file in self.docs_dir.rglob(".*.review.json"):
            try:
                with open(review_file, 'r') as f:
                    assignment = json.load(f)

                summary["total_assignments"] += 1

                # Status counts
                if assignment["status"] == "completed":
                    summary["completed_reviews"] += 1
                else:
                    summary["pending_reviews"] += 1

                # Check for overdue
                deadline = datetime.fromisoformat(assignment["deadline"])
                if deadline < datetime.now() and assignment["status"] != "completed":
                    summary["overdue_reviews"] += 1

                # Reviewer load
                for review_type, reviewers in assignment["reviewers"].items():
                    for reviewer in reviewers:
                        summary["reviewer_load"][reviewer] = summary["reviewer_load"].get(reviewer, 0) + 1

                # Document type breakdown
                doc_type = assignment["document_type"]
                summary["documents_by_type"][doc_type] = summary["documents_by_type"].get(doc_type, 0) + 1

                # Complexity breakdown
                complexity = assignment["complexity"]
                summary["documents_by_complexity"][complexity] = summary["documents_by_complexity"].get(complexity, 0) + 1

            except Exception as e:
                print(f"Error reading review file {review_file}: {e}")

        return summary

def main():
    """Main execution function."""
    engine = ReviewAssignmentEngine()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "assign":
            print("Assigning reviews to new documents...")
            assignments = engine.assign_reviews()
            print(f"Assigned {len(assignments)} reviews")

        elif command == "summary":
            print("Generating review summary...")
            summary = engine.generate_review_summary()
            print(json.dumps(summary, indent=2))

        elif command == "scan":
            print("Scanning for new documents...")
            new_docs = engine.scan_for_new_documents()
            print(f"Found {len(new_docs)} documents needing review:")
            for doc in new_docs:
                print(f"  - {doc}")

        else:
            print(f"Unknown command: {command}")
            print("Available commands: assign, summary, scan")

    else:
        print("Review Assignment Engine")
        print("Usage: python review-assignment.py <command>")
        print("Commands:")
        print("  assign   - Assign reviews to new documents")
        print("  summary  - Generate review summary")
        print("  scan     - Scan for documents needing review")

if __name__ == "__main__":
    main()