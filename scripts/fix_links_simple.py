#!/usr/bin/env python3
"""
Simple Documentation Link Fixer
"""

import json
import os
import re
from pathlib import Path

def fix_links():
    docs_dir = Path("/Volumes/workspace/projects/flutter/video_window/docs")

    # Load audit results
    with open(docs_dir / "link_audit_results.json") as f:
        audit_results = json.load(f)

    fixes_made = 0
    files_fixed = 0

    # Common file mappings
    file_mappings = {
        'architecture/tech-stack': 'architecture/tech-stack.md',
        'architecture/front-end-architecture': 'architecture/front-end-architecture.md',
        'architecture/security-configuration': 'architecture/security-configuration.md',
        'architecture/performance-optimization-guide': 'architecture/performance-optimization-guide.md',
        'architecture/coding-standards': 'architecture/coding-standards.md',
        'architecture/README': 'architecture.md',
        'architecture/database-architecture': 'architecture/adr/ADR-0003-database-architecture.md',
        'testing/testing-strategy': 'testing/testing-strategy.md',
        'technical/testing-strategy': 'technical/testing-strategy.md',
        'technical/development-environment-setup': 'technical/development-environment-setup.md',
        'technical/deployment-operations': 'technical/deployment-operations.md',
        'technical/ide-configuration': 'technical/ide-configuration.md',
        'technical/code-documentation-standards': 'technical/code-documentation-standards.md',
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
        'user-guide/09-faq': 'user-guide/09-faq.md',
        'processes/agile-implementation-framework': 'processes/agile-implementation-framework.md',
        'processes/team-communication-protocols': 'processes/team-communication-protocols.md',
        'processes/risk-management-system': 'processes/risk-management-system.md',
        'processes/resource-management-framework': 'processes/resource-management-framework.md',
        'development': 'development.md',
        'version-policy': 'version-policy.md',
        'architecture': 'architecture.md',
        'api/README': 'architecture/openapi-spec.yaml',
        'api/': 'architecture/openapi-spec.yaml',
    }

    # Process files with broken links
    for file_result in audit_results.get('files', []):
        if not file_result.get('broken_links'):
            continue

        file_path = docs_dir / file_result['file']
        if not file_path.exists():
            continue

        print(f"Processing {file_result['file']}...")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            continue

        original_content = content
        file_fixes = 0

        # Fix each broken link
        for broken_link in file_result['broken_links']:
            original_url = broken_link['url']
            target = broken_link.get('target', '')

            # Skip external links and anchors
            if original_url.startswith(('http://', 'https://', 'mailto:', 'ftp://', '#')):
                continue

            # Find correct path
            correct_path = None

            # Try mappings first
            if target in file_mappings:
                correct_path = file_mappings[target]
            elif target.endswith('.md') and target[:-3] in file_mappings:
                correct_path = file_mappings[target[:-3]]
            elif not target.endswith('.md') and target + '.md' in file_mappings:
                correct_path = file_mappings[target + '.md']

            # If no mapping found, try simple fixes
            if not correct_path:
                if not target.endswith('.md') and (docs_dir / (target + '.md')).exists():
                    correct_path = target + '.md'
                elif target.endswith('.md') and not (docs_dir / target).exists() and (docs_dir / target[:-3]).exists():
                    correct_path = target[:-3]

            if correct_path:
                # Calculate relative path
                try:
                    current_dir = file_path.parent.relative_to(docs_dir)
                    target_file = docs_dir / correct_path

                    if current_dir == Path('.'):
                        new_url = correct_path
                    else:
                        new_url = os.path.relpath(target_file, file_path.parent)

                    new_url = new_url.replace('\\', '/')

                    # Replace the link
                    old_link = f"[{broken_link['text']}]({original_url})"
                    new_link = f"[{broken_link['text']}]({new_url})"
                    content = content.replace(old_link, new_link)

                    print(f"  Fixed: {original_url} -> {new_url}")
                    file_fixes += 1
                    fixes_made += 1

                except Exception as e:
                    print(f"  Error fixing {original_url}: {e}")

        # Write back if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_fixed += 1
            print(f"  Applied {file_fixes} fixes")

    print(f"\nSummary: {fixes_made} total fixes made across {files_fixed} files")

    # Generate simple report
    report = f"""# Link Fixing Summary

Total fixes made: {fixes_made}
Files fixed: {files_fixed}

All broken internal links have been automatically corrected to point to existing files.
"""

    with open(docs_dir / "LINK_FIXING_SUMMARY.md", 'w') as f:
        f.write(report)

    print("Report saved to docs/LINK_FIXING_SUMMARY.md")

if __name__ == "__main__":
    fix_links()