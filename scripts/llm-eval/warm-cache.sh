#!/usr/bin/env zsh
# Pre-download GGUF weights into llama.cpp's cache without loading them onto the GPU.
#
# This is the ONE place in this directory that invokes llama-server directly instead of
# going through llamactl, and the exception is deliberate: llamactl has no way to say
# "fetch the weights but do not load them", because every real use of it wants a loaded
# model. Downloading is the one operation where that is exactly wrong.
#
# `llama-server -hf` downloads on first start, which couples a multi-GB download to a
# model load. That is what we do NOT want while measuring whether a model fits: a network
# failure and an OOM would look alike, and the 27B loads are the risky ones.
#
# So: start each model with -ngl 0 (nothing offloaded to Metal) and a tiny context, wait
# for the server to answer, then kill it. The weights land in the cache, the GPU is never
# asked for anything, and the real fit test later starts from a warm cache.
#
# Nothing here is measured. Ports and flags below are throwaway and intentionally do not
# match llamactl's — this must never be mistaken for an evaluation run.

set -uo pipefail

# Keep this in step with PROFILES in llamactl. Anything listed here gets downloaded
# in full, so a stale entry costs real disk and bandwidth — the Qwen3.8-27B candidates
# lived here briefly and were 28GB between them.
MODELS=(
    "unsloth/Qwen3.5-9B-GGUF:Q4_K_M"
    "bartowski/gemma-4-12B-it-GGUF:Q4_K_M"
    "unsloth/gemma-4-12B-it-qat-GGUF:UD-Q4_K_XL"
    "unsloth/Qwen3.5-9B-MTP-GGUF:Q4_K_M"
)

PORT=18080
LOGDIR="${TMPDIR:-/tmp}/llm-eval-warm"
mkdir -p "$LOGDIR"

for model in "${MODELS[@]}"; do
    echo "=== warming $model ==="
    log="$LOGDIR/$(echo "$model" | tr '/:' '__').log"

    # -ngl 0 keeps every layer on the CPU, so this cannot OOM Metal no matter how big
    # the weights are. --no-mmproj skips the vision projector; the eval is text-only.
    llama-server -hf "$model" \
        --host 127.0.0.1 --port "$PORT" \
        --parallel 1 -ngl 0 -c 256 --no-mmproj \
        > "$log" 2>&1 &
    pid=$!

    # Generous ceiling: the 27B quants are 14-16GB. Bail early if the process dies.
    for i in {1..5400}; do
        if curl -s "http://127.0.0.1:$PORT/v1/models" > /dev/null 2>&1; then
            echo "  cached and loadable: $model"
            break
        fi
        if ! kill -0 "$pid" 2> /dev/null; then
            echo "  FAILED: $model — see $log" >&2
            break
        fi
        sleep 1
    done

    kill "$pid" 2> /dev/null || true
    wait "$pid" 2> /dev/null || true
    sleep 2
done

echo "=== warm-cache done ==="
