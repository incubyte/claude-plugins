#!/usr/bin/env bash
set -eo pipefail

# update-bee-state.sh — Silent state persistence for Bee workflows.
# Called via Bash from build.md to avoid Write/Edit permission prompts.
#
# Usage:
#   update-bee-state.sh init --feature "User auth" --size FEATURE --risk MODERATE
#   update-bee-state.sh set --phase-spec "docs/specs/user-auth.md — confirmed"
#   update-bee-state.sh set --current-slice "Slice 2" --tdd-plan "docs/specs/plan.md"
#   update-bee-state.sh get                        # prints full file
#   update-bee-state.sh get --field feature         # prints single value
#   update-bee-state.sh clear                       # removes state file
#
# Multi-line fields (phase-progress, slice-progress) use | as line separator:
#   --phase-progress "Phase 1: done|Phase 2: executing|Phase 3: not started"
#   --slice-progress "Slice 1: done|Slice 2: executing (3/7 steps)"

STATE_FILE=".claude/bee-state.local.md"

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

render_multiline() {
  local raw="$1"
  if [[ -z "$raw" || "$raw" == "n/a" ]]; then
    echo "$raw"
    return
  fi
  echo "$raw" | tr '|' '\n'
}

write_state() {
  mkdir -p "$(dirname "$STATE_FILE")"

  # Escape double quotes in values for YAML safety
  local esc_feature="${feature//\"/\\\"}"
  local esc_discovery="${discovery//\"/\\\"}"
  local esc_design_brief="${design_brief//\"/\\\"}"
  local esc_boundaries="${boundaries//\"/\\\"}"
  local esc_current_phase="${current_phase//\"/\\\"}"
  local esc_phase_spec="${phase_spec//\"/\\\"}"
  local esc_architecture="${architecture//\"/\\\"}"
  local esc_tdd_plan="${tdd_plan//\"/\\\"}"
  local esc_current_slice="${current_slice//\"/\\\"}"

  # Render multi-line fields
  local rendered_phase_progress
  rendered_phase_progress=$(render_multiline "$phase_progress")
  local rendered_slice_progress
  rendered_slice_progress=$(render_multiline "$slice_progress")

  cat > "$STATE_FILE" <<EOF
---
feature: "${esc_feature}"
size: "${size}"
risk: "${risk}"
discovery: "${esc_discovery}"
design_brief: "${esc_design_brief}"
boundaries: "${esc_boundaries}"
current_phase: "${esc_current_phase}"
phase_spec: "${esc_phase_spec}"
architecture: "${esc_architecture}"
tdd_plan: "${esc_tdd_plan}"
current_slice: "${esc_current_slice}"
---

# Bee State

## Feature
${feature}

## Triage
Size: ${size}
Risk: ${risk}

## Discovery
${discovery}

## Current Phase
${current_phase}

## Phase Spec
${phase_spec}

## Architecture
${architecture}

## Current Slice
${current_slice}

## TDD Plan
${tdd_plan}

## Phase Progress
${rendered_phase_progress}

## Slice Progress
${rendered_slice_progress}
EOF
}

# --- Load existing state (defaults if file missing) ---

load_defaults() {
  feature=""
  size=""
  risk=""
  discovery="not done"
  design_brief=""
  boundaries=""
  current_phase=""
  phase_spec="not yet written"
  architecture="not yet decided"
  tdd_plan="not yet written"
  current_slice=""
  phase_progress="n/a"
  slice_progress=""
}

load_existing() {
  load_defaults
  if [[ ! -f "$STATE_FILE" ]]; then
    return
  fi

  local val

  val=$(read_field "$STATE_FILE" "feature")
  if [[ -n "$val" ]]; then feature="$val"; fi
  val=$(read_field "$STATE_FILE" "size")
  if [[ -n "$val" ]]; then size="$val"; fi
  val=$(read_field "$STATE_FILE" "risk")
  if [[ -n "$val" ]]; then risk="$val"; fi
  val=$(read_field "$STATE_FILE" "discovery")
  if [[ -n "$val" ]]; then discovery="$val"; fi
  val=$(read_field "$STATE_FILE" "design_brief")
  if [[ -n "$val" ]]; then design_brief="$val"; fi
  val=$(read_field "$STATE_FILE" "boundaries")
  if [[ -n "$val" ]]; then boundaries="$val"; fi
  val=$(read_field "$STATE_FILE" "current_phase")
  if [[ -n "$val" ]]; then current_phase="$val"; fi
  val=$(read_field "$STATE_FILE" "phase_spec")
  if [[ -n "$val" ]]; then phase_spec="$val"; fi
  val=$(read_field "$STATE_FILE" "architecture")
  if [[ -n "$val" ]]; then architecture="$val"; fi
  val=$(read_field "$STATE_FILE" "tdd_plan")
  if [[ -n "$val" ]]; then tdd_plan="$val"; fi
  val=$(read_field "$STATE_FILE" "current_slice")
  if [[ -n "$val" ]]; then current_slice="$val"; fi

  # Multi-line fields: read from markdown body, join with |
  local body
  body=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

  local pp
  pp=$(echo "$body" | sed -n '/^## Phase Progress$/,/^## /{/^## /d;p;}' | sed '/^$/d' | paste -sd '|' - || true)
  if [[ -n "$pp" ]]; then phase_progress="$pp"; fi

  local sp
  sp=$(echo "$body" | sed -n '/^## Slice Progress$/,/^$/{ /^## /d; p; }' | sed '/^$/d' | paste -sd '|' - || true)
  if [[ -n "$sp" ]]; then slice_progress="$sp"; fi
}

# --- Apply --flag value pairs ---

apply_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --feature)         feature="$2";         shift 2 ;;
      --size)            size="$2";            shift 2 ;;
      --risk)            risk="$2";            shift 2 ;;
      --discovery)       discovery="$2";       shift 2 ;;
      --design-brief)    design_brief="$2";    shift 2 ;;
      --boundaries)      boundaries="$2";      shift 2 ;;
      --current-phase)   current_phase="$2";   shift 2 ;;
      --phase-spec)      phase_spec="$2";      shift 2 ;;
      --architecture)    architecture="$2";    shift 2 ;;
      --tdd-plan)        tdd_plan="$2";        shift 2 ;;
      --current-slice)   current_slice="$2";   shift 2 ;;
      --phase-progress)  phase_progress="$2";  shift 2 ;;
      --slice-progress)  slice_progress="$2";  shift 2 ;;
      *)
        echo "Unknown flag: $1" >&2
        exit 1
        ;;
    esac
  done
}

# --- Commands ---

cmd_init() {
  load_defaults
  apply_args "$@"

  if [[ -z "$feature" ]]; then
    echo "Error: --feature is required for init" >&2
    exit 1
  fi

  write_state
  echo "State initialized: ${feature} (${size}, ${risk})"
}

cmd_set() {
  load_existing
  apply_args "$@"
  write_state
  echo "State updated."
}

cmd_get() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "No active Bee state."
    exit 0
  fi

  if [[ $# -gt 0 && "$1" == "--field" ]]; then
    read_field "$STATE_FILE" "$2"
  else
    cat "$STATE_FILE"
  fi
}

cmd_clear() {
  rm -f "$STATE_FILE"
  echo "State cleared."
}

# --- Main ---

if [[ $# -eq 0 ]]; then
  echo "Usage: update-bee-state.sh {init|set|get|clear} [--flag value ...]" >&2
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  init)  cmd_init "$@" ;;
  set)   cmd_set "$@" ;;
  get)   cmd_get "$@" ;;
  clear) cmd_clear "$@" ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: update-bee-state.sh {init|set|get|clear} [--flag value ...]" >&2
    exit 1
    ;;
esac
