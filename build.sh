#!/usr/bin/env bash
#
# build.sh — turn each guide's Markdown into a self-contained, printable,
# GitHub-Pages-ready index.html (Mermaid diagrams render client-side).
#
# Repo layout (main branch holds ONLY sources — Markdown + this script):
#   guides/
#     build.sh
#     <project>/README.md        <-- source of truth for each guide
#
# Generated output (NOT committed to main; published to the gh-pages branch by CI):
#   guides/
#     index.html                 <-- landing page (generated from the project READMEs)
#     <project>/index.html       <-- generated guide
#
# Usage:
#   ./build.sh                    # build every <project>/README.md + the landing page
#   ./build.sh models-as-a-service
#   ./build.sh path/to/README.md path/to/index.html
#
# The generated HTML embeds the Markdown inline (works offline / file://),
# loads marked + mermaid from CDN, and includes print CSS for Ctrl+P -> PDF.

set -euo pipefail
cd "$(dirname "$0")"

# ---- build one guide: <project>/README.md -> <project>/index.html -------------
build_one() {
  local src="$1" out="$2"
  local title
  title="$(sed -n 's/^# //p' "$src" | head -1)"
  title="${title:-Guide}"
  TITLE="$title" python3 - "$src" "$out" <<'PY'
import sys, html, pathlib, os
src, out = sys.argv[1], sys.argv[2]
title = os.environ.get("TITLE", "Guide")
md = pathlib.Path(src).read_text(encoding="utf-8")
md_safe = md.replace("</script>", "<\\/script>")
title_safe = html.escape(title)

TEMPLATE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  window.__mermaid = mermaid;
</script>
<style>
  :root{ --bg:#fff; --fg:#1b1f24; --muted:#57606a; --border:#d0d7de;
    --accent:#0969da; --code-bg:#f6f8fa; --th-bg:#f6f8fa; --nav-bg:#f6f8fa; }
  *{box-sizing:border-box}
  html,body{margin:0;padding:0;background:var(--bg);color:var(--fg);
    font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}
  .layout{display:grid;grid-template-columns:300px minmax(0,1fr);max-width:1280px;margin:0 auto;}
  nav.toc{position:sticky;top:0;align-self:start;height:100vh;overflow:auto;
    padding:24px 16px;border-right:1px solid var(--border);background:var(--nav-bg);font-size:14px;}
  nav.toc h2{font-size:13px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);margin:0 0 8px;}
  nav.toc a{display:block;color:var(--fg);text-decoration:none;padding:3px 6px;border-radius:6px;}
  nav.toc a:hover{background:rgba(127,127,127,.15)}
  nav.toc a.h3{padding-left:18px;color:var(--muted);font-size:13px}
  main{padding:32px 48px 120px;min-width:0;}
  main h1{font-size:2em;border-bottom:2px solid var(--border);padding-bottom:.3em;}
  main h2{font-size:1.5em;border-bottom:1px solid var(--border);padding-bottom:.3em;margin-top:2.2em;}
  main h3{font-size:1.2em;margin-top:1.8em;}
  a{color:var(--accent)}
  code{background:var(--code-bg);padding:.15em .4em;border-radius:6px;
    font:0.88em/1.5 "SFMono-Regular",Consolas,"Liberation Mono",monospace;}
  pre{background:var(--code-bg);padding:14px 16px;border-radius:10px;overflow:auto;border:1px solid var(--border);}
  pre code{background:none;padding:0;}
  pre.mermaid{background:transparent;border:none;text-align:center;padding:8px;}
  table{border-collapse:collapse;width:100%;margin:1em 0;display:block;overflow:auto;}
  th,td{border:1px solid var(--border);padding:8px 12px;text-align:left;vertical-align:top;}
  th{background:var(--th-bg);}
  tr:nth-child(2n) td{background:rgba(127,127,127,.04);}
  blockquote{border-left:4px solid var(--accent);margin:1em 0;padding:.4em 1em;
    background:rgba(9,105,218,.06);border-radius:0 8px 8px 0;}
  hr{border:none;border-top:1px solid var(--border);margin:2.5em 0;}
  .toolbar{position:fixed;top:14px;right:20px;z-index:50;display:flex;gap:8px;}
  .toolbar button{font-size:13px;padding:6px 12px;border:1px solid var(--border);
    background:var(--bg);color:var(--fg);border-radius:8px;cursor:pointer;}
  .toolbar button:hover{border-color:var(--accent);color:var(--accent);}
  @media (max-width:900px){ .layout{grid-template-columns:1fr} nav.toc{display:none} main{padding:20px} }
  @media print{
    nav.toc,.toolbar{display:none!important}
    .layout{display:block;max-width:none} main{padding:0} body{font-size:11.5pt}
    main h2{page-break-after:avoid} pre,table,blockquote{page-break-inside:avoid}
    a{color:inherit;text-decoration:none} @page{margin:16mm} }
</style>
</head>
<body>
<div class="toolbar">
  <button onclick="window.print()">🖨️ Print / Save PDF</button>
  <button onclick="document.documentElement.scrollTop=0">↑ Top</button>
</div>
<div class="layout">
  <nav class="toc"><h2>Contents</h2><div id="toc"></div></nav>
  <main id="content"></main>
</div>
<script id="source" type="text/markdown">__MARKDOWN__</script>
<script>
  const md = document.getElementById('source').textContent;
  const renderer = new marked.Renderer();
  const origCode = renderer.code.bind(renderer);
  renderer.code = (code, lang) => {
    const text = (typeof code === 'object') ? code.text : code;
    const language = (typeof code === 'object') ? code.lang : lang;
    if ((language || '').trim() === 'mermaid') return '<pre class="mermaid">' + text + '</pre>';
    return origCode(code, lang);
  };
  marked.setOptions({ renderer, headerIds: true, mangle: false, gfm: true });
  const content = document.getElementById('content');
  content.innerHTML = marked.parse(md);
  const toc = document.getElementById('toc');
  const slug = s => s.toLowerCase().replace(/[^\w\s-]/g,'').trim().replace(/\s+/g,'-');
  content.querySelectorAll('h2, h3').forEach(h => {
    if (!h.id) h.id = slug(h.textContent);
    const a = document.createElement('a');
    a.href = '#' + h.id;
    a.textContent = h.textContent.replace(/^\d+\.?\s*/, '');
    if (h.tagName === 'H3') a.className = 'h3';
    toc.appendChild(a);
  });
  (function initMermaid(){
    if (!window.__mermaid){ return setTimeout(initMermaid, 40); }
    window.__mermaid.initialize({ startOnLoad:false, theme:'default', securityLevel:'loose' });
    window.__mermaid.run({ querySelector:'pre.mermaid' });
  })();
</script>
</body>
</html>
"""
pathlib.Path(out).write_text(
    TEMPLATE.replace("__TITLE__", title_safe).replace("__MARKDOWN__", md_safe),
    encoding="utf-8")
print(f"  built {out}  ({len(md)} bytes)")
PY
}

# ---- build the landing page by scanning every <project>/README.md ------------
build_landing() {
  python3 - <<'PY'
import html, pathlib, re

def meta(readme):
    lines = readme.read_text(encoding="utf-8").splitlines()
    title, desc = None, None
    for ln in lines:
        if title is None and ln.startswith("# "):
            title = ln[2:].strip()
            continue
        if title is not None and ln.strip().startswith(">"):
            desc = ln.strip().lstrip(">").strip()
            break
        if title is not None and ln.strip() and not ln.startswith("#"):
            desc = ln.strip()
            break
    return title, desc

cards = []
for readme in sorted(pathlib.Path(".").glob("*/README.md")):
    proj = readme.parent.name
    title, desc = meta(readme)
    title = title or proj
    desc = desc or ""
    # strip markdown emphasis/links from the blurb for a clean card
    desc = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", desc)
    desc = desc.replace("**", "").replace("*", "").replace("`", "")
    cards.append(
        f'    <a class="card" href="./{html.escape(proj)}/">\n'
        f'      <h2>{html.escape(title)}</h2>\n'
        f'      <p>{html.escape(desc)}</p>\n'
        f'    </a>')

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Engineering Guides</title>
<style>
  :root{ --bg:#fff; --fg:#1b1f24; --muted:#57606a; --border:#d0d7de; --accent:#0969da; --card:#f6f8fa; }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--fg);
    font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}
  .wrap{max-width:880px;margin:0 auto;padding:64px 24px 96px;}
  h1{font-size:2.2em;margin:0 0 .2em;}
  .sub{color:var(--muted);font-size:1.1em;margin-bottom:2.5em;}
  a.card{display:block;text-decoration:none;color:inherit;border:1px solid var(--border);
    background:var(--card);border-radius:14px;padding:20px 22px;margin:14px 0;transition:.15s;}
  a.card:hover{border-color:var(--accent);transform:translateY(-1px);}
  a.card h2{margin:0 0 .3em;font-size:1.25em;color:var(--accent);}
  a.card p{margin:0;color:var(--muted);}
  footer{margin-top:3em;color:var(--muted);font-size:.9em;}
</style>
</head>
<body>
  <div class="wrap">
    <h1>Engineering Guides</h1>
    <p class="sub">In-depth technical learning notes for cloud-native and platform-engineering projects.</p>

__CARDS__

    <footer>Each guide is also available as Markdown in its project directory.</footer>
  </div>
</body>
</html>
"""
pathlib.Path("index.html").write_text(
    TEMPLATE.replace("__CARDS__", "\n".join(cards)), encoding="utf-8")
print(f"  built index.html  ({len(cards)} guide card(s))")
PY
}

# --- dispatch -----------------------------------------------------------------
if [[ $# -eq 2 ]]; then
  build_one "$1" "$2"; exit 0
fi

if [[ $# -eq 1 ]]; then
  if [[ -f "$1" ]]; then build_one "$1" "$(dirname "$1")/index.html";
  elif [[ -d "$1" ]]; then build_one "$1/README.md" "$1/index.html";
  else echo "error: '$1' not found" >&2; exit 1; fi
  exit 0
fi

# No args: build every <project>/README.md + the landing page
found=0
for readme in */README.md; do
  [[ -e "$readme" ]] || continue
  echo "building $readme ..."
  build_one "$readme" "$(dirname "$readme")/index.html"
  found=1
done
[[ $found -eq 1 ]] || { echo "no <project>/README.md files found"; exit 1; }
echo "building landing page ..."
build_landing
echo "Done."
