# llm-eval

A harness for deciding whether a local GGUF model is worth running on this machine.

It exists because "does it fit?" is the question that actually gates model choice here,
and it is not answerable by reading a model card. Vendors publish VRAM figures that
assume a dedicated GPU and no operating system. On a 24GB unified-memory Mac the honest
test is empirical, and `docs/local-llm.md` records what happened the last time that was
skipped.

## Everything goes through llamactl

The harness does not launch `llama-server` itself. It calls `llamactl start`, reads the
PID from `llamactl pid`, and enumerates candidates with `llamactl profiles`. There is no
second copy of the model table, the port, the context size, or the server flags.

This is not tidiness. The first version of this script did launch the server directly,
and in doing so it silently omitted the raised `iogpu.wired_limit_mb` that `llamactl`
sets before every start. Per `docs/local-llm.md` that ceiling is the difference between
a hard OOM and a working load — so the harness would have confidently measured a
configuration that nothing on this machine actually runs. Any number here has to come
from the same code path as `llamactl chat`, or it is measuring fiction.

The consequence: to evaluate a model, add it to `PROFILES` in `llamactl`. Profiles
outside `EVERYDAY_PROFILES` are labelled `candidate` and are skipped unless you pass
`--all` or name them explicitly.

## What it measures

**Memory and fit.** Swap and wired memory are sampled at three points: before the server
starts, after the model loads, and after a ~8k-token prompt. The third sample is the one
that matters. A model that loads is not a model that fits — raising
`iogpu.wired_limit_mb` converts an OOM crash into slow swap-thrashing, and only a real
prompt distinguishes the two. Verdicts come from the swap delta, not from whether the
server came up.

**Tool-calling reliability.** Six cases against three tool definitions, driven through
the same OpenAI-compatible endpoint Pi uses. Checks that the right tool is selected, that
its arguments are valid JSON carrying the expected values, and — in two cases — that the
model correctly declines to call anything. A model that cannot do this is unusable as the
`coding` profile no matter how it reads.

**Task quality.** Eight prompts across coding, reasoning, summarization,
instruction-following, and calibration. Two are auto-scored because they have objectively
checkable outputs (strict JSON; exactly three bullets with no preamble). The other six
are saved verbatim for side-by-side reading. They are deliberately *not* given a numeric
score — an eight-prompt rubric cannot support one honestly, and a fabricated number is
worse than an absent one. Each case carries a `looking_for` note describing the failure
mode it probes.

## Usage

```bash
llamactl stop                          # required: a resident model corrupts the baseline
./run-eval.py --list                   # profiles, from llamactl
./run-eval.py                          # everyday profiles only
./run-eval.py --all                    # everyday + candidates
./run-eval.py chat                     # an explicit subset
```

The script refuses to start if `llamactl pid` reports a running server. That is not
politeness about the port — a resident model makes every memory number meaningless, so
the run is worth aborting.

Results land in `~/.cache/llm-eval/<timestamp>/`:

| File | Contents |
|---|---|
| `report.html` | **Start here.** Side-by-side answers, plus every table |
| `summary.md` | The three tables — fit, tool-calling, quality |
| `results.json` | Everything, including full model outputs for the unscored prompts |

`report.html` is self-contained, opens straight off disk, and follows the system light or
dark theme. It puts every model's answer to the same prompt next to each other with the
`looking_for` note above them, which is the only way the six ungraded prompts inform
anything. It also flags `NO ANSWER` where a model spent its whole budget on reasoning, so
a budget artifact cannot be mistaken for a capability result.

Regenerate it for any past run without re-running the models:

```bash
./report.py                                     # newest run
./report.py ~/.cache/llm-eval/20260820T201652Z  # a specific one
```

## What this harness does not tell you

It is a fitness and smoke test. It answers *can I run this without wrecking the machine,
and does it call tools correctly*. It does not answer *is this model good*:

  * **Eight single-turn prompts is not a benchmark.** It catches confabulation and
    format-instruction failures. It will not tell you which model is better at your work.
  * **Six of the eight are ungraded by design.** A rubric that small cannot support a
    number honestly, so a human reads them or nobody does. That is what `report.html`
    is for.
  * **Nothing measures multi-turn behaviour.** Every case is one request. Real sessions
    are long conversations where context handling and instruction drift dominate.
  * **Nothing measures agentic loops.** Tool-calling is tested one call at a time.
    Whether a model chains calls, recovers from a tool error, or knows when to stop is
    untested — and that is most of what `llamactl code` actually does.

`results.json` is rewritten after every profile, so a crash on a 27B does not discard the
baselines collected before it. `llamactl logs` is the place to look when a start fails;
the tail of that log is also captured into the results.

## warm-cache.sh

The one deliberate exception to the llamactl rule. It starts `llama-server` directly with
`-ngl 0`, which keeps every layer on the CPU, so weights download without Metal ever
being asked for memory. `llamactl` has no way to express "fetch but do not load", and
coupling a 16GB download to a risky load makes a network failure and an OOM look alike.

Nothing it does is measured — it only warms `~/.cache/huggingface/hub`. Run it before a
first evaluation of a new model, or skip it and let `llamactl start` download on demand.

## Notes on the method

Context comes from the profile, so it is whatever `llamactl` runs. Both current profiles
and both 27B candidates use 16384; memory figures are only comparable while that holds.

Server flags are `llamactl`'s, including `--parallel 1` (the default of 4 gives each slot
its own copy of the `-c` window and silently quadruples KV memory), flash attention, and
a q8_0 KV cache.

Multimodal projectors are disabled, because `llamactl` now passes `--no-mmproj` for every
profile. The evaluation measures what actually runs. Two consequences for reading the
numbers:

  * Memory figures exclude the vision tower — 879MB on Qwen3.5-9B, ~930MB on the 27B
    candidates. That is real headroom the 27B gets to keep, not a benchmark that flatters
    it, because everyday sessions run the same way.
  * `--cache-reuse 256` is genuinely active. `llama-server` disables it for multimodal
    models, so the measured throughput is not comparable to any earlier run made with a
    projector loaded.

If vision capability ever becomes part of the decision, `LLAMACTL_VISION=1` restores the
projector — and the memory and throughput numbers both move.

Sampler settings are **not** sent with requests. Each profile's values live in llamactl's
`SAMPLERS` table and are applied as `llama-server` defaults, so the harness inherits
exactly what a real session gets.

This reverses an earlier decision. The harness used to pin one sampler config across every
model, on the theory that identical decoding made the comparison fair. It does not: the
published values differ per model — Qwen3.5-9B wants `top_k 20`, Gemma-4 wants `top_k 64`
— so one setting does not equalise anything, it just runs somebody at the wrong numbers.
The right comparison for "which model should I run day to day" is each model at its own
recommended settings. The sampler actually used is recorded per profile in `summary.md`
and `results.json`.

`max_tokens` is 2048. Reasoning models spend their first several hundred tokens in
`reasoning_content`, and a small budget returns empty `content` with
`finish_reason: "length"` — which looks like a model failure but is a configuration one.

Memory numbers are only as clean as the machine. Run from a fresh boot with apps closed;
`vm.swapusage` should read near zero before you start, or the swap-delta verdicts are
measuring the rest of your session rather than the model.

## Adding a model

Add it to `PROFILES` in `personal/.local/bin/llamactl`, outside `EVERYDAY_PROFILES` until
it has earned promotion. Verify the quant tag resolves to a real file first — the tags do
not always match the names on the model card, and Unsloth in particular prefixes most of
theirs with `UD-`:

```bash
curl -s https://huggingface.co/api/models/<repo> \
  | python3 -c "import json,sys; [print(s['rfilename']) for s in json.load(sys.stdin)['siblings'] if s['rfilename'].endswith('.gguf')]"
```
