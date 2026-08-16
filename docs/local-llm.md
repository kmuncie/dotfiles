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
| `scripts/llamactl-wired-limit.sudoers` | Scoped sudoers drop-in permitting exactly one privileged command. Not stowed — installed once, by hand, into `/etc/sudoers.d/`. |
| `personal/.pi/agent/models.json` | Points Pi at `http://localhost:8080/v1` as provider `llama-cpp`, and lists the models from both profiles. Stowed to `~/.pi/agent/models.json`. |

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
llamactl stop                  # when done — frees the model, resets the ceiling
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
| Model | Qwen3.5 9B | Gemma 4 12B |
| Tools | Off (`--no-tools`) — cannot touch files | Full read/write/edit/bash |
| For | Questions, drafting, thinking out loud | Actual work on a codebase |

Switching between them restarts the server with the other model; only one runs
at a time, because two would not fit in memory together.

### There is no web UI

This Homebrew build of `llama-server` does not serve one — the root path returns
415. The Pi TUI above is the interface. To talk to the server directly, use the
OpenAI-compatible API:

```bash
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"unsloth/Qwen3.5-9B-GGUF:Q4_K_M",
       "messages":[{"role":"user","content":"hello"}],
       "max_tokens":512}' | jq -r '.choices[0].message.content'
```

Keep `max_tokens` generous — both models emit reasoning tokens first, so a small
budget returns empty `content`. See Troubleshooting.

## Server management

For when you want the server without a client attached — another editor, a
script, or the `curl` call above:

```bash
llamactl start coding     # or: chat
llamactl status           # pid, profile, endpoint, wired limit, swap usage
llamactl logs             # follow the server log
llamactl restart coding
llamactl stop             # kills the server AND resets the wired limit
```

## One-time setup: the scoped sudoers rule

`llamactl` raises a kernel tunable, which needs root. Rather than general
passwordless sudo, a drop-in file permits exactly one command:

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

Until the drop-in is installed, `llamactl start` fails fast with instructions
instead of hanging on a password prompt. To run without touching the wired limit
at all (fine for smaller models):

```bash
LLAMACTL_SKIP_WIRED_LIMIT=1 llamactl start chat
```

## What was learned the hard way

### Model size: the honest ceiling here is ~12-14B dense

Dense models in the 27-30B class (~17GB of Q4_K_M weights) reliably hit Metal
OOM errors or swap-thrash on this 24GB machine, **even though vendors market
them as fitting a 24GB machine.** The comfortable ceiling for dense models here
is closer to 12-14B (~7-9GB of weights), which is what both `llamactl` profiles
use.

Verify a model actually fits rather than trusting that it loaded: run
`llamactl status` after loading *and* after a real prompt, and check that
`vm.swapusage` stays flat. A model that loads but swaps is not a model that
fits.

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

### The Metal wired-memory ceiling

macOS's default `iogpu.wired_limit_mb` is unset (`0`), which falls back to an
internal heuristic around 75% of total RAM. That default was contributing to at
least one OOM failure; raising it explicitly turned a hard crash into a working
load.

`llamactl start` sets it to **21000** MB (of 24576 total) before launching the
server, and `llamactl stop` resets it to `0`. The wider ceiling therefore exists
only while a model is actually loaded.

The value is left as an explicit constant on purpose. It was validated on this
specific machine and this macOS version — it is not auto-detected, and it should
not be. If the hardware changes, change it consciously.

## Downsides of raising the wired limit

These apply to the on-demand approach below and *more strongly* to the permanent
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
| `start` fails with a sudo error | The sudoers drop-in is not installed, or the `sysctl` path drifted. Re-run `which sysctl` and compare to the rule. |
| Server never comes up | `llamactl logs`. First run of a profile downloads several GB; the health check waits 120s. |
| Loads, then everything crawls | `llamactl status` — if `vm.swapusage` is climbing, the model is too big. Use a smaller one; the wired limit will not rescue it. |
| Pi cannot reach the model | Confirm `~/.pi/agent/models.json` still symlinks into the repo, that it has the `llama-cpp` provider at `http://localhost:8080/v1`, and that its model ids match the profiles in `llamactl`. `pi --list-models \| grep llama-cpp` is the quick check. |
| Wired limit still raised with nothing running | `llamactl stop` resets it to `0`. Confirm with `sysctl iogpu.wired_limit_mb`. |
| `command not found: pi` or `env: node: No such file or directory` | Pi is installed under nvm, which is initialized in `.zshrc` — interactive shells only. `llamactl` is non-interactive, so `.zshenv` → `.profile` rebuilds `PATH` without nvm's node bin. `llamactl` resolves the binary itself and prepends its directory so the `#!/usr/bin/env node` shebang also resolves. If it still fails, Pi is installed under a different Node version than the nvm default: `npm install -g @mariozechner/pi-coding-agent`. |
| Empty `content` in an API response | The coding profile is a reasoning model: it fills `reasoning_content` first, and a low `max_tokens` hits `finish_reason: "length"` before any final content is emitted. Raise `max_tokens`. Not a server fault. |

Two things llama.cpp reports at startup that are worth knowing about:
`--cache-reuse` is silently disabled for multimodal models (the coding profile is
one), and upstream plans to move the default server port from 8080 to 9931. This
repo pins the port explicitly, so that move will not break anything here, but
`~/.pi/agent/models.json` hardcodes 8080 too and would need to match if the
constant in `llamactl` ever changes.
