#!/usr/bin/env bash
# Checks docs/design/UI-BRIEF.md against docs/SPEC.md (features.json D2-2):
# - every SPEC §1 screen has a section with all 5 parts: job, borrowed references (#n), elements with
#   test IDs, copy (a **Copy:** line or a string quoted from SPEC), and states;
# - the widget section has a row per SPEC §5 family with test IDs and states, plus job, references and states;
# - the Live Activity section has all 5 parts;
# - every string the brief marks (**SPEC**) appears word for word in SPEC.
# Usage: scripts/check-brief.sh [brief.md]
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -I - "${1:-docs/design/UI-BRIEF.md}" docs/SPEC.md <<'EOF'
import re, sys
brief, spec = open(sys.argv[1]).read(), open(sys.argv[2]).read()

def block(pattern, text):
    match = re.search(rf"^{pattern}.*?(?=^#{{1,3}} |\Z)", text, re.M | re.S)
    return match.group(0) if match else None

screens_table = block(r"## 1\. Screens", spec)
screens = [re.sub(r"\s*\(.*?\)", "", row.split("|")[1]).strip()
           for row in screens_table.splitlines() if row.startswith("| ") and not row.startswith("| Screen") and "---" not in row]
families = re.findall(r"^\| `(\w+)` \|", block(r"## 5\. Widgets", spec), re.M)

JOB, BORROWS, STATES = r"\*\*Job:\*\*", r"\*\*Borrows:\*\*.*#\d+", r"\*\*States:\*\*"
ELEMENTS = r"\*\*Elements:\*\*[\s\S]*?`[a-z0-9]+(-[a-z0-9<>…]+)+`"
COPY = r"\*\*Copy:\*\*|\(\*\*SPEC\*\*\)"
problems = []

def need(name, text, parts):
    if text is None:
        problems.append(f"{name}: no section"); return
    problems.extend(f"{name}: missing {part}" for part, pattern in parts.items() if not re.search(pattern, text))

five = {"job": JOB, "references": BORROWS, "elements with test IDs": ELEMENTS, "copy": COPY, "states": STATES}
for screen in screens:
    need(screen, block(rf"### 5\.\d+ {re.escape(screen)}\b", brief), five)

widgets = block(r"### 6\.1 Widgets", brief)
need("Widgets", widgets, {"job": JOB, "references": BORROWS, "states": STATES})
for family in families:
    row = re.search(rf"^\| `{family}` \|(.*)$", widgets or "", re.M)
    cells = [c.strip() for c in row.group(1).split("|")] if row else []
    if len(cells) < 5:
        problems.append(f"Widgets: no full row for {family}")
        continue
    content, test_ids, _, states = cells[0], cells[1], cells[2], cells[3]
    if not re.search(r"`[a-z]+(-[a-z0-9…]+)+`", test_ids): problems.append(f"Widgets: {family} has no test IDs")
    if not states: problems.append(f"Widgets: {family} has no states")

need("Live Activity", block(r"### 6\.2 Live Activity", brief), five)

normalise = lambda s: re.sub(r"\s+", " ", s.replace("“", '"').replace("”", '"'))
spec_text = normalise(spec)
quoted = re.findall(r"(?:\"([^\"]+)\"|`([^`]+)`) \(\*\*SPEC\*\*\)", brief)
for string in (a or b for a, b in quoted):
    if normalise(string) not in spec_text:
        problems.append(f"marked (**SPEC**) but not in SPEC: {string!r}")

if problems:
    print("FAIL brief:\n  " + "\n  ".join(problems)); sys.exit(1)
print(f"PASS brief: {len(screens)} SPEC screens with all 5 parts, {len(families)} widget families, "
      f"the Live Activity, {len(quoted)} SPEC strings found word for word")
EOF
