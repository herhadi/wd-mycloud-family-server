#!/bin/bash
set -eu

# Optional local validation helper. It does not install packages.
# If shellcheck is available, validate every repository shell script.

if ! command -v shellcheck >/dev/null 2>&1; then
  echo 'INFO: shellcheck is not installed; skipping static shell validation.'
  exit 0
fi

status=0
for file in scripts/*.sh; do
  echo "Checking $file"
  if ! shellcheck "$file"; then
    status=1
  fi
done
exit "$status"
