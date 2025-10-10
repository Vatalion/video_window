# Quality Metrics Dashboard

Status: v1.0 — Real-time monitoring of documentation quality metrics and trends

## Overview

This dashboard provides comprehensive visibility into documentation quality through real-time metrics, trend analysis, and actionable insights.

## Dashboard Architecture

### Data Collection Layer

```python
#!/usr/bin/env python3
"""
Quality metrics data collection and aggregation system.
"""

import json
import os
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
                   [".git", "node_modules", ".DS_Store", "quality-automation"]):
                continue

            metrics["total_documents"] += 1

            # Get file size
            size_bytes = doc_file.stat().st_size
            metrics["total_size_mb"] += size_bytes / (1024 * 1024)

            # Document type classification
            doc_type = self._classify_document(doc_file)
            metrics["documents_by_type"][doc_type] = metrics["documents_by_type"].get(doc_type, 0) + 1

            # Directory classification
            relative_dir = str(doc_file.parent.relative_to(self.docs_dir))
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
            metrics["average_document_age_days"] = statistics.mean(all_ages)

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
            with open(validation_file, 'r') as f:
                validation_data = json.load(f)
            quality_metrics["validation_results"] = validation_data

        # Load compliance results
        compliance_file = self.metrics_dir.parent / "compliance-report.json"
        if compliance_file.exists():
            with open(compliance_file, 'r') as f:
                compliance_data = json.load(f)
            quality_metrics["compliance_results"] = compliance_data

        # Load coverage results
        coverage_file = Path("reports/coverage/coverage-summary.json")
        if coverage_file.exists():
            with open(coverage_file, 'r') as f:
                coverage_data = json.load(f)
            quality_metrics["coverage_results"] = coverage_data

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

            except Exception as e:
                print(f"Error processing ownership file {ownership_file}: {e}")

        # Calculate average review time
        if review_times:
            review_metrics["average_review_time_days"] = statistics.mean(review_times)

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
                with open(metrics_file, 'r') as f:
                    daily_metrics = json.load(f)

                trend_metrics["quality_score_trend"].append({
                    "date": date_str,
                    "score": daily_metrics.get("overall_quality_score", 0)
                })

                trend_metrics["document_count_trend"].append({
                    "date": date_str,
                    "count": daily_metrics.get("total_documents", 0)
                })

                trend_metrics["review_completion_trend"].append({
                    "date": date_str,
                    "completed": daily_metrics.get("completed_reviews", 0),
                    "pending": daily_metrics.get("pending_reviews", 0)
                })

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
```

### Dashboard Frontend

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentation Quality Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f7;
            color: #1d1d1f;
            line-height: 1.6;
        }

        .dashboard {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }

        .header p {
            opacity: 0.9;
            font-size: 1.1rem;
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .metric-card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }

        .metric-value {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .metric-label {
            color: #666;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .metric-change {
            font-size: 0.85rem;
            margin-top: 10px;
            padding: 5px 10px;
            border-radius: 20px;
            display: inline-block;
        }

        .metric-change.positive {
            background-color: #d4edda;
            color: #155724;
        }

        .metric-change.negative {
            background-color: #f8d7da;
            color: #721c24;
        }

        .chart-container {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }

        .chart-title {
            font-size: 1.3rem;
            margin-bottom: 20px;
            color: #333;
        }

        .insights-container {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }

        .alert {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            border-left: 4px solid;
        }

        .alert.high {
            background-color: #f8d7da;
            border-color: #dc3545;
            color: #721c24;
        }

        .alert.medium {
            background-color: #fff3cd;
            border-color: #ffc107;
            color: #856404;
        }

        .alert.low {
            background-color: #d1ecf1;
            border-color: #17a2b8;
            color: #0c5460;
        }

        .recommendations {
            margin-top: 20px;
        }

        .recommendation {
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            margin-bottom: 10px;
            border-left: 4px solid #28a745;
        }

        .loading {
            text-align: center;
            padding: 50px;
            font-size: 1.2rem;
            color: #666;
        }

        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .quality-score {
            position: relative;
            display: inline-block;
        }

        .quality-score.high { color: #28a745; }
        .quality-score.medium { color: #ffc107; }
        .quality-score.low { color: #dc3545; }

        .refresh-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1rem;
            transition: background 0.3s ease;
        }

        .refresh-btn:hover {
            background: #5a6fd8;
        }

        .last-updated {
            color: #666;
            font-size: 0.9rem;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>Documentation Quality Dashboard</h1>
            <p>Real-time monitoring of documentation quality metrics and trends</p>
            <button class="refresh-btn" onclick="refreshDashboard()">Refresh Data</button>
            <div class="last-updated" id="lastUpdated">Loading...</div>
        </div>

        <div id="loadingIndicator" class="loading">
            <div class="spinner"></div>
            <div>Loading quality metrics...</div>
        </div>

        <div id="dashboardContent" style="display: none;">
            <!-- Quality Score Cards -->
            <div class="metrics-grid">
                <div class="metric-card">
                    <div class="metric-value quality-score" id="overallQualityScore">-</div>
                    <div class="metric-label">Overall Quality Score</div>
                    <div class="metric-change" id="qualityScoreChange">-</div>
                </div>

                <div class="metric-card">
                    <div class="metric-value" id="totalDocuments">-</div>
                    <div class="metric-label">Total Documents</div>
                    <div class="metric-change" id="documentCountChange">-</div>
                </div>

                <div class="metric-card">
                    <div class="metric-value" id="validationPassRate">-</div>
                    <div class="metric-label">Validation Pass Rate</div>
                    <div class="metric-change" id="validationChange">-</div>
                </div>

                <div class="metric-card">
                    <div class="metric-value" id="complianceRate">-</div>
                    <div class="metric-label">Compliance Rate</div>
                    <div class="metric-change" id="complianceChange">-</div>
                </div>
            </div>

            <!-- Quality Trend Chart -->
            <div class="chart-container">
                <h3 class="chart-title">Quality Score Trend (Last 30 Days)</h3>
                <canvas id="qualityTrendChart" width="400" height="150"></canvas>
            </div>

            <!-- Document Distribution Chart -->
            <div class="chart-container">
                <h3 class="chart-title">Document Distribution by Type</h3>
                <canvas id="documentDistributionChart" width="400" height="150"></canvas>
            </div>

            <!-- Review Status Chart -->
            <div class="chart-container">
                <h3 class="chart-title">Review Status Overview</h3>
                <canvas id="reviewStatusChart" width="400" height="150"></canvas>
            </div>

            <!-- Insights and Alerts -->
            <div class="insights-container">
                <h3 class="chart-title">Quality Insights & Alerts</h3>
                <div id="alertsContainer"></div>
                <div class="recommendations" id="recommendationsContainer"></div>
            </div>
        </div>
    </div>

    <script>
        // Dashboard JavaScript
        let qualityTrendChart = null;
        let documentDistributionChart = null;
        let reviewStatusChart = null;

        // Initialize dashboard
        document.addEventListener('DOMContentLoaded', function() {
            loadDashboardData();
            // Auto-refresh every 5 minutes
            setInterval(loadDashboardData, 5 * 60 * 1000);
        });

        async function loadDashboardData() {
            try {
                showLoading(true);

                // In a real implementation, this would fetch from an API endpoint
                // For now, we'll simulate with mock data
                const metrics = await fetchMetrics();

                updateMetricCards(metrics);
                updateCharts(metrics);
                updateInsights(metrics);
                updateLastUpdated();

                showLoading(false);
            } catch (error) {
                console.error('Error loading dashboard data:', error);
                showError('Failed to load dashboard data');
                showLoading(false);
            }
        }

        async function fetchMetrics() {
            // Simulate API call - replace with actual API call
            return new Promise(resolve => {
                setTimeout(() => {
                    resolve(generateMockMetrics());
                }, 1000);
            });
        }

        function generateMockMetrics() {
            return {
                documentation_metrics: {
                    total_documents: 156,
                    documents_by_type: {
                        user_story: 45,
                        technical_decision: 12,
                        architecture: 8,
                        qa_document: 15,
                        user_guide: 23,
                        api_documentation: 18,
                        general: 35
                    }
                },
                quality_metrics: {
                    overall_quality_score: 87.5,
                    validation_results: {
                        total_files: 156,
                        passed_files: 142,
                        failed_files: 14
                    },
                    compliance_results: {
                        compliance_rate: 92.3
                    },
                    coverage_results: {
                        overall_coverage: 78.5
                    }
                },
                review_metrics: {
                    total_reviews: 89,
                    completed_reviews: 67,
                    pending_reviews: 22,
                    overdue_reviews: 3
                },
                trend_metrics: {
                    quality_score_trend: generateTrendData(87.5, 30),
                    document_count_trend: generateTrendData(156, 30)
                },
                insights: {
                    alerts: [],
                    recommendations: [
                        {
                            priority: "medium",
                            message: "3 reviews are overdue",
                            recommendation: "Schedule review catch-up sessions"
                        },
                        {
                            priority: "low",
                            message: "Consider updating older documentation",
                            recommendation: "Review documents older than 90 days"
                        }
                    ]
                }
            };
        }

        function generateTrendData(currentValue, days) {
            const trend = [];
            let value = currentValue - (Math.random() * 10 - 5);

            for (let i = days; i >= 0; i--) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                value += (Math.random() * 4 - 2);
                value = Math.max(70, Math.min(100, value));

                trend.push({
                    date: date.toISOString().split('T')[0],
                    score: Math.round(value * 10) / 10
                });
            }

            return trend;
        }

        function updateMetricCards(metrics) {
            const qualityScore = metrics.quality_metrics.overall_quality_score;
            const qualityScoreElement = document.getElementById('overallQualityScore');

            qualityScoreElement.textContent = qualityScore.toFixed(1);
            qualityScoreElement.className = `metric-value quality-score ${getQualityLevel(qualityScore)}`;

            // Update other metrics
            document.getElementById('totalDocuments').textContent = metrics.documentation_metrics.total_documents;

            const validationPassRate = (metrics.quality_metrics.validation_results.passed_files /
                                     metrics.quality_metrics.validation_results.total_files * 100).toFixed(1);
            document.getElementById('validationPassRate').textContent = validationPassRate + '%';

            document.getElementById('complianceRate').textContent =
                metrics.quality_metrics.compliance_results.compliance_rate.toFixed(1) + '%';

            // Update change indicators (mock data for now)
            updateChangeIndicator('qualityScoreChange', 2.3, true);
            updateChangeIndicator('documentCountChange', 5, true);
            updateChangeIndicator('validationChange', -1.2, false);
            updateChangeIndicator('complianceChange', 0.8, true);
        }

        function updateChangeIndicator(elementId, change, isPositive) {
            const element = document.getElementById(elementId);
            const sign = isPositive ? '+' : '';
            element.textContent = `${sign}${change.toFixed(1)}% from last week`;
            element.className = `metric-change ${isPositive ? 'positive' : 'negative'}`;
        }

        function getQualityLevel(score) {
            if (score >= 85) return 'high';
            if (score >= 70) return 'medium';
            return 'low';
        }

        function updateCharts(metrics) {
            updateQualityTrendChart(metrics.trend_metrics.quality_score_trend);
            updateDocumentDistributionChart(metrics.documentation_metrics.documents_by_type);
            updateReviewStatusChart(metrics.review_metrics);
        }

        function updateQualityTrendChart(trendData) {
            const ctx = document.getElementById('qualityTrendChart').getContext('2d');

            if (qualityTrendChart) {
                qualityTrendChart.destroy();
            }

            qualityTrendChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: trendData.map(d => d.date),
                    datasets: [{
                        label: 'Quality Score',
                        data: trendData.map(d => d.score),
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: false,
                            min: 70,
                            max: 100
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        function updateDocumentDistributionChart(distribution) {
            const ctx = document.getElementById('documentDistributionChart').getContext('2d');

            if (documentDistributionChart) {
                documentDistributionChart.destroy();
            }

            documentDistributionChart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(distribution),
                    datasets: [{
                        data: Object.values(distribution),
                        backgroundColor: [
                            '#667eea',
                            '#764ba2',
                            '#f093fb',
                            '#4facfe',
                            '#43e97b',
                            '#fa709a',
                            '#fee140'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        }

        function updateReviewStatusChart(reviewMetrics) {
            const ctx = document.getElementById('reviewStatusChart').getContext('2d');

            if (reviewStatusChart) {
                reviewStatusChart.destroy();
            }

            reviewStatusChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Completed', 'Pending', 'Overdue'],
                    datasets: [{
                        label: 'Reviews',
                        data: [
                            reviewMetrics.completed_reviews,
                            reviewMetrics.pending_reviews - reviewMetrics.overdue_reviews,
                            reviewMetrics.overdue_reviews
                        ],
                        backgroundColor: ['#28a745', '#ffc107', '#dc3545']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        function updateInsights(metrics) {
            const alertsContainer = document.getElementById('alertsContainer');
            const recommendationsContainer = document.getElementById('recommendationsContainer');

            // Clear existing content
            alertsContainer.innerHTML = '';
            recommendationsContainer.innerHTML = '';

            // Add alerts if any
            if (metrics.insights.alerts && metrics.insights.alerts.length > 0) {
                metrics.insights.alerts.forEach(alert => {
                    const alertElement = createAlert(alert);
                    alertsContainer.appendChild(alertElement);
                });
            } else {
                alertsContainer.innerHTML = '<p style="color: #28a745;">✅ No critical alerts at this time</p>';
            }

            // Add recommendations
            if (metrics.insights.recommendations && metrics.insights.recommendations.length > 0) {
                const recommendationsTitle = document.createElement('h4');
                recommendationsTitle.textContent = 'Recommendations';
                recommendationsTitle.style.marginBottom = '15px';
                recommendationsContainer.appendChild(recommendationsTitle);

                metrics.insights.recommendations.forEach(rec => {
                    const recElement = createRecommendation(rec);
                    recommendationsContainer.appendChild(recElement);
                });
            }
        }

        function createAlert(alert) {
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert ${alert.severity}`;
            alertDiv.innerHTML = `
                <strong>${alert.severity.toUpperCase()}:</strong> ${alert.message}
                <br><em>Recommendation: ${alert.recommendation}</em>
            `;
            return alertDiv;
        }

        function createRecommendation(recommendation) {
            const recDiv = document.createElement('div');
            recDiv.className = 'recommendation';
            recDiv.innerHTML = `
                <strong>${recommendation.message}</strong>
                <br><em>Action: ${recommendation.recommendation}</em>
            `;
            return recDiv;
        }

        function updateLastUpdated() {
            const lastUpdatedElement = document.getElementById('lastUpdated');
            lastUpdatedElement.textContent = `Last updated: ${new Date().toLocaleString()}`;
        }

        function showLoading(show) {
            const loadingIndicator = document.getElementById('loadingIndicator');
            const dashboardContent = document.getElementById('dashboardContent');

            if (show) {
                loadingIndicator.style.display = 'block';
                dashboardContent.style.display = 'none';
            } else {
                loadingIndicator.style.display = 'none';
                dashboardContent.style.display = 'block';
            }
        }

        function showError(message) {
            const dashboardContent = document.getElementById('dashboardContent');
            dashboardContent.innerHTML = `
                <div style="text-align: center; padding: 50px; color: #dc3545;">
                    <h3>Error Loading Dashboard</h3>
                    <p>${message}</p>
                    <button class="refresh-btn" onclick="loadDashboardData()">Retry</button>
                </div>
            `;
        }

        function refreshDashboard() {
            loadDashboardData();
        }
    </script>
</body>
</html>
```

### Dashboard API Server

```python
#!/usr/bin/env python3
"""
Simple API server for serving quality metrics data to the dashboard.
"""

import json
import os
from datetime import datetime
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import sys

# Add the metrics collector to the path
sys.path.append(str(Path(__file__).parent))

try:
    from metrics_collector import QualityMetricsCollector
except ImportError:
    print("Warning: metrics_collector.py not found in the same directory")
    QualityMetricsCollector = None

class DashboardAPIHandler(SimpleHTTPRequestHandler):
    """Custom HTTP handler for the dashboard API."""

    def __init__(self, *args, **kwargs):
        self.metrics_dir = Path("docs/quality-automation/metrics")
        super().__init__(*args, **kwargs)

    def do_GET(self):
        """Handle GET requests."""
        parsed_path = urlparse(self.path)

        if parsed_path.path == '/api/metrics':
            self.handle_metrics_request()
        elif parsed_path.path == '/api/health':
            self.handle_health_request()
        elif parsed_path.path == '/' or parsed_path.path == '/index.html':
            self.serve_dashboard()
        else:
            # Serve static files
            super().do_GET()

    def handle_metrics_request(self):
        """Handle metrics API request."""
        try:
            if QualityMetricsCollector:
                collector = QualityMetricsCollector()
                metrics = collector.generate_comprehensive_report()
            else:
                # Fallback to loading latest metrics file
                metrics = self.load_latest_metrics()

            self.send_json_response(metrics)
        except Exception as e:
            self.send_error_response(500, f"Error generating metrics: {str(e)}")

    def load_latest_metrics(self):
        """Load the most recent metrics file."""
        metrics_files = list(self.metrics_dir.glob("metrics-*.json"))
        if not metrics_files:
            # Return empty metrics if no files exist
            return {
                "generated_at": datetime.now().isoformat(),
                "error": "No metrics data available"
            }

        # Sort by filename (which includes timestamp) and get the latest
        latest_file = max(metrics_files, key=lambda f: f.name)

        with open(latest_file, 'r') as f:
            return json.load(f)

    def handle_health_request(self):
        """Handle health check request."""
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": "1.0.0"
        }
        self.send_json_response(health_data)

    def serve_dashboard(self):
        """Serve the main dashboard HTML."""
        dashboard_file = Path(__file__).parent / "quality-dashboard.html"

        if dashboard_file.exists():
            with open(dashboard_file, 'r') as f:
                content = f.read()

            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
        else:
            self.send_error_response(404, "Dashboard file not found")

    def send_json_response(self, data):
        """Send JSON response."""
        json_data = json.dumps(data, indent=2)

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json_data.encode('utf-8'))

    def send_error_response(self, code, message):
        """Send error response."""
        error_data = {
            "error": message,
            "status_code": code,
            "timestamp": datetime.now().isoformat()
        }

        json_data = json.dumps(error_data)

        self.send_response(code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json_data.encode('utf-8'))

def run_server(port=8080):
    """Run the dashboard server."""
    server_address = ('', port)
    httpd = HTTPServer(server_address, DashboardAPIHandler)

    print(f"Dashboard server starting on port {port}")
    print(f"Open http://localhost:{port} to view the dashboard")
    print("Press Ctrl+C to stop the server")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.server_close()

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Documentation Quality Dashboard Server")
    parser.add_argument("--port", type=int, default=8080, help="Port to run the server on")
    parser.add_argument("--generate", action="store_true", help="Generate metrics before starting server")

    args = parser.parse_args()

    if args.generate and QualityMetricsCollector:
        print("Generating fresh metrics...")
        collector = QualityMetricsCollector()
        metrics = collector.generate_comprehensive_report()
        collector.save_metrics(metrics)
        print("Metrics generated successfully!")

    run_server(args.port)
```

This comprehensive quality metrics dashboard provides real-time monitoring, trend analysis, and actionable insights for maintaining high documentation quality standards.