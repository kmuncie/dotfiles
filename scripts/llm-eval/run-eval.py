#!/usr/bin/env python3
"""Evaluate the local GGUF models that llamactl knows how to run.

Everything about the server — flags, port, context size, and the Metal wired-memory
ceiling — is llamactl's business, not this script's. That is the whole point. An earlier
version of this harness launched llama-server itself and silently omitted the raised
wired limit, so it would have measured a configuration that nothing actually runs. Any
number produced here has to come from the same code path as `llamactl chat`.

So: this script starts profiles with `llamactl start`, reads the server PID with
`llamactl pid`, and enumerates candidates with `llamactl profiles`. The profile table
lives in llamactl and is not duplicated here.

Measures three things, in the order that matters on a memory-constrained machine:

  1. Memory and fit  — does the model fit, or does it merely load and then swap?
     docs/local-llm.md is emphatic that these are different outcomes and that only the
     second is visible after a real prompt. Swap and wired memory are sampled before
     start, after load, and after a prompt that fills a meaningful part of the context.

  2. Tool-calling    — can the model emit well-formed tool calls through the same
     endpoint Pi drives? A model that cannot is useless as the `coding` profile no
     matter how well it writes.

  3. Task quality    — a fixed prompt set, saved verbatim for side-by-side reading.
     Only the objectively checkable cases are auto-scored; the rest are recorded, not
     graded, because a prompt set this small cannot honestly support a number.

Usage:
    ./run-eval.py --list                 # profiles llamactl knows about
    ./run-eval.py                        # everyday profiles only
    ./run-eval.py --all                  # everyday + candidates
    ./run-eval.py chat                   # an explicit subset
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# llamactl owns the port. Keep this in sync with LLAMA_PORT in llamactl — the same
# coupling that ~/.pi/agent/models.json has, and for the same reason.
BASE = "http://127.0.0.1:8080"

SCRIPT_DIR = Path(__file__).resolve().parent
PROMPT_DIR = SCRIPT_DIR / "prompts"

# report.py lives beside this script and is also runnable standalone against any past
# run, so an old results.json can be re-rendered without re-running anything.
sys.path.insert(0, str(SCRIPT_DIR))
import report  # noqa: E402
RESULT_DIR = Path.home() / ".cache" / "llm-eval"

# Sampler settings are deliberately NOT sent with requests. They live in llamactl's
# SAMPLERS table, per profile, and llama-server applies them as its defaults.
#
# This reverses an earlier decision worth explaining. The harness used to pin one
# sampler config across every model, on the theory that identical decoding made the
# comparison fair. It does not. Each model's authors publish different values —
# Qwen3.5-9B wants top_k 20, Gemma-4 wants top_k 64 — so a single setting does not
# equalise anything, it just runs somebody at the wrong numbers. Gemma spent this
# repo's entire history sampling from a distribution truncated to a third of its
# intended width.
#
# The right comparison for "which model should I run day to day" is each model at its
# own recommended settings, which is also exactly how llamactl will run it. Omitting
# these fields makes the eval inherit the server defaults llamactl set, so the harness
# measures the real configuration instead of one invented for the occasion.
SAMPLER = {}

# Reasoning models spend their first several *thousand* tokens in `reasoning_content`.
# A small budget returns empty `content` with finish_reason "length" and looks like a
# model failure when it is really a configuration one — see the Troubleshooting table
# in docs/local-llm.md.
#
# This was set to 2048 for the first real run and it silently wrecked the quality
# comparison: Qwen3.5-9B returned no final answer on 4 of 8 prompts and Qwen3.8-27B on
# 4 of 8, while Gemma — which barely reasons — returned all 8. The scoreboard was
# measuring reasoning verbosity against a budget, not capability, and it flattered the
# model that thought least. 8192 leaves room for the ~2000-token reasoning traces
# actually observed, at the cost of a much longer run.
MAX_TOKENS = 8192

# Fixed sampling seed, sent with every request.
#
# The profiles now include near-identical pairs — a model and its MTP twin run the same
# weights — and the recommended samplers use temperature 1.0. Without a fixed seed those
# pairs would differ purely by sampling noise, and there would be no way to tell a real
# difference from a reroll. That matters most for MTP, which verifies its own
# speculations and is therefore distribution-preserving: with a shared seed, a profile
# and its -mtp twin should produce nearly identical text, and any large divergence is
# evidence of a problem rather than of the model changing.
#
# This does not make different models comparable to each other — they have different
# token distributions, so the same seed does not walk the same path. It only removes
# run-to-run variance for a given model, which is what makes A/B comparison meaningful.
SEED = 20260821


# ------------------------------------------------------------------------------
# llamactl interface
# ------------------------------------------------------------------------------

def wired_limit_mb():
    """llamactl's Metal ceiling, read from the script rather than duplicated here.

    Only used to report headroom. If the constant ever moves, this finds it or falls
    back to a clearly-wrong 0 rather than silently reporting stale headroom.
    """
    try:
        src = Path(shutil.which("llamactl")).resolve().read_text()
        m = re.search(r'^WIRED_LIMIT_MB="(\d+)"', src, re.M)
        return int(m.group(1)) if m else 0
    except Exception:
        return 0


def llamactl(*args, check=False, capture=True):
    return subprocess.run(
        ["llamactl", *args], check=check,
        capture_output=capture, text=True,
    )


def list_profiles():
    """Parse `llamactl profiles` into {name: {"model":…, "ctx":…, "kind":…}}."""
    res = llamactl("profiles")
    if res.returncode != 0:
        raise RuntimeError(f"`llamactl profiles` failed: {res.stderr.strip()}")
    out = {}
    for line in res.stdout.splitlines():
        if not line.strip():
            continue
        name, model, ctx, kind = line.split("\t")
        out[name] = {"model": model, "ctx": int(ctx), "kind": kind}
    return out


def server_pid():
    res = llamactl("pid")
    pid = res.stdout.strip()
    return int(pid) if res.returncode == 0 and pid.isdigit() else None


def health_ok():
    """True only when /health returns 200. It returns 503 while the model loads."""
    try:
        with urllib.request.urlopen(f"{BASE}/health", timeout=5) as r:
            return r.status == 200
    except Exception:
        return False


def start_profile(profile, settle_timeout=1800):
    """`llamactl start`, then independently confirm the model is actually loaded.

    Returns (ok, seconds, output). llamactl handles the wired limit, the download, and
    its own health check — but this harness exists to produce trustworthy numbers, so it
    verifies readiness itself rather than taking a single signal on faith.

    That paranoia is not hypothetical. llamactl used to poll /v1/models, which answers
    as soon as the port binds and long before a 15GB model finishes loading. Every
    profile reported a 1.1s load, memory was sampled mid-load, and the 27B candidates
    returned 503 to every request — which looked exactly like "the model does not fit".
    """
    started = time.time()
    # No timeout on the call itself: llamactl's ceiling is an hour to cover a multi-GB
    # first download, and it bails the moment the server process dies.
    res = llamactl("start", profile, capture=True)
    output = res.stdout + res.stderr
    if res.returncode != 0:
        return False, time.time() - started, output

    for _ in range(settle_timeout):
        if health_ok():
            return True, time.time() - started, output
        if server_pid() is None:
            return False, time.time() - started, output + "\nserver died while loading"
        time.sleep(1)
    return False, time.time() - started, output + "\n/health never returned 200"


def stop_profile():
    llamactl("stop")
    # Let the kernel reclaim, or the next model's baseline is polluted by this one.
    time.sleep(8)


# ------------------------------------------------------------------------------
# Memory sampling
# ------------------------------------------------------------------------------

def _wired_mb():
    out = subprocess.run(["vm_stat"], capture_output=True, text=True).stdout
    page = re.search(r"page size of (\d+) bytes", out)
    wired = re.search(r"Pages wired down:\s+(\d+)", out)
    if not page or not wired:
        return None
    return int(wired.group(1)) * int(page.group(1)) / 1e6


def _swap_used_mb():
    out = subprocess.run(
        ["/usr/sbin/sysctl", "-n", "vm.swapusage"], capture_output=True, text=True
    ).stdout
    m = re.search(r"used\s*=\s*([\d.]+)M", out)
    return float(m.group(1)) if m else None


def _rss_mb(pid):
    if pid is None:
        return None
    out = subprocess.run(
        ["/bin/ps", "-o", "rss=", "-p", str(pid)], capture_output=True, text=True
    ).stdout.strip()
    return int(out) / 1024 if out.isdigit() else None


def sample_memory(pid=None):
    return {
        "server_rss_mb": _rss_mb(pid),
        "wired_mb": _wired_mb(),
        "swap_used_mb": _swap_used_mb(),
    }


class MemoryMonitor(threading.Thread):
    """Poll memory continuously for the whole life of a profile and keep the peaks.

    Point-sampling does not work here, and the first real run proved it. Memory was
    sampled three times — before start, after load, after one long prompt — and every
    sample landed in a quiet moment. The 27B profiles were recorded at under 600MB of
    swap and reported as "fits", while the machine was visibly sitting at 5-7GB during
    the tool-calling and quality phases that ran afterwards.

    Two lessons are baked in here:

      * Sample continuously and keep the maximum. The peak is the number that decides
        whether a model is usable; the average is decoration.
      * Report peak *absolute* swap, not a delta from baseline. macOS does not reclaim
        swap eagerly, so once one profile pushes it to 2.6GB the next profile inherits
        that as its baseline and its delta reads ~0 no matter how badly it thrashes.
        Deltas made a swapping model look clean.
    """

    def __init__(self, pid_getter, interval=2.0):
        super().__init__(daemon=True)
        self._pid_getter = pid_getter
        self._interval = interval
        self._stop = threading.Event()
        self.samples = []

    def run(self):
        while not self._stop.is_set():
            try:
                s = sample_memory(self._pid_getter())
                s["t"] = time.time()
                self.samples.append(s)
            except Exception:
                pass
            self._stop.wait(self._interval)

    def stop(self):
        self._stop.set()
        self.join(timeout=10)

    def stats(self):
        def peak(key):
            vals = [s[key] for s in self.samples if s.get(key) is not None]
            return max(vals) if vals else None

        return {
            "n_samples": len(self.samples),
            "peak_swap_mb": peak("swap_used_mb"),
            "peak_wired_mb": peak("wired_mb"),
            "peak_server_rss_mb": peak("server_rss_mb"),
        }


# ------------------------------------------------------------------------------
# HTTP
# ------------------------------------------------------------------------------

def chat(messages, model, tools=None, max_tokens=MAX_TOKENS, timeout=900):
    body = {"model": model, "messages": messages, "max_tokens": max_tokens,
            "seed": SEED, **SAMPLER}
    if tools:
        body["tools"] = tools
    req = urllib.request.Request(
        f"{BASE}/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    started = time.time()
    with urllib.request.urlopen(req, timeout=timeout) as r:
        payload = json.load(r)
    payload["_elapsed_s"] = round(time.time() - started, 2)
    return payload


# ------------------------------------------------------------------------------
# Evaluations
# ------------------------------------------------------------------------------

def eval_memory(pid, model):
    """Sample after load, then after a prompt that genuinely exercises the KV cache.

    A model that loads is not a model that fits. The second sample is the one that
    matters: if swap climbs between them, the model is thrashing rather than running.
    """
    after_load = sample_memory(pid)

    # Roughly 8k tokens — half the 16384 context — so the KV cache is really allocated
    # rather than nominally reserved.
    filler = "The quick brown fox jumps over the lazy dog. " * 700
    try:
        resp = chat([{
            "role": "user",
            "content": f"{filler}\n\nIn one sentence: what animal is mentioned most?",
        }], model=model, max_tokens=256)
        ok = True
        tokens = resp.get("usage", {}).get("prompt_tokens")
        elapsed = resp["_elapsed_s"]
    except Exception as e:
        ok, tokens, elapsed = False, None, None
        print(f"    long-context prompt FAILED: {type(e).__name__}: {e}")

    time.sleep(3)
    return {
        "after_load": after_load,
        "after_prompt": sample_memory(pid),
        "long_prompt_ok": ok,
        "long_prompt_tokens": tokens,
        "long_prompt_elapsed_s": elapsed,
    }


def auto_score(case_id, content):
    """Only the objectively checkable cases. Everything else returns None by design —
    a fabricated rubric score is worse than an honest absence of one."""
    if case_id == "format-strict":
        text = content.strip()
        if text.startswith("```"):
            return "fail: wrapped in a markdown fence"
        try:
            obj = json.loads(text)
        except Exception:
            return "fail: not parseable JSON"
        if set(obj.keys()) != {"language", "year", "typed"}:
            return f"fail: keys were {sorted(obj.keys())}"
        return "pass"

    if case_id == "summarize":
        lines = content.splitlines()
        bullets = [ln for ln in lines if re.match(r"^\s*([-*•]|\d+[.)])\s+", ln)]
        if len(bullets) != 3:
            return f"fail: {len(bullets)} bullets, expected 3"
        if not lines or not re.match(r"^\s*([-*•]|\d+[.)])\s+", lines[0]):
            return "fail: preamble before the first bullet"
        return "pass"

    return None


def eval_quality(cases, model):
    results = []
    for case in cases:
        entry = {"id": case["id"], "category": case["category"],
                 "looking_for": case["looking_for"]}
        try:
            resp = chat([{"role": "user", "content": case["prompt"]}], model=model)
            choice = resp["choices"][0]
            msg = choice["message"]
            content = (msg.get("content") or "").strip()
            usage = resp.get("usage", {})
            ct = usage.get("completion_tokens")

            entry.update({
                "ok": True,
                "content": content,
                "reasoning_chars": len(msg.get("reasoning_content") or ""),
                "finish_reason": choice.get("finish_reason"),
                "elapsed_s": resp["_elapsed_s"],
                "completion_tokens": ct,
                "tokens_per_s": round(ct / resp["_elapsed_s"], 1)
                                if ct and resp["_elapsed_s"] else None,
                "auto_score": auto_score(case["id"], content),
            })
        except Exception as e:
            entry.update({"ok": False, "error": f"{type(e).__name__}: {e}"})
        results.append(entry)
        print(f"    {case['id']:<22} {'ok' if entry.get('ok') else 'FAILED'} "
              f"{entry.get('elapsed_s', '')}s {entry.get('auto_score') or ''}")
    return results


def eval_tools(spec, model):
    tools, results = spec["tools"], []
    for case in spec["cases"]:
        entry = {"id": case["id"], "expect_tool": case["expect_tool"]}
        try:
            resp = chat([{"role": "user", "content": case["prompt"]}],
                        model=model, tools=tools)
            msg = resp["choices"][0]["message"]
            calls = msg.get("tool_calls") or []
            got = calls[0]["function"]["name"] if calls else None
            entry.update({"got_tool": got, "n_calls": len(calls),
                          "elapsed_s": resp["_elapsed_s"], "ok": True})

            if case["expect_tool"] is None:
                entry["verdict"] = "pass" if not calls else f"fail: called {got}"
            elif got != case["expect_tool"]:
                entry["verdict"] = f"fail: expected {case['expect_tool']}, got {got}"
            else:
                raw = calls[0]["function"].get("arguments") or "{}"
                entry["args_raw"] = raw
                try:
                    args = json.loads(raw)
                except Exception:
                    entry["verdict"] = "fail: arguments were not valid JSON"
                else:
                    missing = [
                        k for k, v in case["expect_args"].items()
                        if str(v).lower() not in str(args.get(k, "")).lower()
                    ]
                    entry["verdict"] = "pass" if not missing else f"fail: bad args {missing}"
        except Exception as e:
            entry.update({"ok": False, "verdict": f"error: {type(e).__name__}: {e}"})
        results.append(entry)
        print(f"    {case['id']:<22} {entry.get('verdict')}")
    return results


# ------------------------------------------------------------------------------
# Driver
# ------------------------------------------------------------------------------

def run_profile(name, cfg, outdir, quality_cases, tool_spec):
    print(f"\n=== {name} ({cfg['model']}, ctx {cfg['ctx']}, {cfg['kind']}) ===")

    baseline = sample_memory()
    print(f"  baseline: swap {baseline['swap_used_mb']:.0f}MB, "
          f"wired {baseline['wired_mb']:.0f}MB")
    if baseline["swap_used_mb"] and baseline["swap_used_mb"] > 1500:
        print("  WARNING: baseline swap is already high. macOS does not reclaim swap "
              "eagerly, so a previous profile may still be inflating this. Peak figures "
              "below are absolute and remain valid; treat cross-profile comparison with "
              "care and prefer a fresh boot for a decisive run.")

    # Runs for the entire profile lifetime — load, memory, tools, quality, shutdown.
    # The phases after eval_memory are where the first run's swap actually climbed.
    monitor = MemoryMonitor(server_pid)
    monitor.start()

    print("  llamactl start...")
    ok, load_s, output = start_profile(name)
    if not ok:
        print(f"  FAILED TO START after {load_s:.0f}s")
        monitor.stop()
        return {"profile": name, **cfg, "started": False,
                "baseline": baseline, "peak": monitor.stats(),
                "llamactl_output": output.splitlines()[-25:],
                "server_log_tail": tail(Path.home() / ".cache/llama-server/llama-server.log")}

    pid = server_pid()
    print(f"  up in {load_s:.0f}s (pid {pid})")

    # Recorded, not chosen: llamactl decides the sampler and reports it on startup.
    # Capturing it here means the results file says what decoding actually produced
    # them, rather than leaving a reader to assume.
    sampler = next((ln.split("sampler:", 1)[1].strip()
                    for ln in output.splitlines() if "sampler:" in ln), "unknown")
    spec = next((ln.split("speculative:", 1)[1].strip()
                 for ln in output.splitlines() if "speculative:" in ln), "")
    print(f"  sampler: {sampler}")
    if spec:
        print(f"  speculative: {spec}")

    result = {"profile": name, **cfg, "started": True, "sampler": sampler,
              "speculative": spec, "load_seconds": round(load_s, 1),
              "baseline": baseline}
    try:
        print("  [memory]")
        result["memory"] = eval_memory(pid, cfg["model"])
        print("  [tool-calling]")
        result["tools"] = eval_tools(tool_spec, cfg["model"])
        print("  [quality]")
        result["quality"] = eval_quality(quality_cases, cfg["model"])
    finally:
        stop_profile()
        monitor.stop()

    result["peak"] = monitor.stats()
    result["after_stop"] = sample_memory()
    result["server_log_tail"] = tail(Path.home() / ".cache/llama-server/llama-server.log")
    p = result["peak"]
    print(f"  peak: swap {p['peak_swap_mb']:.0f}MB, wired {p['peak_wired_mb']:.0f}MB "
          f"({p['n_samples']} samples)")
    return result


def tail(path, n=25):
    try:
        return Path(path).read_text(errors="replace").splitlines()[-n:]
    except Exception:
        return []


def render_summary(results):
    WIRED_LIMIT_MB = wired_limit_mb()
    lines = [
        "# Local LLM evaluation",
        "",
        f"Generated {datetime.now(timezone.utc).isoformat(timespec='seconds')}. "
        "Every model was started through `llamactl`, so these numbers reflect the "
        "flags and the raised Metal wired limit that real sessions use.",
        "",
        "## Memory and fit",
        "",
        f"Memory is sampled continuously for the whole life of each profile and the "
        f"**peak** is reported. Swap is absolute, not a delta from baseline: macOS does "
        f"not reclaim swap eagerly, so a delta makes a thrashing model look clean once "
        f"an earlier profile has already inflated the baseline.",
        "",
        f"`wired headroom` is the gap between peak wired memory and llamactl's "
        f"{WIRED_LIMIT_MB}MB ceiling. A small gap means the model is running against "
        f"the limit, which is where swap pressure comes from.",
        "",
        "| Profile | Load | Peak RSS | Peak wired | Wired headroom | Peak swap | Verdict |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in results:
        if not r.get("started"):
            lines.append(
                f"| `{r['profile']}` | — | — | — | — | — | **failed to start** |")
            continue
        p, m = r["peak"], r["memory"]
        swap, wired = p["peak_swap_mb"] or 0, p["peak_wired_mb"] or 0
        headroom = WIRED_LIMIT_MB - wired
        if not m["long_prompt_ok"]:
            verdict = "**does not fit** (prompt failed)"
        elif swap > 3000:
            verdict = "**does not fit** (heavy swap)"
        elif swap > 1500 or headroom < 1500:
            verdict = "**marginal** (running at the ceiling)"
        elif swap > 800:
            verdict = "marginal"
        else:
            verdict = "fits"
        lines.append(
            f"| `{r['profile']}` | {r['load_seconds']}s "
            f"| {(p['peak_server_rss_mb'] or 0):.0f} MB | {wired:.0f} MB "
            f"| {headroom:.0f} MB | {swap:.0f} MB | {verdict} |"
        )

    lines += ["", "## Tool-calling reliability", "",
              "| Profile | Passed | Failures |", "|---|---|---|"]
    for r in results:
        if not r.get("started"):
            continue
        t = r["tools"]
        passed = sum(1 for c in t if c.get("verdict") == "pass")
        fails = [f"`{c['id']}`" for c in t if c.get("verdict") != "pass"]
        lines.append(f"| `{r['profile']}` | {passed}/{len(t)} "
                     f"| {', '.join(fails) if fails else '—'} |")

    lines += ["", "## Quality", "",
              "Auto-scored cases only. The other six are recorded verbatim in "
              "`results.json` for side-by-side reading.", "",
              "`No answer` counts prompts where the model exhausted its "
              f"{MAX_TOKENS}-token budget on reasoning and returned empty `content`. "
              "Any non-zero value invalidates the quality comparison for that model — "
              "it is a budget artifact, not a capability signal, and it penalises "
              "models that reason more.", "",
              "Each model runs at its own authors' recommended sampler settings, taken "
              "from llamactl, not at one setting imposed across all of them. A single "
              "shared config would not equalise anything — the published values differ "
              "per model — it would just run somebody at the wrong numbers.", "",
              "| Profile | Auto-scored | No answer | Median tok/s | Sampler |",
              "|---|---|---|---|---|"]
    for r in results:
        if not r.get("started"):
            continue
        q = [c for c in r["quality"] if c.get("ok")]
        scored = [c for c in q if c.get("auto_score")]
        passed = sum(1 for c in scored if c["auto_score"] == "pass")
        empty = sum(1 for c in q if not (c.get("content") or "").strip())
        rates = sorted(c["tokens_per_s"] for c in q if c.get("tokens_per_s"))
        med = rates[len(rates) // 2] if rates else "—"
        flag = f"**{empty}/{len(q)}**" if empty else f"0/{len(q)}"
        lines.append(f"| `{r['profile']}` | {passed}/{len(scored)} | {flag} | {med} "
                     f"| `{r.get('sampler', 'unknown')}` |")

    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("profiles", nargs="*", help="profile names (default: everyday only)")
    ap.add_argument("--all", action="store_true", help="include candidate profiles")
    ap.add_argument("--list", action="store_true", help="list profiles and exit")
    args = ap.parse_args()

    if not shutil.which("llamactl"):
        print("llamactl not on PATH — is the dotfiles stow in place?", file=sys.stderr)
        return 1

    available = list_profiles()

    if args.list:
        for name, cfg in available.items():
            print(f"{name:<16} {cfg['model']:<45} ctx {cfg['ctx']:<7} {cfg['kind']}")
        return 0

    if args.profiles:
        unknown = [p for p in args.profiles if p not in available]
        if unknown:
            print(f"unknown profile(s): {unknown}. --list to see the options.",
                  file=sys.stderr)
            return 1
        selected = args.profiles
    elif args.all:
        selected = list(available)
    else:
        selected = [n for n, c in available.items() if c["kind"] == "everyday"]

    # A resident model makes every memory number in the report meaningless, so an
    # already-running server is worth aborting over rather than working around.
    if server_pid() is not None:
        print("A llama-server is already running. `llamactl stop` first — its resident "
              "model would corrupt every memory measurement.", file=sys.stderr)
        return 1

    quality_cases = json.loads((PROMPT_DIR / "quality.json").read_text())
    tool_spec = json.loads((PROMPT_DIR / "tools.json").read_text())

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    outdir = RESULT_DIR / stamp
    outdir.mkdir(parents=True, exist_ok=True)
    print(f"Profiles: {', '.join(selected)}")
    print(f"Results -> {outdir}")

    results = []
    try:
        for name in selected:
            results.append(
                run_profile(name, available[name], outdir, quality_cases, tool_spec))
            # Write after every profile so a crash on a 27B does not discard baselines.
            (outdir / "results.json").write_text(json.dumps(results, indent=2))
    except KeyboardInterrupt:
        print("\ninterrupted — stopping the server", file=sys.stderr)
        llamactl("stop")
    finally:
        if results:
            (outdir / "results.json").write_text(json.dumps(results, indent=2))
            (outdir / "summary.md").write_text(render_summary(results))
            # The HTML report is where the six ungraded prompts actually become
            # readable. Generated even on an interrupted run, so a partial result is
            # still reviewable. A failure to render must not lose the data.
            try:
                (outdir / "report.html").write_text(
                    report.render_html(results, source=outdir.name))
                print(f"\nWrote {outdir}/results.json, summary.md, report.html")
                print(f"  open {outdir}/report.html")
            except Exception as e:
                print(f"\nWrote {outdir}/results.json and summary.md")
                print(f"  report.html failed to render: {type(e).__name__}: {e}",
                      file=sys.stderr)
                print(f"  retry with: ./report.py {outdir}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
