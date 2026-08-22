# Local LLM Setup (llama.cpp + Pi)

Running local GGUF models on this machine — an M5 Pro MacBook Pro with 24GB of
unified memory — for casual chat and for coding work through the
[Pi coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent),
which talks to `llama-server`'s OpenAI-compatible endpoint.

Everything here exists because of a debugging session that produced several
crashes. The point of writing it down is so the *reasoning* survives, not just
the working command line.

## Components

| Path | Purpose |
|------|---------|
| `personal/.local/bin/llamactl` | Start/stop/status the local server, launch Pi against it. Stowed to `~/.local/bin`, already on `PATH` via `personal/.profile`. |
| `scripts/llamactl-wired-limit.sudoers` | Scoped sudoers drop-in for `iogpu.wired_limit_mb`. **No longer needed** — kept only for `LLAMACTL_WIRED_LIMIT_MB` opt-in when evaluating large models. Not stowed. |
| `personal/.pi/agent/models.json` | Points Pi at `http://localhost:8080/v1` as provider `llama-cpp`, and names the one model both modes use. Stowed to `~/.pi/agent/models.json`. |

Only `models.json` is tracked from `~/.pi/agent/`. Its siblings are ignored on
purpose: `auth.json` holds provider credentials, `models-store.json` and
`settings.json` are machine state, and this repo is public. See the `.gitignore`
block that denies `personal/.pi/agent/*` and re-allows the single file.

Note the coupling: `models.json` hardcodes port 8080 in its `baseUrl`, and JSON
cannot carry a comment saying so. If `LLAMA_PORT` in `llamactl` changes, that
file must change with it.

Install `llama.cpp` via `brew bundle` (it is in the Brewfile). Install Pi with
`npm i -g @mariozechner/pi-coding-agent`.

## Quickstart

Two commands cover everyday use. Both start the server themselves — there is no
separate "start it first" step.

```bash
llamactl chat                  # casual chat
llamactl code ~/some/project   # coding agent, rooted in that directory
llamactl stop                  # when done — frees the model and its memory
```

Both open the same Pi TUI. Leave it with `Ctrl-C` or `/exit`. **Leaving Pi does
not stop the server** — the model stays resident in memory until you run
`llamactl stop`. Run `llamactl status` if you are unsure whether something is
still loaded.

Extra arguments pass straight through to Pi, which is handy for one-shot
questions without entering the TUI:

```bash
llamactl chat -p "what does ulimit -n do?"
llamactl code . -p "summarize this repo" --no-session
```

|  | `llamactl chat` | `llamactl code [dir]` |
|---|---|---|
| Model | Gemma-4-12B QAT + MTP | the same one |
| Tools | Off (`--no-tools`) — cannot touch files | Full read/write/edit/bash |
| For | Questions, drafting, thinking out loud | Actual work on a codebase |

Since August 2026 both modes run **one model on one server**. The only difference
between them is whether Pi is given tools, which is a client flag, so switching
is instant — `llamactl start` sees the profile already serving and reuses it
rather than reloading several GB. Measured: 4.3s cold, **0.07s** to switch.

This is the practical reason to consolidate. Previously each mode owned its own
model and swapping meant unloading one and loading the other.

### There is no web UI

This Homebrew build of `llama-server` does not serve one — the root path returns
415. The Pi TUI above is the interface. To talk to the server directly, use the
OpenAI-compatible API:

```bash
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"unsloth/gemma-4-12B-it-qat-GGUF:UD-Q4_K_XL",
       "messages":[{"role":"user","content":"hello"}],
       "max_tokens":512}' | jq -r '.choices[0].message.content'
```

Keep `max_tokens` generous — the model emits reasoning tokens first, so a small
budget returns empty `content`. See Troubleshooting.

## Server management

For when you want the server without a client attached — another editor, a
script, or the `curl` call above:

```bash
llamactl start            # the default profile
llamactl status           # pid, profile, endpoint, wired limit, swap usage
llamactl logs             # follow the server log
llamactl restart
llamactl stop             # kills the server and frees the model
```

## One-time setup: nothing required

As of August 2026 `llamactl` needs no privileged setup. It does not modify any
kernel tunable, and `sudo` is never invoked on a normal start. Install
`llama.cpp` via `brew bundle`, install Pi, and run it.

If a sudoers drop-in for `iogpu.wired_limit_mb` is still installed from the
earlier setup, **it can be removed** — nothing calls it any more:

```bash
sudo rm /etc/sudoers.d/llamactl-wired-limit
sudo visudo -c
sudo -l              # confirm the NOPASSWD entry is gone
```

The rest of this section applies only if you deliberately opt back in with
`LLAMACTL_WIRED_LIMIT_MB`, which is worth doing when evaluating a model large
enough to hit the default ceiling. See "The Metal wired-memory ceiling" below
for why that is no longer the default.

### The scoped sudoers rule (only needed if opting in)

Raising the ceiling needs root. Rather than general passwordless sudo, a drop-in
file permits exactly one command:

```
kmuncie ALL=(root) NOPASSWD: /usr/sbin/sysctl iogpu.wired_limit_mb=*
```

The wildcard covers only the *value*, so `...=21000` and `...=0` match and
nothing else does. Install it — never hand-edit anything under `/etc/sudoers.d`
without validating:

```bash
cd ~/dotfiles
sudo visudo -c -f scripts/llamactl-wired-limit.sudoers
sudo install -m 0440 -o root -g wheel \
    scripts/llamactl-wired-limit.sudoers \
    /etc/sudoers.d/llamactl-wired-limit
sudo visudo -c
sudo -l    # confirm ONLY that one NOPASSWD entry appears
```

The binary path in the rule must match how `llamactl` invokes it. It was
confirmed with `which sysctl` on this machine (macOS 27.0): `/usr/sbin/sysctl`.
A wrong path does not error — the rule simply never matches, and sudo falls back
to prompting for a password. Worse, a typo'd rule can be interpreted more
broadly than intended, which is why `visudo -c` and `sudo -l` are both in the
list above rather than optional.

Without the drop-in, an opted-in `llamactl start` fails fast with instructions
instead of hanging on a password prompt. Unset `LLAMACTL_WIRED_LIMIT_MB` and it
starts normally.

`llamactl stop` resets the sysctl whenever it finds it non-zero, reading the live
value rather than trusting an environment variable. A session that opted in
cannot leave the machine in a raised state just because `stop` ran from a
different shell.

## What was learned the hard way

### Model size: the honest ceiling here is ~12-14B dense

Dense models in the 27-30B class (~17GB of Q4_K_M weights) reliably hit Metal
OOM errors or swap-thrash on this 24GB machine, **even though vendors market
them as fitting a 24GB machine.** The comfortable ceiling for dense models here
is closer to 12-14B (~7-9GB of weights), which is what the `llamactl` profile
uses.

Verify a model actually fits rather than trusting that it loaded: run
`llamactl status` after loading *and* after a real prompt, and check that
`vm.swapusage` stays flat. A model that loads but swaps is not a model that
fits.

### The 27B re-test (August 2026)

The ceiling above was challenged and it held. Unsloth's Qwen3.8-27B was
evaluated at both `UD-IQ4_XS` (13GB) and `UD-Q4_K_M` (15GB) using
`scripts/llm-eval`, on the grounds that IQ4_XS is ~2GB smaller than the quant
the original finding was based on. It was not enough.

| | `chat` (9B) | `coding` (12B) | 27B IQ4_XS | 27B Q4_K_M |
|---|---|---|---|---|
| Peak wired | 8885MB | 10993MB | 17515MB | 19660MB |
| Headroom under the 21000MB ceiling | 12.1GB | 10.0GB | 3.5GB | **1.3GB** |
| Median tok/s | 44.1 | 30.1 | 15.7 | 14.8 |
| 7k-token prompt | 14.0s | 24.2s | 43.4s | 36.8s |
| Tool-calling | 6/6 | 6/6 | 6/6 | 6/6 |

Both 27B quants ran, answered correctly, and called tools perfectly. They also
sat 3x slower than the 9B and drove observed swap to 5-7GB. `Q4_K_M` peaked
1.3GB under the Metal ceiling, leaving under 5GB for the whole of macOS.

The decisive point is not that they failed. It is that they cost 3x throughput
and all the memory headroom while showing **no measurable advantage** on the one
capability dimension that was validly measured — every profile scored 6/6 on
tool-calling. Weights were deleted; the profiles were removed.

**Three ways the first attempts measured the wrong thing.** Each produced a
confident, wrong table, and they are worth knowing because they generalise:

   1. **The readiness check could not fail.** See the "Readiness" section below.
      Every profile reported a 1.1s load and the 27B returned 503 to every
      request. That table read exactly like "too big for this machine" and was
      nothing of the kind.
   2. **Point-sampling missed the peak.** Memory was sampled three times, all
      before the sustained work began. The 27B was recorded at under 600MB of
      swap and labelled "fits" while the machine was visibly at 5-7GB. The
      harness now samples continuously and reports the peak.
   3. **Swap *delta* hid the thrash.** macOS does not reclaim swap eagerly, so
      once one profile pushed swap to 2.6GB the next inherited that as its
      baseline and its delta read `-40MB`.

That third point was then over-corrected, which is worth recording because the
fix was wrong in the opposite direction. Switching to peak *absolute* swap
charged every profile for whatever was already resting on the machine: with
~900MB of pre-existing swap, all five profiles in the next run were flagged
"marginal" while nothing had moved at all.

The metric now is **peak minus the profile's own starting baseline**, sampled
continuously. Continuous sampling is what makes a delta trustworthy — the
original delta was not wrong as a *measure*, it was blind, because three point
samples all landed in quiet moments. Subtracting the profile's own baseline is
what removes the false alarms. Both corrections are needed; either alone
produces a confident wrong answer, and each did.

Validated against both historical runs and a set of synthetic cases: a healthy
profile on a dirty machine (baseline 2600MB, no movement) reads `fits`, and a
thrashing profile inheriting that same dirty baseline reads `does not fit`. The
two earlier metrics each got exactly one of those two cases wrong.

A fourth flaw corrupted the quality comparison rather than the memory one: a
2048-token budget was exhausted by reasoning traces, so Qwen returned no final
answer on half the prompts while Gemma — which barely reasons — answered all of
them. The scoreboard was measuring reasoning verbosity against a budget and
flattering the model that thought least. The harness now uses 8192 tokens and
reports a "No answer" count that invalidates the comparison when non-zero.

Quality was therefore never validly compared between these models. That does not
change the conclusion, because the throughput and memory costs are disqualifying
on their own, but it is the honest limit of what this exercise established.

### Readiness: `/health`, not `/v1/models`

`llama-server` binds its port and starts answering `/v1/models` as soon as the
HTTP listener is up — which is *before* the model has been read off disk. The
endpoint that reflects the model's actual state is `/health`: it returns 503
while loading and 200 when the model is ready to serve.

The distinction is invisible with small models and fatal with large ones. A 5GB
model finishes loading in the second or two before anything gets around to
sending a request. A 15GB model does not, and every request in that window comes
back `503 Service Unavailable`.

`llamactl`'s readiness loop originally polled `/v1/models` with a bare `curl -s`,
which compounded the problem two ways:

   * The wrong endpoint answered before the model existed.
   * `curl -s` exits 0 on a 503. Only `curl -f` turns an HTTP error status into a
     non-zero exit, which is what the loop was actually trying to test.

The result was that `start` returned in about a second for every profile
regardless of size, and handed callers a server that was not ready. The first
full evaluation run reported all four profiles loading in 1.1s, sampled their
memory mid-load, and recorded both 27B candidates as total failures — a result
that read exactly like "too big for this machine" and was nothing of the kind.

The loop now polls `/health` with `curl -sf`. Take the lesson generally: a
readiness check that cannot fail is not a readiness check, and "it came up fast"
deserves suspicion rather than relief.

### `--parallel 1` is load-bearing

`llama-server` defaults to `--parallel 4`. Each slot gets its own copy of the
context window set by `-c`, so the default silently demands **4x** the KV cache
memory you think you asked for. This caused a real OOM. `llamactl` always passes
`--parallel 1`.

### Bind to loopback

Every crash log showed the server listening on all interfaces, with CORS wide
open and no API key. That is defensible for pure localhost use, but a corporate
VPN is active on this machine at times, so `llamactl` pins
`--host 127.0.0.1`. Do not change that to `0.0.0.0` without adding `--api-key`
and thinking about who can reach port 8080.

### The Metal wired-memory ceiling — no longer raised

macOS's default `iogpu.wired_limit_mb` is unset (`0`), which falls back to an
internal heuristic around 75% of total RAM — roughly 18.4GB on this 24576MB
machine. That default was contributing to at least one OOM failure back when the
profiles were 15-17GB models, and raising it to 21000 turned a hard crash into a
working load. It was the right fix for that problem.

**That problem is gone.** The current profile peaks around 11.6GB of system-wide
wired memory, comfortably under the default heuristic. Measured August 2026 with
the sysctl untouched at `0`:

| | Raised to 21000 | macOS default (`0`) |
|---|---|---|
| Peak wired after a 21k-token prompt | 11438 MB | 11608 MB |
| 21k-token prompt latency | 63s | 63s |
| Swap movement during the run | +298 MB | **none** |
| Errors in the server log | 0 | 0 |

So `llamactl` no longer touches it. The raise now buys nothing measurable, and it
is not free: it is an undocumented Apple sysctl, it requires a sudoers drop-in,
and it lets Metal claim more non-pageable memory — which pushes every *other*
process toward swap.

That last point is worth stating plainly, because the intuition runs backwards:
**raising the wired limit does not reduce swap.** It converts an out-of-memory
crash into swap-thrashing. If the goal is less disk writing, leaving it alone is
strictly better once nothing needs it.

Opt back in per-session with `LLAMACTL_WIRED_LIMIT_MB=21000` — appropriate when
evaluating a model large enough to hit the default ceiling, which is exactly the
case the 21000 figure was validated for. It is not auto-detected and should not
be; if the hardware changes, change it consciously.

The downsides below therefore describe a setting that is now **off by default**.
They are kept because they are the reason it is off, and because they apply in
full to anyone who opts back in.

## Downsides of raising the wired limit

These applied to the on-demand approach and apply *more strongly* to the permanent
one. They matter as much as the fix does.

- **Wired memory cannot be paged out.** Raising the ceiling lets Metal claim
  more unified memory as non-swappable. That memory becomes unavailable to every
  other process on the machine for as long as it is held, even if the GPU is not
  actively using all of it at a given moment. This directly reduces the safety
  margin macOS has for everything else running — browser, Slack, IDE.

- **Set too high, this can cause system-wide instability**, not just slowness.
  If wired memory demand exceeds what the kernel needs to keep for its own
  operation, expect beachballing, forced app kills, or in bad cases a reboot.
  The chosen value (21000MB on a 24576MB machine) leaves headroom deliberately.
  Do not casually raise it further without understanding why that margin exists.

- **This is an undocumented, unsupported sysctl.** Apple does not publish
  official semantics for `iogpu.wired_limit_mb`. Behavior is inferred from
  community use, and it could change across macOS updates with no notice or
  deprecation warning. The exact numeric value is not load-bearing precision —
  it is a working heuristic, re-validated on this specific machine and macOS
  version, not a documented Apple API contract.

- **It is global to Metal, not scoped to llama.cpp.** If another GPU-heavy app
  (Xcode, video work, other local ML tooling) runs concurrently with
  `llama-server`, both now operate under the same widened ceiling, and total
  demand can stack in ways that are harder to predict than a single app's
  behavior alone. This is a secondary reason to prefer the on-demand approach —
  it minimizes the window during which that interaction is even possible.

- **Real memory pressure is not actually fixed by this**, only OOM crash
  behavior is. The debugging session showed the wired-limit change turned a hard
  crash into slow swap-thrashing for a model that was genuinely too large for
  the machine — it did not make that model comfortable to run. The fix is
  appropriate for models that genuinely fit with some margin (confirmed via
  `sysctl vm.swapusage` staying flat after load plus a real prompt), not as a
  workaround for models that do not fit at all.

## On-demand vs. permanent: why option A

### Option A — on-demand, tied to `llamactl start`/`stop` (implemented)

`llamactl start` raises `iogpu.wired_limit_mb` before launching the server;
`llamactl stop` resets it to `0` after killing the server. The wider ceiling
exists only while a model is loaded, which shrinks the window in which every
downside above applies.

Costs: it needs the scoped sudoers drop-in described above, and the limit stays
raised if the machine is put to sleep or the process is killed without running
`llamactl stop`. Running `llamactl stop` (or `llamactl status`, to check) fixes
that.

### Option B — permanent, via a LaunchDaemon (documented, **not installed**)

A `LaunchDaemon` plist that sets the wired limit at every boot, system-wide,
for all processes indefinitely:

```xml
<!-- /Library/LaunchDaemons/com.local.iogpu-wired-limit.plist — NOT INSTALLED -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.iogpu-wired-limit</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/sbin/sysctl</string>
        <string>iogpu.wired_limit_mb=21000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

**Pros:** simpler — no sudoers rule, no wrapper script involvement, survives
reboots, never in a half-applied state.

**Cons:** the relaxed ceiling applies at all times, even when no LLM is running,
and to every Metal-using process on the machine rather than just
`llama-server`. Every downside in the section above is then permanently in
effect instead of scoped to a session. This is the reason it is documented but
not installed.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| `start` fails with a sudo error | Only possible with `LLAMACTL_WIRED_LIMIT_MB` set. Unset it — the default profile does not need a raised ceiling. |
| Server never comes up | `llamactl logs`. First run of a profile downloads several GB; the health check waits 120s. |
| Loads, then everything crawls | `llamactl status` — if `vm.swapusage` is climbing, the model is too big. Use a smaller one; the wired limit will not rescue it. |
| Pi cannot reach the model | Confirm `~/.pi/agent/models.json` still symlinks into the repo, that it has the `llama-cpp` provider at `http://localhost:8080/v1`, and that its model ids match the profiles in `llamactl`. `pi --list-models \| grep llama-cpp` is the quick check. |
| Wired limit still raised with nothing running | `llamactl stop` resets it whenever it finds it non-zero. Confirm with `sysctl iogpu.wired_limit_mb`. |
| `command not found: pi` or `env: node: No such file or directory` | Pi is installed under nvm, which is initialized in `.zshrc` — interactive shells only. `llamactl` is non-interactive, so `.zshenv` → `.profile` rebuilds `PATH` without nvm's node bin. `llamactl` resolves the binary itself and prepends its directory so the `#!/usr/bin/env node` shebang also resolves. If it still fails, Pi is installed under a different Node version than the nvm default: `npm install -g @mariozechner/pi-coding-agent`. |
| Empty `content` in an API response | The coding profile is a reasoning model: it fills `reasoning_content` first, and a low `max_tokens` hits `finish_reason: "length"` before any final content is emitted. Raise `max_tokens`. Not a server fault. |

One thing llama.cpp reports at startup that is worth knowing about: upstream plans
to move the default server port from 8080 to 9931. This repo pins the port
explicitly, so that move will not break anything here, but
`~/.pi/agent/models.json` hardcodes 8080 too and would need to match if the
constant in `llamactl` ever changes.

## Sampler settings live in llamactl

`llamactl` passes each profile's published sampler settings to `llama-server`, from
the `SAMPLERS` table.

They belong at the server rather than in a client because `llama-server`'s own
defaults are **`temp 0.80, top_k 40, top_p 0.95, min_p 0.05`**, which are not the
recommended values for either model here. Anything that does not override them
inherits those numbers — Pi sessions included, not just evaluation runs.

| Profile | Model | Settings | Source |
|---|---|---|---|
| `chat` | Qwen3.5-9B | `temp 1.0, top_p 0.95, top_k 20, min_p 0.0, presence_penalty 1.5` | Unsloth, "thinking mode, general tasks" |
| `coding` | Gemma-4-12B | `temp 1.0, top_p 0.95, top_k 64, min_p 0.0` | Google, standardized config |

Note the `top_k` gap: Gemma's authors specify **64**, more than triple Qwen's 20. Until
August 2026 this repo ran a single shared setting of 20 across both, which truncated
Gemma's sampling distribution to under a third of its intended width on every coding
turn. It was not a deliberate choice — the value had been copied from a candidate model
that was later dropped.

`min_p` is set to `0.0` (disabled) for both. Google specifies three parameters for
Gemma, and leaving `llama-server`'s `0.05` in place would silently add a fourth sampler
its authors did not ask for.

Qwen publishes different values for precise coding (`temp 0.6`, `presence_penalty 0.0`).
The `chat` profile is not for that, so it uses the general-task numbers. If a Qwen-based
coding profile ever appears, it should not inherit these.

### Why not one shared setting for fair comparison

The evaluation harness originally pinned one sampler config across every model, on the
theory that identical decoding made the comparison fair. That reasoning is wrong. The
published values differ per model, so a single setting does not equalise anything — it
just runs somebody at the wrong numbers, and handicapping a model does not make a
comparison fairer, it makes it measure something else.

The useful question is "which model should I run day to day", and the honest way to
answer it is each model at its own recommended settings, which is also how `llamactl`
will actually run it. `scripts/llm-eval` therefore sends no sampler fields at all and
inherits whatever the server was started with.

## Vision is disabled by default

`llamactl` passes `--no-mmproj`, so the multimodal projector is never loaded.
Set `LLAMACTL_VISION=1` for a session that genuinely needs to send images.

Two reasons, and the second is the larger one.

**Memory.** The projector is dead weight for text work: 879MB on Qwen3.5-9B,
167MB on Gemma-4-12B, ~930MB on the 27B candidates. On a 24GB machine that is a
real fraction of the headroom.

**`--cache-reuse` actually works now.** `llama-server` logs

```
cache_reuse is not supported by multimodal, it will be disabled
```

and then ignores the `--cache-reuse 256` that `llamactl` passes. Both everyday
profiles are multimodal, so prompt-prefix reuse had never once been active
despite being in the command line since the beginning. Dropping the projector
turns it back on. This matters most for the coding profile, where every turn
re-sends a long and largely unchanged prefix.

That string is in the shipped binary, not inferred:

```bash
strings /opt/homebrew/Cellar/llama.cpp/*/lib/*.dylib | grep cache_reuse
```

The tradeoff is that image input silently stops working rather than failing
loudly — a model asked to read an image will simply not see it. That is
acceptable here because Pi is a text coding agent, but it is the reason the
escape hatch exists.
