#!/bin/sh
set -eu

# Non-destructive Browser Gateway integration smoke test.
# No credentials are stored here. If authentication is required, supply it
# through CURL_AUTH, e.g. CURL_AUTH='-u user:password' in the shell only.
#
# Usage:
#   BASE_URL=http://127.0.0.1:6066/ ./scripts/test-gateway.sh
#
# The script performs only GET/PROPFIND requests and does not modify files.

BASE_URL="${BASE_URL:-http://127.0.0.1:6066/}"
CURL_AUTH="${CURL_AUTH:-}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT HUP INT TERM

curl_opts="-fsS"
if [ -n "$CURL_AUTH" ]; then
  # shellcheck disable=SC2086
  curl_opts="$curl_opts $CURL_AUTH"
fi

echo "=== Browser Gateway smoke test ==="
echo "Endpoint: $BASE_URL"

# shellcheck disable=SC2086
curl $curl_opts -D "$tmp" -o /dev/null "$BASE_URL"
grep -qi '^HTTP/.* 200' "$tmp"

# PROPFIND is read-only here. The response is checked for successful WebDAV
# Multi-Status and absence of the internal metadata patterns filtered by v1.1.1.
# shellcheck disable=SC2086
curl $curl_opts -X PROPFIND -H 'Depth: 1' -H 'Content-Type: application/xml' "$BASE_URL" > "$tmp"
grep -q '207\|multistatus' "$tmp" || {
  echo "ERROR: PROPFIND did not return a WebDAV Multi-Status response." >&2
  exit 1
}

for pattern in '.stfolder' '.temp' '.stversions' '.DS_Store' '.trashed-' '.mace_'; do
  if grep -Fq "$pattern" "$tmp"; then
    echo "ERROR: filtered metadata pattern is visible: $pattern" >&2
    exit 1
  fi
done

echo "OK   browser GET"
echo "OK   WebDAV PROPFIND"
echo "OK   hidden metadata filtering"
echo "=== PASSED ==="
