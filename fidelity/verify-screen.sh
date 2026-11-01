#!/bin/zsh
# Screen check (D3-1): runs FidelityTests for one screen, or every screen with no argument, against
# fidelity/inventory/<screen>.json, and writes screenshots to fidelity/shots/ (git-ignored: they contain artwork, D-37).
# Prints ALL PASS when every item is present with its exact copy.
# Usage: fidelity/verify-screen.sh [welcome|upcoming|upcoming-empty|detail|settings]
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p fidelity/shots
only=(-only-testing:MeridianUITests/FidelityTests)
[[ $# -gt 0 ]] && only=(-only-testing:"MeridianUITests/FidelityTests/test_${1//-/_}")
xcodegen generate --quiet
log=$(mktemp)
TEST_RUNNER_FIDELITY_SHOTS="$PWD/fidelity/shots" xcodebuild -scheme MeridianFidelity \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -collect-test-diagnostics never \
  "${only[@]}" test > "$log" 2>&1 && result=0 || result=$?
grep -E "error:|Executed .* tests?" "$log" | grep -v "^\s*$" | sort -u || true
xcrun simctl shutdown all 2>/dev/null || true
if [[ $result -eq 0 ]]; then echo "ALL PASS (${1:-all screens}); shots in fidelity/shots/"; else echo "FAIL (log: $log)"; exit 1; fi
