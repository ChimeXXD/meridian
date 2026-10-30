#!/usr/bin/env python3
"""Write rules/zone-countries.json, IANA zone -> ISO country, from the tz database's zone.tab.

Usage: python3 -I scripts/make-zone-countries.py [/usr/share/zoneinfo/zone.tab]
Airstamp uses it to know the viewer's country from their time zone (D2-6), for "No official stream in your country".
"""
import json
import pathlib
import sys

source = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/usr/share/zoneinfo/zone.tab")
pairs = {}
for line in source.read_text().splitlines():
    if line.startswith("#") or not line.strip():
        continue
    country, _, zone, *_ = line.split("\t")
    pairs[zone] = country
out = pathlib.Path(__file__).resolve().parent.parent / "rules" / "zone-countries.json"
out.write_text(json.dumps(dict(sorted(pairs.items())), indent=0, ensure_ascii=False) + "\n")
print(f"{len(pairs)} zones -> {out.relative_to(out.parent.parent)}")
