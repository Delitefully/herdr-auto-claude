#!/bin/sh
# Start Claude Code in the first pane of a space herdr has just created.
set -eu

herdr="${HERDR_BIN_PATH:-herdr}"

# Read the space from the event, not from HERDR_WORKSPACE_ID: that is the
# invocation context, which herdr fills from the active space when the event
# does not supply one.
workspace_id=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" |
	grep -o '"workspace_id":"[^"]*"' | head -n 1 | cut -d '"' -f 4)
[ -n "$workspace_id" ] || exit 0

pane_json=$("$herdr" pane list --workspace "$workspace_id")
panes=$(printf '%s' "$pane_json" | grep -o '"pane_id":"[^"]*"' | cut -d '"' -f 4)
[ "$(printf '%s\n' "$panes" | grep -c .)" -eq 1 ] || exit 0

# A cos chief of staff starts its own Claude, with a brief, in the spaces it
# creates. It claims each one with a file named after the space's directory.
cwd=$(printf '%s' "$pane_json" | grep -o '"cwd":"[^"]*"' | head -n 1 | cut -d '"' -f 4)
[ -n "$cwd" ] && cwd=$(cd "$cwd" 2>/dev/null && pwd -P || printf '%s' "$cwd")
claims="${COS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/cos}/claims"
[ -n "$cwd" ] && [ -e "$claims/$(printf '%s' "$cwd" | shasum | cut -c 1-16)" ] && exit 0

# Agent names must match [a-z][a-z0-9_-]{0,31} and be unique among live agents.
name=$(printf 'claude-%s' "$workspace_id" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9_-' | cut -c 1-32)

output=$("$herdr" agent start "$name" --kind claude --pane "$panes" --timeout 60000 2>&1) && exit 0

case $output in
# The pane is not an idle shell. Moving a pane that already runs Claude into a
# new space creates the space around it, and that pane is left alone.
*'"agent_pane_busy"'*) exit 0 ;;
# Claude started but is waiting on a prompt, such as the folder trust dialog.
*'"agent_not_ready"'*) exit 0 ;;
esac
printf '%s\n' "$output" >&2
exit 1
