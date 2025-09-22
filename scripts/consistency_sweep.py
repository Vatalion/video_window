#!/usr/bin/env python3
import sys
import re
from pathlib import Path
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[1]
STORIES = ROOT / "docs" / "stories"
TARGET_PREFIXES = tuple([f"0{i}." for i in range(2,10)])  # 02..09

SECTION_PATTERNS = {
    "status": re.compile(r"^##\s+Status\b", re.MULTILINE),
    "priority": re.compile(r"^##\s+Priority\b", re.MULTILINE),
    "tasks": re.compile(r"^##\s+Tasks\s*/\s*Subtasks\b", re.MULTILINE),
    # treat either 'Definition of Done' or 'DoD' as satisfying DoD
    "dod": re.compile(r"^##\s+(Definition of Done|DoD)\b", re.MULTILINE),
    "qa_results": re.compile(r"^##\s+QA\s+Results\b", re.MULTILINE),
    "dev_agent": re.compile(r"^##\s+Dev\s+Agent\s+Record\b", re.MULTILINE),
}

TEMPLATES = {
    "status": "\n\n## Status\nTBD\n",
    "priority": "\n\n## Priority\nTBD\n",
    "tasks": "\n\n## Tasks / Subtasks\n- [ ] Add task breakdown aligned to Acceptance Criteria\n",
    "dod": (
        "\n\n## Definition of Done\n"
        "- All Acceptance Criteria validated\n"
        "- Telemetry hooked per analytics schema\n"
        "- Unit/Widget/Integration tests added and passing\n"
        "- Accessibility and performance checks completed\n"
        "- Documentation updated (README/CHANGELOG as needed)\n"
    ),
    "qa_results": (
        "\n\n## QA Results\n"
        "- Owner: TBD\n"
        "- Test window: TBD\n"
        "- Summary: Pending\n"
    ),
    "dev_agent": (
        "\n\n## Dev Agent Record\n"
        "- Engineer: TBD\n"
        "- Dates: TBD\n"
        "- Notes: TBD\n"
    ),
}

def should_process(path: Path) -> bool:
    # only markdown files under epics 02..09, skip archive and backup files
    if path.suffix.lower() != ".md":
        return False
    rel = path.relative_to(STORIES)
    parts = rel.parts
    if not parts:
        return False
    # top-level epic folder name must start with 02. .. 09.
    epic_folder = parts[0]
    if not epic_folder.startswith(TARGET_PREFIXES):
        return False
    # skip archive folder
    if "archive" in parts:
        return False
    name = path.name.lower()
    if name.endswith("-backup.md"):
        return False
    return True


def find_missing_sections(text: str) -> Dict[str, bool]:
    missing = {}
    for key, pat in SECTION_PATTERNS.items():
        missing[key] = pat.search(text) is None
    return missing


def append_sections(text: str, missing: Dict[str, bool]) -> str:
    additions: List[str] = []
    for key, is_missing in missing.items():
        if is_missing:
            additions.append(TEMPLATES[key])
    if not additions:
        return text
    updated = text.rstrip() + "".join(additions)
    # Append one-liner sweep checklist
    checklist = [
        f"status={'added' if missing['status'] else 'present'}",
        f"priority={'added' if missing['priority'] else 'present'}",
        f"tasks={'added' if missing['tasks'] else 'present'}",
        f"dod={'added' if missing['dod'] else 'present'}",
        f"qa={'added' if missing['qa_results'] else 'present'}",
        f"devrec={'added' if missing['dev_agent'] else 'present'}",
    ]
    updated += "\n\n<!-- Consistency Sweep: " + ", ".join(checklist) + " -->\n"
    return updated


def main() -> int:
    write = True
    if len(sys.argv) > 1 and sys.argv[1] in ("--dry-run", "-n"):
        write = False
    changed = 0
    total = 0
    for path in STORIES.rglob("*.md"):
        if not should_process(path):
            continue
        total += 1
        text = path.read_text(encoding="utf-8")
        missing = find_missing_sections(text)
        if any(missing.values()):
            new_text = append_sections(text, missing)
            if write:
                path.write_text(new_text, encoding="utf-8")
            changed += 1
    print(f"Scanned {total} stories, updated {changed} files with missing sections.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
