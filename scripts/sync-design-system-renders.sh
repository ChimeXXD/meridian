#!/bin/zsh
# Copies the app's widget and Live Activity renders into the design system, so the site shows exactly what the app
# draws. The render tests fail while the site's copies differ (MeridianTests/Support/DesignSystemCopy.swift); run this
# once Chime has approved the new renders, then commit the app change and the site's copies together.
# Usage: scripts/sync-design-system-renders.sh            (renders, then copies only what this run drew)
#        scripts/sync-design-system-renders.sh --no-render (copies every render already in fidelity/shots/)
set -euo pipefail
cd "$(dirname "$0")/.."
marker=$(mktemp)
trap 'rm -f "$marker"' EXIT
if [[ "${1:-}" != "--no-render" ]]; then
  # Sync mode skips only the site-copy check (TEST_RUNNER_ variables reach the test process without the prefix), so
  # any other failure, such as a view past its height or a bad art hole, a build error or a crash, copies nothing.
  log=$(mktemp)
  if ! TEST_RUNNER_MERIDIAN_SYNC_RENDERS=1 xcodebuild -scheme Meridian \
    -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test \
    -only-testing:MeridianTests/WidgetRenderTests -only-testing:MeridianTests/LiveActivityLayoutTests > "$log" 2>&1; then
    grep -E "error:|✘|Mach" "$log" | head -8; echo "The render tests failed; nothing copied ($log)"; exit 1
  fi
  rm -f "$log"
else
  touch -t 197001010000 "$marker"  # every render counts
fi
for kind in widgets live-activity; do
  src=fidelity/shots/$kind dst=design-system/assets/$kind
  # Only this run's renders: fidelity/shots/ is never cleared, so a dropped state's old PNG may still be there.
  drawn=("${(@f)$(find "$src" -name '*.png' -newer "$marker")}")
  [[ -n "${drawn[1]:-}" ]] || { echo "No new renders in $src; nothing copied"; exit 1; }
  cp "${drawn[@]}" "$src/art-holes.json" "$dst"/
  # A picture on the site that this run didn't draw is a state the app dropped: list it rather than delete it.
  for f in "$dst"/*.png; do
    (( ${drawn[(Ie)$src/${f:t}]} )) || echo "Not rendered any more (remove it from the site?): $f"
  done
done
echo "Copied. Check: git status design-system/assets"
