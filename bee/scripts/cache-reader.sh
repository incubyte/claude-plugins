#!/usr/bin/env bash
set -eo pipefail

# cache-reader.sh — Cache validation and parsing for Playwright-BDD initialization workflow.
# Called via Bash from playwright-bdd.md to check cache status and read cached data.
#
# Usage:
#   cache-reader.sh check                        # returns: missing|fresh|stale|corrupt
#   cache-reader.sh validate [current-features] [current-steps]  # check staleness
#   cache-reader.sh get --field [field-name]     # returns single value
#   cache-reader.sh get                          # returns full file content
#
# check command outputs one of:
#   missing  - cache file does not exist OR partial cache detected (missing sections)
#   fresh    - cache exists and file counts are within ±1
#   stale    - cache exists but file counts changed by ±2 or more
#   corrupt  - cache exists but structure is invalid (parse error)
#
# validate command takes current counts and returns staleness status

CACHE_FILE="docs/playwright-init.md"

# --- Helpers ---

read_field() {
  local file="$1" key="$2"
  if [[ ! -f "$file" ]]; then
    echo ""
    return
  fi
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file")
  local line
  line=$(echo "$frontmatter" | grep "^${key}:" || true)
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  # Strip key prefix and surrounding quotes
  local value
  value=$(echo "$line" | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/')
  echo "$value"
}

validate_structure() {
  local file="$1"

  # Check frontmatter exists
  if ! grep -q "^---$" "$file"; then
    return 1
  fi

  # Check required frontmatter fields
  local last_updated
  last_updated=$(read_field "$file" "last_updated")
  if [[ -z "$last_updated" ]]; then
    return 1
  fi

  local feature_count
  feature_count=$(read_field "$file" "feature_file_count")
  if [[ -z "$feature_count" ]]; then
    return 1
  fi

  local step_count
  step_count=$(read_field "$file" "step_file_count")
  if [[ -z "$step_count" ]]; then
    return 1
  fi

  # Check required sections exist
  if ! grep -q "^## Summary$" "$file"; then
    return 1
  fi

  if ! grep -q "^## Context Summary$" "$file"; then
    return 1
  fi

  if ! grep -q "^## Flow Catalog$" "$file"; then
    return 1
  fi

  if ! grep -q "^## Pattern Catalog$" "$file"; then
    return 1
  fi

  if ! grep -q "^## Steps Catalog$" "$file"; then
    return 1
  fi

  return 0
}

detect_partial_cache() {
  local file="$1"

  # If file doesn't exist, not partial
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Count how many required sections are present
  local section_count=0

  if grep -q "^## Summary$" "$file"; then
    ((section_count++))
  fi

  if grep -q "^## Context Summary$" "$file"; then
    ((section_count++))
  fi

  if grep -q "^## Flow Catalog$" "$file"; then
    ((section_count++))
  fi

  if grep -q "^## Pattern Catalog$" "$file"; then
    ((section_count++))
  fi

  if grep -q "^## Steps Catalog$" "$file"; then
    ((section_count++))
  fi

  # Partial cache: some sections exist but not all 5
  if [[ $section_count -gt 0 && $section_count -lt 5 ]]; then
    return 0
  fi

  return 1
}

check_staleness() {
  local cached_features="$1"
  local cached_steps="$2"
  local current_features="$3"
  local current_steps="$4"

  # Calculate deltas
  local feature_delta=$(( current_features - cached_features ))
  local step_delta=$(( current_steps - cached_steps ))

  # Get absolute values
  if [[ $feature_delta -lt 0 ]]; then
    feature_delta=$(( -feature_delta ))
  fi
  if [[ $step_delta -lt 0 ]]; then
    step_delta=$(( -step_delta ))
  fi

  # Stale if either delta is 2 or more
  if [[ $feature_delta -ge 2 || $step_delta -ge 2 ]]; then
    echo "stale"
  else
    echo "fresh"
  fi
}

# --- Commands ---

cmd_check() {
  # Check if cache file exists
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "missing"
    return 0
  fi

  # Check for partial cache (missing sections)
  if detect_partial_cache "$CACHE_FILE"; then
    echo "missing"
    return 0
  fi

  # Check if structure is valid
  if ! validate_structure "$CACHE_FILE"; then
    echo "corrupt"
    return 0
  fi

  # If we can't determine staleness without current counts, report as fresh
  # (caller needs to use validate command to check staleness)
  echo "fresh"
}

cmd_validate() {
  if [[ $# -lt 2 ]]; then
    echo "Error: validate requires current feature count and step count" >&2
    exit 1
  fi

  local current_features="$1"
  local current_steps="$2"

  # First check if cache exists and is valid
  local status
  status=$(cmd_check)

  if [[ "$status" == "missing" || "$status" == "corrupt" ]]; then
    echo "$status"
    return 0
  fi

  # Read cached counts
  local cached_features
  cached_features=$(read_field "$CACHE_FILE" "feature_file_count")
  local cached_steps
  cached_steps=$(read_field "$CACHE_FILE" "step_file_count")

  # Check staleness
  check_staleness "$cached_features" "$cached_steps" "$current_features" "$current_steps"
}

cmd_get() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "Error: Cache file not found" >&2
    exit 1
  fi

  if [[ $# -gt 0 && "$1" == "--field" ]]; then
    if [[ $# -lt 2 ]]; then
      echo "Error: --field requires a field name" >&2
      exit 1
    fi
    read_field "$CACHE_FILE" "$2"
  else
    cat "$CACHE_FILE"
  fi
}

# --- Main ---

if [[ $# -eq 0 ]]; then
  echo "Usage: cache-reader.sh {check|validate|get} [args...]" >&2
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  check)    cmd_check "$@" ;;
  validate) cmd_validate "$@" ;;
  get)      cmd_get "$@" ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: cache-reader.sh {check|validate|get} [args...]" >&2
    exit 1
    ;;
esac
