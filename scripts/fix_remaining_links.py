#!/usr/bin/env python3
"""
Fix remaining specific link issues
"""

import re
from pathlib import Path

def fix_specific_files():
    docs_dir = Path("/Volumes/workspace/projects/flutter/video_window/docs")

    # Define specific fixes needed
    specific_fixes = {
        'docs/user-guide/01-getting-started.md': [
            ('08-troubleshooting.md', './08-troubleshooting.md'),
            ('02-viewer-guide.md', './02-viewer-guide.md'),
            ('03-maker-guide.md', './03-maker-guide.md'),
            ('04-buying-guide.md', './04-buying-guide.md'),
            ('07-safety-guide.md', './07-safety-guide.md'),
        ],
        'docs/user-guide/02-viewer-guide.md': [
            ('04-buying-guide.md', './04-buying-guide.md'),
            ('06-account-management.md', './06-account-management.md'),
            ('07-safety-guide.md', './07-safety-guide.md'),
            ('09-faq.md', './09-faq.md'),
            ('01-getting-started.md', './01-getting-started.md'),
        ],
        'docs/user-guide/README.md': [
            ('01-getting-started.md', './01-getting-started.md'),
            ('02-viewer-guide.md', './02-viewer-guide.md'),
            ('03-maker-guide.md', './03-maker-guide.md'),
            ('04-buying-guide.md', './04-buying-guide.md'),
            ('05-selling-guide.md', './05-selling-guide.md'),
            ('06-account-management.md', './06-account-management.md'),
            ('07-safety-guide.md', './07-safety-guide.md'),
            ('08-troubleshooting.md', './08-troubleshooting.md'),
            ('09-faq.md', './09-faq.md'),
        ],
        'docs/technical/README.md': [
            ('../implementation-readiness-package/development-environment-setup.md', '../implementation-readiness-package/development-environment-setup.md'),
            ('../testing/testing-strategy.md', '../testing/testing-strategy.md'),
        ],
        'docs/tech-spec-epic-3.md': [
            ('../architecture/security-configuration.md', '../architecture/security-configuration.md'),
            ('../architecture/openapi-spec.yaml', '../architecture/openapi-spec.yaml'),
            ('../compliance/compliance-guide.md', '../compliance/compliance-guide.md'),
            ('../architecture/front-end-architecture.md', '../architecture/front-end-architecture.md'),
            ('../architecture/adr/ADR-0003-database-architecture.md', '../architecture/adr/ADR-0003-database-architecture.md'),
        ],
        'docs/deployment/ci-cd.md': [
            ('../testing/testing-strategy.md', '../testing/testing-strategy.md'),
            ('../development.md', '../development.md'),
        ],
        'docs/deployment/docker-configuration.md': [
            ('ci-cd.md', './ci-cd.md'),
            ('../testing/testing-strategy.md', '../testing/testing-strategy.md'),
            ('../development.md', '../development.md'),
        ],
    }

    total_fixes = 0
    files_fixed = 0

    for file_path_str, fixes in specific_fixes.items():
        file_path = Path(file_path_str)

        if not file_path.exists():
            print(f"File not found: {file_path}")
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue

        original_content = content
        file_fixes = 0

        for old_link, new_link in fixes:
            # Use regex to find and replace the links
            pattern = rf'\[([^\]]*)\]\({re.escape(old_link)}\)'
            matches = list(re.finditer(pattern, content))

            for match in matches:
                text = match.group(1)
                old_full = match.group(0)
                new_full = f'[{text}]({new_link})'
                content = content.replace(old_full, new_full)
                file_fixes += 1
                print(f"  Fixed in {file_path.name}: {old_link} -> {new_link}")

        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_fixed += 1
            total_fixes += file_fixes
            print(f"  Applied {file_fixes} fixes to {file_path.name}")

    print(f"\nSummary: {total_fixes} additional fixes made across {files_fixed} files")

if __name__ == "__main__":
    fix_specific_files()