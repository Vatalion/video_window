#!/usr/bin/env python3
"""
Documentation Link Fixer
Automatically fixes broken internal links by correcting file paths and adding .md extensions.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, Set

class DocumentationLinkFixer:
    def __init__(self, docs_dir: str):
        self.docs_dir = Path(docs_dir)
        self.existing_files = set()
        self.fixes_made = []
        self.unfixable_links = []

    def scan_existing_files(self):
        """Build a set of all existing files."""
        for file_path in self.docs_dir.rglob("*"):
            if file_path.is_file():
                # Store multiple variations for matching
                relative_path = str(file_path.relative_to(self.docs_dir))
                self.existing_files.add(relative_path)
                self.existing_files.add(relative_path.lower())
                self.existing_files.add(relative_path.replace('\\', '/'))  # Normalize paths

    def find_closest_match(self, target: str) -> str:
        """Find the closest matching file for a broken link."""
        target = target.replace('\\', '/')
        target_lower = target.lower()

        # Direct match
        if target in self.existing_files:
            return target
        if target_lower in self.existing_files:
            return target_lower

        # Try adding .md extension
        if not target.endswith('.md'):
            target_with_md = target + '.md'
            if target_with_md in self.existing_files:
                return target_with_md
            if target_with_md.lower() in self.existing_files:
                return target_with_md.lower()

        # Try removing .md extension (for links that incorrectly include it)
        if target.endswith('.md'):
            target_without_md = target[:-3]
            if target_without_md in self.existing_files:
                return target_without_md
            if target_without_md.lower() in self.existing_files:
                return target_without_md.lower()

        # Try common directory structures
        common_mappings = {
            'architecture/tech-stack': 'architecture/tech-stack.md',
            'architecture/front-end-architecture': 'architecture/front-end-architecture.md',
            'architecture/security-configuration': 'architecture/security-configuration.md',
            'architecture/performance-optimization-guide': 'architecture/performance-optimization-guide.md',
            'architecture/coding-standards': 'architecture/coding-standards.md',
            'testing/testing-strategy': 'testing/testing-strategy.md',
            'technical/testing-strategy': 'technical/testing-strategy.md',
            'technical/development-environment-setup': 'technical/development-environment-setup.md',
            'technical/deployment-operations': 'technical/deployment-operations.md',
            'deployment/ci-cd': 'deployment/ci-cd.md',
            'compliance/compliance-guide': 'compliance/compliance-guide.md',
            'user-guide/01-getting-started': 'user-guide/01-getting-started.md',
            'user-guide/02-viewer-guide': 'user-guide/02-viewer-guide.md',
            'user-guide/03-maker-guide': 'user-guide/03-maker-guide.md',
            'user-guide/04-buying-guide': 'user-guide/04-buying-guide.md',
            'user-guide/05-selling-guide': 'user-guide/05-selling-guide.md',
            'user-guide/06-account-management': 'user-guide/06-account-management.md',
            'user-guide/07-safety-guide': 'user-guide/07-safety-guide.md',
            'user-guide/08-troubleshooting': 'user-guide/08-troubleshooting.md',
            'processes/agile-implementation-framework': 'processes/agile-implementation-framework.md',
            'processes/team-communication-protocols': 'processes/team-communication-protocols.md',
            'processes/risk-management-system': 'processes/risk-management-system.md',
            'processes/resource-management-framework': 'processes/resource-management-framework.md',
        }

        if target in common_mappings:
            if common_mappings[target] in self.existing_files:
                return common_mappings[target]

        # Try partial matching for files that might have moved
        target_name = Path(target).name
        for existing_file in self.existing_files:
            if Path(existing_file).name == target_name or Path(existing_file).name == target_name + '.md':
                return existing_file

        # Try directory-only matching
        if target in self.existing_files or target_lower in self.existing_files:
            return target if target in self.existing_files else target_lower

        return None

    def fix_links_in_file(self, file_path: Path) -> Dict:
        """Fix broken links in a single file."""
        relative_path = file_path.relative_to(self.docs_dir)

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                original_content = content

        except Exception as e:
            return {
                'file': str(relative_path),
                'status': 'error',
                'message': f"Could not read file: {e}",
                'fixes': []
            }

        # Find all markdown links
        link_pattern = r'\[([^\]]*)\]\(([^)]+)\)'
        matches = list(re.finditer(link_pattern, content))
        fixes = []

        # Process matches in reverse order to avoid offset issues
        for match in reversed(matches):
            text = match.group(1)
            url = match.group(2)
            original_url = url

            # Skip external URLs and anchors
            if url.startswith(('http://', 'https://', 'mailto:', 'ftp://', '#')):
                continue

            # Skip if already a valid file path
            if url.startswith(('./', '../')):
                # Resolve relative path
                if url.startswith('./'):
                    target_path = file_path.parent / url[2:]
                else:
                    target_path = file_path.parent / url

                # Handle anchor links
                if '#' in str(target_path):
                    target_path = Path(str(target_path).split('#')[0])

                target_relative = str(target_path.relative_to(self.docs_dir))
            else:
                target_relative = url

            # Try to find the correct path
            correct_path = self.find_closest_match(target_relative)

            if correct_path and correct_path != target_relative:
                # Calculate the relative path from current file
                current_dir = file_path.parent.relative_to(self.docs_dir)
                target_file = self.docs_dir / correct_path

                # Calculate relative path
                if current_dir == Path('.'):
                    new_url = correct_path
                else:
                    try:
                        new_url = os.path.relpath(target_file, file_path.parent)
                    except ValueError:
                        # If paths are on different drives (unlikely), use absolute
                        new_url = correct_path

                # Normalize path separators
                new_url = new_url.replace('\\', '/')

                # Replace the link
                old_link = f'[{text}]({url})'
                new_link = f'[{text}]({new_url})'
                content = content.replace(old_link, new_link)

                fixes.append({
                    'line': content[:match.start()].count('\n') + 1,
                    'original_url': original_url,
                    'corrected_url': new_url,
                    'text': text,
                    'original_target': target_relative,
                    'correct_target': correct_path
                })

        # Write back if changes were made
        if content != original_content:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                status = 'fixed'
            except Exception as e:
                status = 'error'
                fixes = [{'message': f"Could not write file: {e}"}]
        else:
            status = 'no_fixes_needed'

        return {
            'file': str(relative_path),
            'status': status,
            'fixes': fixes,
            'total_fixes': len(fixes)
        }

    def run_fixer(self) -> Dict:
        """Run the link fixer on all files."""
        print("Starting documentation link fixer...")

        # Build file index
        print("Building file index...")
        self.scan_existing_files()
        print(f"Found {len(self.existing_files)} files")

        # Load broken links from audit results
        audit_results_path = self.docs_dir / "link_audit_results.json"
        broken_links_by_file = {}

        if audit_results_path.exists():
            with open(audit_results_path, 'r') as f:
                audit_results = json.load(f)

            for file_result in audit_results.get('files', []):
                if file_result.get('broken_links'):
                    broken_links_by_file[file_result['file']] = file_result['broken_links']

        results = {
            'summary': {
                'files_with_broken_links': len(broken_links_by_file),
                'files_processed': 0,
                'total_fixes_made': 0,
                'files_with_fixes': 0,
                'errors': 0
            },
            'files_fixed': [],
            'unfixable_links': []
        }

        # Ensure all keys exist
        for key in results['summary']:
            results['summary'][key] = results['summary'][key]

        print("Fixing broken links...")
        for file_name, broken_links in broken_links_by_file.items():
            file_path = self.docs_dir / file_name
            if file_path.exists():
                file_result = self.fix_links_in_file(file_path)
                results['files_processed'] += 1
                results['summary']['total_fixes_made'] += file_result['total_fixes']

                if file_result['status'] == 'fixed':
                    results['files_fixed'].append(file_result)
                    results['summary']['files_with_fixes'] += 1
                    print(f"Fixed {file_result['total_fixes']} links in {file_name}")
                elif file_result['status'] == 'error':
                    results['summary']['errors'] += 1
                    print(f"Error processing {file_name}: {file_result.get('message', 'Unknown error')}")

        return results

    def generate_fix_report(self, results: Dict) -> str:
        """Generate a report of all fixes made."""
        report = []
        report.append("# Documentation Link Fix Report\n")

        # Summary
        report.append("## Summary\n")
        summary = results['summary']
        report.append(f"- **Files with broken links**: {summary['files_with_broken_links']}")
        report.append(f"- **Files processed**: {summary['files_processed']}")
        report.append(f"- **Total fixes made**: {summary['total_fixes_made']} ✅")
        report.append(f"- **Files with fixes**: {summary['files_with_fixes']}")
        report.append(f"- **Errors encountered**: {summary['errors']} ❌")
        report.append("")

        if summary['total_fixes_made'] == 0:
            report.append("No fixes were needed or possible.\n")
            return "\n".join(report)

        # Detailed fixes
        report.append("## Fixes Applied\n")
        for file_result in results['files_fixed']:
            report.append(f"### {file_result['file']}")
            report.append(f"**Fixes applied**: {file_result['total_fixes']}")
            report.append("")

            for fix in file_result['fixes']:
                report.append(f"- **Line {fix['line']}**: `{fix['original_url']}` → `{fix['corrected_url']}`")
                report.append(f"  - Text: {fix['text']}")
                report.append(f"  - Target: `{fix['original_target']}` → `{fix['correct_target']}`")
                report.append("")

        return "\n".join(report)

if __name__ == "__main__":
    docs_dir = "/Volumes/workspace/projects/flutter/video_window/docs"
    fixer = DocumentationLinkFixer(docs_dir)
    results = fixer.run_fixer()

    # Generate report
    report = fixer.generate_fix_report(results)

    # Save report
    report_path = Path(docs_dir) / "LINK_FIX_REPORT.md"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report)

    # Also save JSON data
    json_path = Path(docs_dir) / "link_fix_results.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)

    print(f"\nLink fixing complete! Report saved to: {report_path}")
    print(f"JSON data saved to: {json_path}")
    print(f"\nSummary: {results['summary']['total_fixes_made']} fixes made across {results['summary']['files_with_fixes']} files.")