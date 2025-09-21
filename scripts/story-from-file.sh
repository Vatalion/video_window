#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: $0 docs/stories/<epic-id>.<epic-slug>/<story-id>-<slug>.md
  - <epic-id>: digits (usually 01-09) that group stories by epic
  - <epic-slug>: lowercase `[a-z0-9-]+`
  - <story-id>: dotted numbers (e.g., 05.08 or 05.08.01)
  - <slug>: lowercase `[a-z0-9-]+`
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

file="$1"

if [[ ! -f "$file" ]]; then
  echo "Error: file not found: $file" >&2
  usage
  exit 1
fi

case "$file" in
  */docs/stories/*|docs/stories/*) ;;
  *)
    echo "Error: path must be under docs/stories: $file" >&2
    usage
    exit 1
    ;;
esac

base_dir="$(basename "$(dirname "$file")")"
base_file="$(basename "$file")"

if [[ "$base_file" != *.md ]]; then
  echo "Error: not a Markdown file: $base_file" >&2
  usage
  exit 1
fi

# Validate epic directory naming (allow digits + slug separated by dot)
if [[ "$base_dir" != *.* ]]; then
  echo "Error: epic directory must be <id>.<slug>, got: $base_dir" >&2
  usage
  exit 1
fi

epic_id="${base_dir%%.*}"
epic_slug="${base_dir#*.}"

if [[ ! "$epic_id" =~ ^[0-9]+$ ]]; then
  echo "Error: invalid epic id '$epic_id' (expected digits)." >&2
  exit 1
fi

if [[ ! "$epic_slug" =~ ^[a-z0-9-]+$ ]]; then
  echo "Error: invalid epic slug '$epic_slug' (allowed: lowercase [a-z0-9-])." >&2
  exit 1
fi

name="${base_file%.md}"

if [[ "$name" != *-* ]]; then
  echo "Error: story filename must be <story-id>-<slug>.md, got: $base_file" >&2
  usage
  exit 1
fi

story_id="${name%%-*}"
slug="${name#${story_id}-}"

if [[ -z "$story_id" || -z "$slug" ]]; then
  echo "Error: could not parse story id/slug from $base_file" >&2
  exit 1
fi

if [[ ! "$story_id" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "Error: invalid story id '$story_id' (expected dotted numbers)." >&2
  exit 1
fi

if [[ ! "$slug" =~ ^[a-z0-9-]+$ ]]; then
  echo "Error: invalid slug '$slug' (allowed: lowercase [a-z0-9-])." >&2
  exit 1
fi

echo "story/${story_id}-${slug}"
