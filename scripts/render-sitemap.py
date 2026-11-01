#!/usr/bin/env python3
"""Render docs/SITEMAP.md as a local HTML page with its Mermaid diagrams drawn.

Usage: python3 -I scripts/render-sitemap.py  (writes docs/design/sitemap.html)
The Markdown file stays the source of truth; this is only a viewer.
"""
import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "SITEMAP.md"
OUT = ROOT / "docs" / "design" / "sitemap.html"


def inline(text):
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return text


def convert(markdown):
    out, lines, i = [], markdown.splitlines(), 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("```mermaid"):
            body = []
            i += 1
            while not lines[i].startswith("```"):
                body.append(lines[i]); i += 1
            out.append(f'<figure class="diagram"><pre class="mermaid">{html.escape(chr(10).join(body))}</pre></figure>')
        elif line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip("|").split("|")]
                if not all(set(c) <= set("- ") for c in cells):
                    rows.append(cells)
                i += 1
            head, *body = rows
            out.append("<div class=\"table\"><table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
                       + "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in row) + "</tr>" for row in body) + "</tbody></table></div>")
            continue
        elif m := re.match(r"(#{1,3}) (.+)", line):
            level = len(m.group(1))
            out.append(f"<h{level}>{inline(m.group(2))}</h{level}>")
        elif re.match(r"(\d+\.|-) ", line):
            ordered = line[0].isdigit()
            items = []
            while i < len(lines) and re.match(r"(\d+\.|-) ", lines[i]):
                items.append(re.sub(r"^(\d+\.|-) ", "", lines[i])); i += 1
            tag = "ol" if ordered else "ul"
            out.append(f"<{tag}>" + "".join(f"<li>{inline(t)}</li>" for t in items) + f"</{tag}>")
            continue
        elif line.strip():
            out.append(f"<p>{inline(line)}</p>")
        i += 1
    return "\n".join(out)


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Meridian sitemap</title>
<style>
  :root { --bg: #f6f5f2; --surface: #fff; --ink: #17161a; --ink-2: #57545e; --line: #e2dfd8; --accent: #1f5eff; }
  @media (prefers-color-scheme: dark) { :root { --bg: #0f0f12; --surface: #18181d; --ink: #f2f1f4; --ink-2: #b5b2bd; --line: #2c2c34; --accent: #8aa8ff; } }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--ink); font: 16px/1.55 -apple-system, BlinkMacSystemFont, "SF Pro Text", Inter, sans-serif; }
  main { max-width: 1100px; margin: 0 auto; padding: 40px 24px 80px; }
  h1 { font: 700 36px/1.1 -apple-system, "SF Pro Rounded", Inter, sans-serif; letter-spacing: -0.02em; margin: 0 0 12px; }
  h2 { font-size: 24px; margin: 48px 0 12px; padding-top: 16px; border-top: 1px solid var(--line); }
  h3 { font-size: 18px; margin: 28px 0 8px; }
  p, li { color: var(--ink-2); max-width: 820px; }
  strong { color: var(--ink); }
  code { font: 13px ui-monospace, Menlo, monospace; background: var(--surface); border: 1px solid var(--line); border-radius: 6px; padding: 1px 5px; }
  .diagram { margin: 16px 0 24px; padding: 20px; background: var(--surface); border: 1px solid var(--line); border-radius: 14px; overflow-x: auto; }
  .diagram pre { margin: 0; text-align: center; }
  .table { overflow-x: auto; margin: 12px 0 20px; }
  table { border-collapse: collapse; width: 100%; background: var(--surface); border: 1px solid var(--line); border-radius: 12px; overflow: hidden; font-size: 14px; }
  th, td { text-align: left; vertical-align: top; padding: 10px 12px; border-bottom: 1px solid var(--line); }
  th { font-size: 12px; text-transform: uppercase; letter-spacing: .05em; color: var(--ink-2); }
  td { color: var(--ink-2); }
  @media (max-width: 640px) { main { padding: 24px 16px 64px; } }
</style>
</head>
<body>
<main>
__BODY__
</main>
<script type="module">
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs";
  const dark = matchMedia("(prefers-color-scheme: dark)").matches;
  mermaid.initialize({ startOnLoad: true, theme: dark ? "dark" : "neutral", flowchart: { htmlLabels: true, curve: "basis", useMaxWidth: true },
    themeVariables: { fontFamily: "-apple-system, BlinkMacSystemFont, Inter, sans-serif", fontSize: "15px" } });
</script>
</body>
</html>
"""


def main():
    body = convert(SOURCE.read_text())
    OUT.write_text(PAGE.replace("__BODY__", body))
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
