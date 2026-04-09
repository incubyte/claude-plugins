#!/usr/bin/env bash
set -eo pipefail

# cache-writer.sh — Silent cache persistence for Playwright-BDD initialization workflow.
# Called via Bash from playwright-bdd.md to avoid Write/Edit permission prompts.
#
# Usage:
#   cache-writer.sh write --flows "N" --patterns "M" --steps "P" \
#                         --feature-files "12" --step-files "8" \
#                         --context "context summary text" \
#                         --flow-catalog "flow catalog text" \
#                         --pattern-catalog "pattern catalog text" \
#                         --steps-catalog "steps catalog text"
#   cache-writer.sh write --empty               # create empty cache with warning note
#   cache-writer.sh clear                       # removes cache file
#
# Multi-line fields use | as line separator (will be rendered as separate lines):
#   --context "Line 1|Line 2|Line 3"

CACHE_FILE="docs/playwright-init.md"

# --- Helpers ---

render_multiline() {
  local raw="$1"
  if [[ -z "$raw" || "$raw" == "n/a" ]]; then
    echo "$raw"
    return
  fi
  echo "$raw" | tr '|' '\n'
}

escape_yaml() {
  local value="$1"
  echo "${value//\"/\\\"}"
}

format_timestamp() {
  local iso_timestamp="$1"
  # Convert ISO 8601 to human-readable: 2026-03-10T14:30:00Z → March 10, 2026 at 2:30 PM
  if command -v python3 &> /dev/null; then
    python3 -c "from datetime import datetime; dt = datetime.fromisoformat('${iso_timestamp}'.replace('Z', '+00:00')); print(dt.strftime('%B %d, %Y at %-I:%M %p'))" 2>/dev/null || echo "$iso_timestamp"
  else
    echo "$iso_timestamp"
  fi
}

write_cache() {
  mkdir -p "$(dirname "$CACHE_FILE")"

  # Get current timestamp in ISO format
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Format timestamp for human display
  local formatted_timestamp
  formatted_timestamp=$(format_timestamp "$timestamp")

  # Escape values for YAML safety
  local esc_context
  esc_context=$(escape_yaml "$context")
  local esc_flow_catalog
  esc_flow_catalog=$(escape_yaml "$flow_catalog")
  local esc_pattern_catalog
  esc_pattern_catalog=$(escape_yaml "$pattern_catalog")
  local esc_steps_catalog
  esc_steps_catalog=$(escape_yaml "$steps_catalog")

  # Render multi-line fields
  local rendered_context
  rendered_context=$(render_multiline "$context")
  local rendered_flow_catalog
  rendered_flow_catalog=$(render_multiline "$flow_catalog")
  local rendered_pattern_catalog
  rendered_pattern_catalog=$(render_multiline "$pattern_catalog")
  local rendered_steps_catalog
  rendered_steps_catalog=$(render_multiline "$steps_catalog")

  cat > "$CACHE_FILE" <<EOF
---
last_updated: "${timestamp}"
feature_file_count: ${feature_files}
step_file_count: ${step_files}
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: ${flows}
- Patterns: ${patterns}
- Step Definitions: ${steps}
- Last Updated: ${formatted_timestamp}

## Context Summary
${rendered_context}

## Flow Catalog
${rendered_flow_catalog}

## Pattern Catalog
${rendered_pattern_catalog}

## Steps Catalog
${rendered_steps_catalog}
EOF
}

write_empty_cache() {
  mkdir -p "$(dirname "$CACHE_FILE")"

  # Get current timestamp in ISO format
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Format timestamp for human display
  local formatted_timestamp
  formatted_timestamp=$(format_timestamp "$timestamp")

  cat > "$CACHE_FILE" <<EOF
---
last_updated: "${timestamp}"
feature_file_count: 0
step_file_count: 0
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 0
- Patterns: 0
- Step Definitions: 0
- Last Updated: ${formatted_timestamp}

**Warning**: This cache was created for a repository with zero feature files and zero step definition files. No analysis was performed. When feature files are added, the cache will be invalidated automatically.

## Context Summary
No repository context available (zero files detected).

## Flow Catalog
No flows detected (zero feature files).

## Pattern Catalog
No patterns detected (zero feature files).

## Steps Catalog
No step definitions detected (zero step files).
EOF
}

# --- Load defaults ---

load_defaults() {
  empty_mode=false
  flows="0"
  patterns="0"
  steps="0"
  feature_files="0"
  step_files="0"
  context="n/a"
  flow_catalog="n/a"
  pattern_catalog="n/a"
  steps_catalog="n/a"
}

# --- Apply --flag value pairs ---

apply_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --empty)            empty_mode=true;       shift 1 ;;
      --flows)            flows="$2";            shift 2 ;;
      --patterns)         patterns="$2";         shift 2 ;;
      --steps)            steps="$2";            shift 2 ;;
      --feature-files)    feature_files="$2";    shift 2 ;;
      --step-files)       step_files="$2";       shift 2 ;;
      --context)          context="$2";          shift 2 ;;
      --flow-catalog)     flow_catalog="$2";     shift 2 ;;
      --pattern-catalog)  pattern_catalog="$2";  shift 2 ;;
      --steps-catalog)    steps_catalog="$2";    shift 2 ;;
      *)
        echo "Unknown flag: $1" >&2
        exit 1
        ;;
    esac
  done
}

# --- Commands ---

cmd_write() {
  load_defaults
  apply_args "$@"

  # Handle empty cache mode
  if [[ "$empty_mode" == true ]]; then
    write_empty_cache
    echo "Empty cache created at ${CACHE_FILE}"
    return 0
  fi

  # Validate required fields
  if [[ -z "$flows" || -z "$patterns" || -z "$steps" ]]; then
    echo "Error: --flows, --patterns, and --steps are required" >&2
    exit 1
  fi

  if [[ -z "$feature_files" || -z "$step_files" ]]; then
    echo "Error: --feature-files and --step-files are required" >&2
    exit 1
  fi

  write_cache
  echo "Cache written to ${CACHE_FILE}"
}

cmd_clear() {
  rm -f "$CACHE_FILE"
  echo "Cache cleared."
}

# --- Main ---

if [[ $# -eq 0 ]]; then
  echo "Usage: cache-writer.sh {write|clear} [--flag value ...]" >&2
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  write)  cmd_write "$@" ;;
  clear)  cmd_clear "$@" ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: cache-writer.sh {write|clear} [--flag value ...]" >&2
    exit 1
    ;;
esac
