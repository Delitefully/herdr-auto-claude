#!/bin/sh
# Test: start-claude.sh leaves a space alone when its cwd has a cos claim file.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/space" "$tmp/state/claims"
space=$(cd "$tmp/space" && pwd -P)

cat >"$tmp/herdr" <<EOF
#!/bin/sh
echo "\$*" >>"$tmp/calls"
case "\$1 \$2" in
"pane list") printf '{"result":{"panes":[{"pane_id":"w7:p1","cwd":"%s"}]}}' "$space" ;;
"agent start") printf '{"result":{}}' ;;
esac
EOF
chmod +x "$tmp/herdr"

run() {
	: >"$tmp/calls"
	HERDR_BIN_PATH="$tmp/herdr" COS_STATE_DIR="$tmp/state" \
		HERDR_PLUGIN_EVENT_JSON='{"workspace_id":"w7"}' sh "$here/start-claude.sh"
}

run
grep -q '^agent start' "$tmp/calls" || { echo "FAIL: no claim, but Claude was not started"; exit 1; }

printf 'plt-1\n' >"$tmp/state/claims/$(printf '%s' "$space" | shasum | cut -c 1-16)"
run
if grep -q '^agent start' "$tmp/calls"; then echo "FAIL: claimed space still got a Claude"; exit 1; fi
echo "ok"
