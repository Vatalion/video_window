#!/usr/bin/env python3
"""
Documentation Link Auditor
Scans all markdown files in docs/ directory to identify broken internal links and cross-references.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, Set

class DocumentationAuditor:
    def __init__(self, docs_dir: str):
        self.docs_dir = Path(docs_dir)
        self.existing_files = set()
        self.broken_links = []
        self.valid_links = []
        self.external_links = []

    def scan_existing_files(self):
        """Build a set of all existing markdown files."""
        for md_file in self.docs_dir.rglob("*.md"):
            # Convert to relative path from docs directory
            relative_path = md_file.relative_to(self.docs_dir)
            self.existing_files.add(str(relative_path))
            self.existing_files.add(str(relative_path).lower())  # Case-insensitive check

    def extract_links_from_file(self, file_path: Path) -> List[Tuple[str, int, str]]:
        """Extract all markdown links from a file."""
        links = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            for line_num, line in enumerate(lines, 1):
                # Match markdown links [text](url)
                matches = re.finditer(r'\[([^\]]*)\]\(([^)]+)\)', line)
                for match in matches:
                    text = match.group(1)
                    url = match.group(2)
                    links.append((text, line_num, url))

        except Exception as e:
            print(f"Error reading {file_path}: {e}")

        return links

    def categorize_link(self, url: str, file_path: Path) -> Dict:
        """Categorize a link as internal, external, anchor, etc."""
        result = {
            'url': url,
            'type': 'unknown',
            'target': None,
            'status': 'unknown'
        }

        # Skip anchor-only links
        if url.startswith('#'):
            result['type'] = 'anchor'
            result['status'] = 'valid'
            return result

        # External URLs
        if url.startswith(('http://', 'https://', 'mailto:', 'ftp://')):
            result['type'] = 'external'
            result['status'] = 'external'
            return result

        # Internal links
        if url.startswith('./') or url.startswith('../') or not url.startswith('/'):
            result['type'] = 'internal'

            # Resolve the path
            if url.startswith('./'):
                # Relative to current directory
                target_path = file_path.parent / url[2:]
            elif url.startswith('../'):
                # Relative to parent directories
                target_path = file_path.parent / url
            else:
                # Relative to current directory
                target_path = file_path.parent / url

            # Handle anchor links
            if '#' in target_path.name:
                target_path = target_path.with_name(target_path.name.split('#')[0])
                result['has_anchor'] = True

            # Remove .md extension if present for checking
            check_path = str(target_path)
            if check_path.endswith('.md'):
                check_path = check_path[:-3]
                if not any(target_path.suffix == ext for ext in ['.md', '.yaml', '.yml']):
                    check_path += '.md'

            # Convert to relative path from docs directory
            try:
                relative_path = Path(check_path).relative_to(self.docs_dir)
                result['target'] = str(relative_path)

                # Check if file exists
                if str(relative_path) in self.existing_files or str(relative_path).lower() in self.existing_files:
                    result['status'] = 'valid'
                else:
                    result['status'] = 'broken'

            except ValueError:
                # Path is outside docs directory
                result['type'] = 'external'
                result['status'] = 'external'

        return result

    def audit_file(self, file_path: Path) -> Dict:
        """Audit a single file for broken links."""
        relative_path = file_path.relative_to(self.docs_dir)
        links = self.extract_links_from_file(file_path)

        file_result = {
            'file': str(relative_path),
            'total_links': len(links),
            'broken_links': [],
            'valid_links': [],
            'external_links': [],
            'anchor_links': []
        }

        for text, line_num, url in links:
            link_info = self.categorize_link(url, file_path)
            link_info.update({
                'text': text,
                'line': line_num,
                'source_file': str(relative_path)
            })

            if link_info['status'] == 'broken':
                file_result['broken_links'].append(link_info)
                self.broken_links.append(link_info)
            elif link_info['status'] == 'external':
                file_result['external_links'].append(link_info)
                self.external_links.append(link_info)
            elif link_info['type'] == 'anchor':
                file_result['anchor_links'].append(link_info)
            else:
                file_result['valid_links'].append(link_info)
                self.valid_links.append(link_info)

        return file_result

    def run_audit(self) -> Dict:
        """Run the complete audit."""
        print("Starting documentation audit...")

        # Build file index
        print("Building file index...")
        self.scan_existing_files()
        print(f"Found {len(self.existing_files)} markdown files")

        # Audit all files
        results = {
            'summary': {
                'total_files': 0,
                'total_links': 0,
                'broken_links': 0,
                'valid_links': 0,
                'external_links': 0,
                'anchor_links': 0
            },
            'files': [],
            'broken_links': [],
            'most_problematic_files': []
        }

        print("Auditing files...")
        for md_file in self.docs_dir.rglob("*.md"):
            if md_file.is_file():
                file_result = self.audit_file(md_file)
                results['files'].append(file_result)
                results['summary']['total_files'] += 1
                results['summary']['total_links'] += file_result['total_links']
                results['summary']['broken_links'] += len(file_result['broken_links'])
                results['summary']['valid_links'] += len(file_result['valid_links'])
                results['summary']['external_links'] += len(file_result['external_links'])
                results['summary']['anchor_links'] += len(file_result['anchor_links'])

        # Sort files by number of broken links
        results['files'].sort(key=lambda x: len(x['broken_links']), reverse=True)
        results['broken_links'] = sorted(self.broken_links, key=lambda x: x['source_file'])

        # Get most problematic files (files with broken links)
        results['most_problematic_files'] = [
            f for f in results['files'] if f['broken_links']
        ]

        return results

    def generate_report(self, results: Dict) -> str:
        """Generate a detailed audit report."""
        report = []
        report.append("# Documentation Link Audit Report\n")

        # Summary
        report.append("## Summary\n")
        summary = results['summary']
        report.append(f"- **Total Files**: {summary['total_files']}")
        report.append(f"- **Total Links**: {summary['total_links']}")
        report.append(f"- **Broken Links**: {summary['broken_links']} 🔴")
        report.append(f"- **Valid Links**: {summary['valid_links']} ✅")
        report.append(f"- **External Links**: {summary['external_links']} 🔗")
        report.append(f"- **Anchor Links**: {summary['anchor_links']} ⚓")
        report.append("")

        if summary['broken_links'] == 0:
            report.append("🎉 **No broken links found!** All documentation links are valid.\n")
            return "\n".join(report)

        # Most problematic files
        report.append("## Most Problematic Files\n")
        for file_result in results['most_problematic_files'][:10]:
            report.append(f"### {file_result['file']}")
            report.append(f"- Broken Links: {len(file_result['broken_links'])}")
            report.append(f"- Total Links: {file_result['total_links']}")
            report.append("")

        # Detailed broken links
        report.append("## Broken Links Details\n")
        for link in results['broken_links']:
            report.append(f"### {link['source_file']} (Line {link['line']})")
            report.append(f"**Link Text**: {link['text']}")
            report.append(f"**Target URL**: `{link['url']}`")
            report.append(f"**Expected Target**: `{link.get('target', 'N/A')}`")
            report.append("")

        return "\n".join(report)

if __name__ == "__main__":
    docs_dir = "/Volumes/workspace/projects/flutter/video_window/docs"
    auditor = DocumentationAuditor(docs_dir)
    results = auditor.run_audit()

    # Generate report
    report = auditor.generate_report(results)

    # Save report
    report_path = Path(docs_dir) / "LINK_AUDIT_REPORT.md"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report)

    # Also save JSON data
    json_path = Path(docs_dir) / "link_audit_results.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)

    print(f"\nAudit complete! Report saved to: {report_path}")
    print(f"JSON data saved to: {json_path}")
    print(f"\nSummary: {results['summary']['broken_links']} broken links found out of {results['summary']['total_links']} total links.")