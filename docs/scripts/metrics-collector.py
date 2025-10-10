#!/usr/bin/env python3
"""
Quality metrics data collection and aggregation system for documentation quality monitoring.
"""

import json
import os
import re
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import statistics

class QualityMetricsCollector:
    """Collects and aggregates quality metrics from various sources."""

    def __init__(self, docs_dir: str = "docs", metrics_dir: str = "docs/quality-automation/metrics"):
        self.docs_dir = Path(docs_dir)
        self.metrics_dir = Path(metrics_dir)
        self.metrics_dir.mkdir(parents=True, exist_ok=True)

    def collect_documentation_metrics(self) -> Dict:
        """Collect basic documentation metrics."""
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "total_documents": 0,
            "total_size_mb": 0,
            "documents_by_type": {},
            "documents_by_directory": {},
            "oldest_document": None,
            "newest_document": None,
            "average_document_age_days": 0
        }

        all_ages = []

        for doc_file in self.docs_dir.rglob("*.md"):
            # Skip system files
            if any(pattern in str(doc_file) for pattern in
                   [".git", "node_modules", ".DS_Store", "quality-automation", "__pycache__"]):
                continue

            metrics["total_documents"] += 1

            # Get file size
            size_bytes = doc_file.stat().st_size
            metrics["total_size_mb"] += size_bytes / (1024 * 1024)

            # Document type classification
            doc_type = self._classify_document(doc_file)
            metrics["documents_by_type"][doc_type] = metrics["documents_by_type"].get(doc_type, 0) + 1

            # Directory classification
            try:
                relative_dir = str(doc_file.parent.relative_to(self.docs_dir))
            except ValueError:
                relative_dir = str(doc_file.parent)
            metrics["documents_by_directory"][relative_dir] = metrics["documents_by_directory"].get(relative_dir, 0) + 1

            # Age tracking
            mtime = datetime.fromtimestamp(doc_file.stat().st_mtime)
            age_days = (datetime.now() - mtime).days
            all_ages.append(age_days)

            if metrics["oldest_document"] is None or age_days > metrics["oldest_document"]["age_days"]:
                metrics["oldest_document"] = {
                    "file": str(doc_file.relative_to(self.docs_dir)),
                    "age_days": age_days,
                    "last_modified": mtime.isoformat()
                }

            if metrics["newest_document"] is None or age_days < metrics["newest_document"]["age_days"]:
                metrics["newest_document"] = {
                    "file": str(doc_file.relative_to(self.docs_dir)),
                    "age_days": age_days,
                    "last_modified": mtime.isoformat()
                }

        # Calculate average age
        if all_ages:
            metrics["average_document_age_days"] = round(statistics.mean(all_ages), 1)

        return metrics

    def _classify_document(self, file_path: Path) -> str:
        """Classify document type based on path and content."""
        relative_path = file_path.relative_to(self.docs_dir)
        path_str = str(relative_path).lower()
        filename = file_path.name.lower()

        if "stories" in path_str and re.match(r'^\d+\.\d+\.', filename):
            return "user_story"
        elif "adr" in path_str or filename.startswith("adr-"):
            return "technical_decision"
        elif "architecture" in path_str:
            return "architecture"
        elif "qa" in path_str:
            return "qa_document"
        elif "user-guide" in path_str or "guides" in path_str:
            return "user_guide"
        elif "api" in path_str:
            return "api_documentation"
        elif filename.startswith("readme"):
            return "readme"
        else:
            return "general"

    def collect_quality_metrics(self) -> Dict:
        """Collect quality metrics from validation reports."""
        quality_metrics = {
            "timestamp": datetime.now().isoformat(),
            "validation_results": {},
            "compliance_results": {},
            "coverage_results": {},
            "overall_quality_score": 0
        }

        # Load validation results
        validation_file = self.metrics_dir.parent / "validation-report.json"
        if validation_file.exists():
            try:
                with open(validation_file, 'r') as f:
                    validation_data = json.load(f)
                quality_metrics["validation_results"] = validation_data
            except Exception as e:
                print(f"Error loading validation results: {e}")

        # Load compliance results
        compliance_file = self.metrics_dir.parent / "compliance-report.json"
        if compliance_file.exists():
            try:
                with open(compliance_file, 'r') as f:
                    compliance_data = json.load(f)
                quality_metrics["compliance_results"] = compliance_data
            except Exception as e:
                print(f"Error loading compliance results: {e}")

        # Load coverage results
        coverage_file = Path("reports/coverage/coverage-summary.json")
        if coverage_file.exists():
            try:
                with open(coverage_file, 'r') as f:
                    coverage_data = json.load(f)
                quality_metrics["coverage_results"] = coverage_data
            except Exception as e:
                print(f"Error loading coverage results: {e}")

        # Calculate overall quality score
        quality_metrics["overall_quality_score"] = self._calculate_quality_score(quality_metrics)

        return quality_metrics

    def _calculate_quality_score(self, metrics: Dict) -> float:
        """Calculate overall quality score from various metrics."""
        score = 0.0
        weights = {
            "validation": 0.4,
            "compliance": 0.3,
            "coverage": 0.3
        }

        # Validation score (40% weight)
        if metrics["validation_results"]:
            total_files = metrics["validation_results"].get("total_files", 1)
            passed_files = metrics["validation_results"].get("passed_files", 0)
            validation_score = (passed_files / total_files) * 100 if total_files > 0 else 0
            score += validation_score * weights["validation"]
        else:
            score += 50 * weights["validation"]  # Neutral score if no data

        # Compliance score (30% weight)
        if metrics["compliance_results"]:
            compliance_rate = metrics["compliance_results"].get("compliance_rate", 0)
            score += compliance_rate * weights["compliance"]
        else:
            score += 50 * weights["compliance"]  # Neutral score if no data

        # Coverage score (30% weight)
        if metrics["coverage_results"]:
            overall_coverage = metrics["coverage_results"].get("overall_coverage", 0)
            score += overall_coverage * weights["coverage"]
        else:
            score += 50 * weights["coverage"]  # Neutral score if no data

        return round(score, 2)

    def collect_review_metrics(self) -> Dict:
        """Collect review and governance metrics."""
        review_metrics = {
            "timestamp": datetime.now().isoformat(),
            "total_reviews": 0,
            "completed_reviews": 0,
            "pending_reviews": 0,
            "overdue_reviews": 0,
            "average_review_time_days": 0,
            "reviewer_workload": {},
            "reviews_by_type": {}
        }

        governance_dir = self.metrics_dir.parent / "governance"
        if not governance_dir.exists():
            return review_metrics

        review_times = []

        for ownership_file in governance_dir.glob("*.ownership.json"):
            try:
                with open(ownership_file, 'r') as f:
                    ownership = json.load(f)

                review_metrics["total_reviews"] += 1

                # Classify review status
                next_review = datetime.fromisoformat(ownership["next_review"])
                if next_review < datetime.now():
                    review_metrics["overdue_reviews"] += 1
                    review_metrics["pending_reviews"] += 1
                else:
                    review_metrics["pending_reviews"] += 1

                # Reviewer workload
                primary_owner = ownership["primary_owner"]
                review_metrics["reviewer_workload"][primary_owner] = review_metrics["reviewer_workload"].get(primary_owner, 0) + 1

                # Reviews by type
                doc_type = ownership["document_type"]
                review_metrics["reviews_by_type"][doc_type] = review_metrics["reviews_by_type"].get(doc_type, 0) + 1

                # Calculate review time if available
                if ownership.get("last_reviewed"):
                    last_reviewed = datetime.fromisoformat(ownership["last_reviewed"])
                    assigned_at = datetime.fromisoformat(ownership["assigned_at"])
                    review_time = (last_reviewed - assigned_at).days
                    review_times.append(review_time)

                # Count completed reviews (those with last_reviewed)
                if ownership.get("last_reviewed"):
                    review_metrics["completed_reviews"] += 1

            except Exception as e:
                print(f"Error processing ownership file {ownership_file}: {e}")

        # Calculate average review time
        if review_times:
            review_metrics["average_review_time_days"] = round(statistics.mean(review_times), 1)

        return review_metrics

    def collect_trend_metrics(self, days_back: int = 30) -> Dict:
        """Collect trend metrics over time."""
        trend_metrics = {
            "timestamp": datetime.now().isoformat(),
            "period_days": days_back,
            "quality_score_trend": [],
            "document_count_trend": [],
            "review_completion_trend": []
        }

        # Load historical data
        for days_ago in range(days_back, 0, -1):
            date = datetime.now() - timedelta(days=days_ago)
            date_str = date.strftime("%Y-%m-%d")

            # Try to load metrics for this date
            metrics_file = self.metrics_dir / f"daily-metrics-{date_str}.json"
            if metrics_file.exists():
                try:
                    with open(metrics_file, 'r') as f:
                        daily_metrics = json.load(f)

                    trend_metrics["quality_score_trend"].append({
                        "date": date_str,
                        "score": daily_metrics.get("quality_metrics", {}).get("overall_quality_score", 0)
                    })

                    trend_metrics["document_count_trend"].append({
                        "date": date_str,
                        "count": daily_metrics.get("documentation_metrics", {}).get("total_documents", 0)
                    })

                    trend_metrics["review_completion_trend"].append({
                        "date": date_str,
                        "completed": daily_metrics.get("review_metrics", {}).get("completed_reviews", 0),
                        "pending": daily_metrics.get("review_metrics", {}).get("pending_reviews", 0)
                    })
                except Exception as e:
                    print(f"Error loading trend data for {date_str}: {e}")

        return trend_metrics

    def generate_comprehensive_report(self) -> Dict:
        """Generate comprehensive quality metrics report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "documentation_metrics": self.collect_documentation_metrics(),
            "quality_metrics": self.collect_quality_metrics(),
            "review_metrics": self.collect_review_metrics(),
            "trend_metrics": self.collect_trend_metrics()
        }

        # Add calculated insights
        report["insights"] = self._generate_insights(report)

        return report

    def _generate_insights(self, report: Dict) -> Dict:
        """Generate actionable insights from metrics."""
        insights = {
            "quality_trends": [],
            "recommendations": [],
            "alerts": []
        }

        # Quality trend analysis
        quality_score = report["quality_metrics"]["overall_quality_score"]
        if quality_score < 70:
            insights["alerts"].append({
                "severity": "high",
                "message": f"Quality score ({quality_score}) is below acceptable threshold",
                "recommendation": "Immediate attention required to improve documentation quality"
            })
        elif quality_score < 85:
            insights["recommendations"].append({
                "priority": "medium",
                "message": f"Quality score ({quality_score}) could be improved",
                "recommendation": "Focus on addressing validation failures and compliance issues"
            })

        # Review backlog analysis
        overdue_reviews = report["review_metrics"]["overdue_reviews"]
        total_reviews = report["review_metrics"]["total_reviews"]
        if total_reviews > 0:
            overdue_percentage = (overdue_reviews / total_reviews) * 100
            if overdue_percentage > 20:
                insights["alerts"].append({
                    "severity": "medium",
                    "message": f"{overdue_percentage:.1f}% of reviews are overdue",
                    "recommendation": "Schedule review catch-up sessions and reevaluate reviewer workload"
                })

        # Document growth analysis
        doc_metrics = report["documentation_metrics"]
        if doc_metrics["average_document_age_days"] > 90:
            insights["recommendations"].append({
                "priority": "low",
                "message": "Average document age is high",
                "recommendation": "Consider reviewing and updating older documentation"
            })

        # Validation failure analysis
        validation_results = report["quality_metrics"].get("validation_results", {})
        if validation_results.get("failed_files", 0) > 0:
            total_files = validation_results.get("total_files", 1)
            failure_rate = (validation_results["failed_files"] / total_files) * 100
            if failure_rate > 10:
                insights["recommendations"].append({
                    "priority": "medium",
                    "message": f"{failure_rate:.1f}% of documents failed validation",
                    "recommendation": "Address validation failures to improve overall quality"
                })

        return insights

    def save_metrics(self, metrics: Dict, filename: str = None):
        """Save metrics to file."""
        if filename is None:
            filename = f"metrics-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"

        metrics_file = self.metrics_dir / filename
        with open(metrics_file, 'w') as f:
            json.dump(metrics, f, indent=2)

        # Also save daily snapshot
        daily_filename = f"daily-metrics-{datetime.now().strftime('%Y-%m-%d')}.json"
        daily_file = self.metrics_dir / daily_filename
        with open(daily_file, 'w') as f:
            json.dump(metrics, f, indent=2)

        print(f"Metrics saved: {metrics_file}")
        print(f"Daily snapshot saved: {daily_file}")

        return metrics_file

def main():
    """Main execution function."""
    import sys

    collector = QualityMetricsCollector()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "collect":
            report = collector.generate_comprehensive_report()
            collector.save_metrics(report)
            print(json.dumps(report, indent=2))

        elif command == "docs":
            metrics = collector.collect_documentation_metrics()
            print(json.dumps(metrics, indent=2))

        elif command == "quality":
            metrics = collector.collect_quality_metrics()
            print(json.dumps(metrics, indent=2))

        elif command == "reviews":
            metrics = collector.collect_review_metrics()
            print(json.dumps(metrics, indent=2))

        elif command == "trends":
            days = int(sys.argv[2]) if len(sys.argv) > 2 else 30
            metrics = collector.collect_trend_metrics(days)
            print(json.dumps(metrics, indent=2))

        elif command == "help":
            print("Quality Metrics Collector")
            print("Usage: python metrics-collector.py <command> [options]")
            print("Commands:")
            print("  collect            Generate comprehensive metrics report")
            print("  docs               Collect documentation metrics")
            print("  quality            Collect quality metrics")
            print("  reviews            Collect review metrics")
            print("  trends [days]      Collect trend metrics (default: 30 days)")
            print("  help               Show this help message")

        else:
            print(f"Unknown command: {command}")
            print("Use 'help' for usage information")

    else:
        print("Quality Metrics Collector")
        print("Usage: python metrics-collector.py <command> [options]")
        print("Commands:")
        print("  collect            Generate comprehensive metrics report")
        print("  docs               Collect documentation metrics")
        print("  quality            Collect quality metrics")
        print("  reviews            Collect review metrics")
        print("  trends [days]      Collect trend metrics (default: 30 days)")
        print("  help               Show this help message")

if __name__ == "__main__":
    main()