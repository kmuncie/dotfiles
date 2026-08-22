#!/usr/bin/env python3
"""Render an eval run's results.json as a self-contained HTML report.

The point is the side-by-side prompt comparison. Six of the eight quality prompts are
deliberately not auto-scored — an eight-prompt rubric cannot support a number honestly —
so the only way they inform a decision is if somebody reads them. Until this existed the
answers were captured in results.json and never surfaced, which meant they informed
nothing.

Each prompt gets one row per model, with the `looking_for` note stating the failure mode
being probed, so reading it is a two-minute job rather than an exercise in remembering
what the prompt was for.

Runnable standalone against any past run:

    ./report.py                       # newest run in ~/.cache/llm-eval
    ./report.py <dir>                 # a specific run directory
    ./report.py <path/to/results.json>
"""

import html
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

RESULT_DIR = Path.home() / ".cache" / "llm-eval"

CSS = """
:root {
  --bg: #fbfbfa; --fg: #1a1a18; --muted: #6b6b66; --line: #e2e2dd;
  --card: #ffffff; --code-bg: #f5f5f2; --accent: #3a6ea5;
  --pass: #2d6a4f; --fail: #9b2226; --warn: #9a6700;
  --pass-bg: #e8f3ee; --fail-bg: #fbeaea; --warn-bg: #fdf6e3;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #16161a; --fg: #e8e8e3; --muted: #9a9a94; --line: #2e2e34;
    --card: #1e1e23; --code-bg: #131317; --accent: #7fb3e8;
    --pass: #7fd1a8; --fail: #f08a8a; --warn: #e8c46a;
    --pass-bg: #1a2e25; --fail-bg: #2e1a1a; --warn-bg: #2e2718;
  }
}
:root[data-theme="dark"] {
  --bg: #16161a; --fg: #e8e8e3; --muted: #9a9a94; --line: #2e2e34;
  --card: #1e1e23; --code-bg: #131317; --accent: #7fb3e8;
  --pass: #7fd1a8; --fail: #f08a8a; --warn: #e8c46a;
  --pass-bg: #1a2e25; --fail-bg: #2e1a1a; --warn-bg: #2e2718;
}
* { box-sizing: border-box; }
body {
  background: var(--bg); color: var(--fg); margin: 0;
  font: 15px/1.6 ui-sans-serif, -apple-system, "Segoe UI", sans-serif;
  padding: 2rem 1.25rem 6rem;
}
.wrap { max-width: 1400px; margin: 0 auto; }
h1 { font-size: 1.6rem; margin: 0 0 .3rem; letter-spacing: -.01em; }
h2 {
  font-size: 1.15rem; margin: 3rem 0 .75rem; padding-bottom: .4rem;
  border-bottom: 2px solid var(--line);
}
h3 { font-size: .95rem; margin: 0 0 .35rem; }
.sub { color: var(--muted); font-size: .88rem; margin: 0 0 .35rem; }
.note {
  background: var(--card); border: 1px solid var(--line); border-left: 3px solid var(--accent);
  padding: .7rem .9rem; border-radius: 5px; font-size: .88rem; color: var(--muted);
  margin: .75rem 0 1.25rem;
}
.scroll { overflow-x: auto; margin-bottom: 1rem; }
table { border-collapse: collapse; width: 100%; font-size: .88rem; }
th, td {
  text-align: left; padding: .5rem .7rem; border-bottom: 1px solid var(--line);
  white-space: nowrap;
}
th { font-weight: 600; color: var(--muted); font-size: .78rem;
     text-transform: uppercase; letter-spacing: .04em; }
tbody tr:hover { background: var(--code-bg); }
code, pre, .mono { font-family: ui-monospace, "SF Mono", Menlo, monospace; }
code { background: var(--code-bg); padding: .1rem .3rem; border-radius: 3px; font-size: .85em; }

.prompt-block {
  background: var(--card); border: 1px solid var(--line);
  border-radius: 8px; padding: 1rem 1.15rem; margin-bottom: 2.25rem;
}
.prompt-text {
  background: var(--code-bg); border-radius: 5px; padding: .7rem .85rem;
  font-size: .85rem; white-space: pre-wrap; word-break: break-word;
  max-height: 16rem; overflow-y: auto; margin: .5rem 0 .75rem;
}
.looking {
  font-size: .85rem; color: var(--muted); border-left: 3px solid var(--warn);
  padding: .45rem .75rem; background: var(--warn-bg); border-radius: 0 5px 5px 0;
  margin-bottom: 1rem;
}
.grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); }
.answer { border: 1px solid var(--line); border-radius: 6px; overflow: hidden; background: var(--bg); }
.answer-head {
  display: flex; flex-wrap: wrap; gap: .4rem; align-items: center;
  padding: .5rem .75rem; background: var(--code-bg); border-bottom: 1px solid var(--line);
}
.answer-head .name { font-weight: 600; font-size: .9rem; }
.answer-body {
  padding: .75rem .85rem; white-space: pre-wrap; word-break: break-word;
  font-size: .84rem; max-height: 34rem; overflow-y: auto;
}
.empty { color: var(--fail); font-style: italic; }
.badge {
  font-size: .7rem; padding: .12rem .45rem; border-radius: 10px;
  border: 1px solid currentColor; font-weight: 600; white-space: nowrap;
}
.b-pass { color: var(--pass); background: var(--pass-bg); }
.b-fail { color: var(--fail); background: var(--fail-bg); }
.b-warn { color: var(--warn); background: var(--warn-bg); }
.b-mute { color: var(--muted); background: var(--code-bg); }
details { margin-top: .6rem; font-size: .82rem; }
summary { cursor: pointer; color: var(--muted); }
footer { margin-top: 4rem; padding-top: 1rem; border-top: 1px solid var(--line);
         color: var(--muted); font-size: .82rem; }
"""


def esc(s):
    return html.escape(str(s if s is not None else ""))


def badge(text, kind="mute"):
    return f'<span class="badge b-{kind}">{esc(text)}</span>'


def _started(results):
    return [r for r in results if r.get("started")]


def _fit_verdict(r):
    p, m = r.get("peak") or {}, r.get("memory") or {}
    swap = p.get("peak_swap_mb") or 0
    if not m.get("long_prompt_ok"):
        return "does not fit (prompt failed)", "fail"
    if swap > 3000:
        return "does not fit (heavy swap)", "fail"
    if swap > 1500:
        return "marginal", "warn"
    if swap > 800:
        return "marginal", "warn"
    return "fits", "pass"


def render_overview(results):
    rows = []
    for r in results:
        if not r.get("started"):
            rows.append(f"<tr><td><code>{esc(r['profile'])}</code></td>"
                        f"<td colspan='6'>{badge('failed to start', 'fail')}</td></tr>")
            continue
        p = r.get("peak") or {}
        verdict, kind = _fit_verdict(r)
        q = [c for c in r.get("quality", []) if c.get("ok")]
        rates = sorted(c["tokens_per_s"] for c in q if c.get("tokens_per_s"))
        med = rates[len(rates) // 2] if rates else "—"
        tools = r.get("tools", [])
        tp = sum(1 for c in tools if c.get("verdict") == "pass")
        empty = sum(1 for c in q if not (c.get("content") or "").strip())
        rows.append(
            "<tr>"
            f"<td><code>{esc(r['profile'])}</code></td>"
            f"<td class='mono'>{esc(r.get('model'))}</td>"
            f"<td>{(p.get('peak_swap_mb') or 0):.0f} MB</td>"
            f"<td>{(p.get('peak_wired_mb') or 0):.0f} MB</td>"
            f"<td>{badge(verdict, kind)}</td>"
            f"<td>{tp}/{len(tools)}</td>"
            f"<td>{med}</td>"
            f"<td>{badge(f'{empty}/{len(q)}', 'fail' if empty else 'pass')}</td>"
            "</tr>")
    return f"""<h2>Overview</h2>
<div class="note">Peak swap is absolute, sampled continuously across the whole profile
lifetime. <strong>No answer</strong> counts prompts where the model spent its entire token
budget on reasoning and returned nothing — any non-zero value means the quality comparison
for that model is a budget artifact, not a capability signal.</div>
<div class="scroll"><table>
<thead><tr><th>Profile</th><th>Model</th><th>Peak swap</th><th>Peak wired</th>
<th>Fit</th><th>Tools</th><th>Median tok/s</th><th>No answer</th></tr></thead>
<tbody>{''.join(rows)}</tbody></table></div>"""


def render_prompt_sections(results):
    started = _started(results)
    if not started:
        return ""
    # Prompt order and metadata come from the first profile; every profile runs the
    # same set, so any of them serves as the index.
    cases = started[0].get("quality", [])
    out = ["<h2>Answers, side by side</h2>",
           "<div class='note'>The six prompts without an automatic score are the "
           "qualitative material. Nothing grades them — an eight-prompt rubric cannot "
           "support a number honestly — so reading them is the point. Each "
           "<em>Looking for</em> note states the failure mode that prompt probes.</div>"]

    for case in cases:
        cid = case["id"]
        out.append('<div class="prompt-block">')
        scored = case.get("auto_score") is not None
        out.append(f'<h3>{esc(cid)} {badge(case.get("category", ""), "mute")} '
                   f'{badge("auto-scored" if scored else "read it yourself", "mute")}</h3>')
        out.append(f'<div class="prompt-text">{esc(case.get("prompt", ""))}</div>')
        out.append(f'<div class="looking"><strong>Looking for:</strong> '
                   f'{esc(case.get("looking_for", ""))}</div>')

        out.append('<div class="grid">')
        for r in started:
            c = next((x for x in r.get("quality", []) if x["id"] == cid), None)
            out.append('<div class="answer">')
            head = [f'<span class="name">{esc(r["profile"])}</span>']
            if c is None or not c.get("ok"):
                head.append(badge("error", "fail"))
                out.append(f'<div class="answer-head">{"".join(head)}</div>')
                err = (c or {}).get("error", "no result recorded")
                out.append(f'<div class="answer-body empty">{esc(err)}</div></div>')
                continue

            content = (c.get("content") or "").strip()
            if c.get("auto_score"):
                head.append(badge(c["auto_score"],
                                  "pass" if c["auto_score"] == "pass" else "fail"))
            if not content:
                head.append(badge("NO ANSWER", "fail"))
            if c.get("finish_reason") == "length":
                head.append(badge("hit token cap", "warn"))
            if c.get("tokens_per_s"):
                head.append(badge(f"{c['tokens_per_s']} tok/s", "mute"))
            if c.get("elapsed_s"):
                head.append(badge(f"{c['elapsed_s']}s", "mute"))
            out.append(f'<div class="answer-head">{"".join(head)}</div>')

            if content:
                body = f'<div class="answer-body">{esc(content)}</div>'
            else:
                body = ('<div class="answer-body empty">No final answer. The model '
                        f'used its whole budget on reasoning '
                        f'({c.get("reasoning_chars", 0):,} chars) and returned empty '
                        'content. This is a configuration artifact, not a model '
                        'failure — raise MAX_TOKENS.</div>')
            out.append(body)
            if c.get("reasoning_chars"):
                out.append(f'<details><summary>{c["reasoning_chars"]:,} characters of '
                           f'reasoning (not captured verbatim)</summary>'
                           f'<p class="sub">Only the length is recorded. Set '
                           f'<code>--reasoning-format</code> on the server to capture '
                           f'traces.</p></details>')
            out.append('</div>')
        out.append('</div></div>')
    return "".join(out)


def render_tools(results):
    started = _started(results)
    if not started:
        return ""
    ids = [c["id"] for c in started[0].get("tools", [])]
    head = "".join(f"<th>{esc(p['profile'])}</th>" for p in started)
    rows = []
    for cid in ids:
        cells = []
        for r in started:
            c = next((x for x in r.get("tools", []) if x["id"] == cid), None)
            v = (c or {}).get("verdict", "—")
            cells.append(f"<td>{badge(v, 'pass' if v == 'pass' else 'fail')}</td>")
        expect = next((c.get("expect_tool") for c in started[0].get("tools", [])
                       if c["id"] == cid), None)
        rows.append(f"<tr><td><code>{esc(cid)}</code></td>"
                    f"<td class='mono'>{esc(expect or 'no call expected')}</td>"
                    f"{''.join(cells)}</tr>")
    return f"""<h2>Tool-calling detail</h2>
<div class="note">The most capability-like signal here. Checks the right tool is chosen,
its arguments are valid JSON carrying the expected values, and — for the last two cases —
that the model correctly declines to call anything at all.</div>
<div class="scroll"><table>
<thead><tr><th>Case</th><th>Expected</th>{head}</tr></thead>
<tbody>{''.join(rows)}</tbody></table></div>"""


def render_html(results, source=None):
    started = _started(results)
    gen = datetime.now(timezone.utc).isoformat(timespec="seconds")
    samplers = "".join(
        f"<tr><td><code>{esc(r['profile'])}</code></td>"
        f"<td class='mono'>{esc(r.get('sampler', 'unknown'))}</td>"
        f"<td class='mono'>{esc(r.get('speculative') or '—')}</td></tr>"
        for r in started)
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Local LLM eval — {esc(', '.join(r['profile'] for r in started))}</title>
<style>{CSS}</style></head><body><div class="wrap">
<h1>Local LLM evaluation</h1>
<p class="sub">Rendered {esc(gen)}{f' from <code>{esc(source)}</code>' if source else ''} ·
{len(started)} profile(s) started, {len(results)} attempted</p>
<div class="note">Every model was started through <code>llamactl</code>, at its own
authors' recommended sampler settings, so these numbers reflect the configuration real
sessions use. This is a fitness and smoke test — it answers <em>can I run this, and does
it call tools correctly</em>. It is not a capability benchmark: eight single-turn prompts
cannot tell you which model is better at your actual work, and nothing here measures
multi-turn behaviour or agentic loops.</div>
{render_overview(results)}
{render_tools(results)}
{render_prompt_sections(results)}
<h2>Serving configuration used</h2>
<div class="note">Recorded, not chosen — llamactl decides these and reports them at
startup. A <code>speculative</code> entry that is blank on a profile named
<code>-mtp</code> means the draft model did not load and that profile is silently
identical to its baseline.</div>
<div class="scroll"><table><thead><tr><th>Profile</th><th>Sampler</th>
<th>Speculative</th></tr></thead>
<tbody>{samplers}</tbody></table></div>
<footer>Generated by <code>scripts/llm-eval/report.py</code>. Raw data, including every
answer verbatim, is in <code>results.json</code> alongside this file.</footer>
</div></body></html>"""


def resolve(arg=None):
    """Find a results.json from a path, a directory, or the newest run."""
    if arg:
        p = Path(arg).expanduser()
        if p.is_dir():
            return p / "results.json"
        return p
    runs = sorted((d for d in RESULT_DIR.glob("*/") if (d / "results.json").exists()),
                  key=lambda d: d.name)
    if not runs:
        raise SystemExit(f"no runs with results.json under {RESULT_DIR}")
    return runs[-1] / "results.json"


def main():
    src = resolve(sys.argv[1] if len(sys.argv) > 1 else None)
    if not src.exists():
        raise SystemExit(f"not found: {src}")
    results = json.loads(src.read_text())
    out = src.parent / "report.html"
    out.write_text(render_html(results, source=src.parent.name))
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
