#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BIN="./bin/nymph"

if [[ ! -x "$BIN" ]]; then
  echo "Building nymph..."
  nim c -d:release -d:danger --opt:size -o:./bin/nymph src/nymph.nim >/dev/null
fi

echo "Smoke: run with builtin defaults"
"$BIN" >/dev/null

echo "Smoke: run with --no-color"
"$BIN" --no-color >/dev/null

echo "Smoke: run with override logo name (fallback expected)"
"$BIN" --logo fake-does-not-exist >/dev/null

echo "OK"
