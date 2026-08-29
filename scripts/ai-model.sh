#!/usr/bin/env bash

set -e

LLAMA_SERVER="/opt/llama.cpp/build/bin/llama-server"
MODEL_DIR="/opt/models"

TEMP="0.1"
TOP_K="40"
MIN_P="0.05"
SEED="42"

# ──────────────────────────────────────────
# Find installed GGUF models
# ──────────────────────────────────────────

get_models() {
    find "$MODEL_DIR" \
        -type f \
        -name "*.gguf" \
        -print 2>/dev/null | sort
}

# ──────────────────────────────────────────
# Stop existing llama-server
# ──────────────────────────────────────────

stop_server() {
    if pgrep -f "llama-server" >/dev/null 2>&1; then
        echo
        echo "Stopping existing llama-server..."
        pkill -f "llama-server" || true
        sleep 2
    fi
}

# ──────────────────────────────────────────
# Model menu
# ──────────────────────────────────────────

mapfile -t MODELS < <(get_models)

if [ "${#MODELS[@]}" -eq 0 ]; then
    echo
    echo "No GGUF models found."
    echo
    echo "Please run ./install.sh first."
    exit 1
fi

echo
echo "╔══════════════════════════════════════════╗"
echo "║             AI MODEL MENU                ║"
echo "╠══════════════════════════════════════════╣"

for i in "${!MODELS[@]}"; do
    MODEL_PATH="${MODELS[$i]}"
    MODEL_NAME="$(basename "$MODEL_PATH" .gguf)"

    printf "║ %d. %-36s ║\n" \
        "$((i + 1))" \
        "$MODEL_NAME"
done

echo "╠══════════════════════════════════════════╣"
echo "║ 0. Exit                                  ║"
echo "╚══════════════════════════════════════════╝"
echo

read -rp "Select model: " MODEL_CHOICE

if [ "$MODEL_CHOICE" = "0" ]; then
    exit 0
fi

if ! [[ "$MODEL_CHOICE" =~ ^[0-9]+$ ]] ||
   [ "$MODEL_CHOICE" -lt 1 ] ||
   [ "$MODEL_CHOICE" -gt "${#MODELS[@]}" ]; then

    echo "Invalid model selection."
    exit 1
fi

MODEL="${MODELS[$((MODEL_CHOICE - 1))]}"

# ──────────────────────────────────────────
# Context menu
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║             CONTEXT SIZE                 ║"
echo "╠══════════════════════════════════════════╣"
echo "║ 1. 4096                                  ║"
echo "║ 2. 8192                                  ║"
echo "║ 3. 16384                                 ║"
echo "║ 4. 32768                                 ║"
echo "╚══════════════════════════════════════════╝"
echo

read -rp "Select context size: " CONTEXT_CHOICE

case "$CONTEXT_CHOICE" in
    1)
        CONTEXT=4096
        ;;
    2)
        CONTEXT=8192
        ;;
    3)
        CONTEXT=16384
        ;;
    4)
        CONTEXT=32768
        ;;
    *)
        echo "Invalid context selection."
        exit 1
        ;;
esac

# ──────────────────────────────────────────
# Display configuration
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║              AI CONFIGURATION            ║"
echo "╠══════════════════════════════════════════╣"
printf "║ Model: %-34s ║\n" "$(basename "$MODEL")"
printf "║ Context: %-32s ║\n" "$CONTEXT"
printf "║ Temperature: %-28s ║\n" "$TEMP"
printf "║ Top-K: %-34s ║\n" "$TOP_K"
printf "║ Min-P: %-34s ║\n" "$MIN_P"
printf "║ Seed: %-35s ║\n" "$SEED"
echo "╚══════════════════════════════════════════╝"
echo

# ──────────────────────────────────────────
# Start llama-server
# ──────────────────────────────────────────

if [ ! -x "$LLAMA_SERVER" ]; then
    echo "ERROR: llama-server not found:"
    echo "$LLAMA_SERVER"
    echo
    echo "Run ./install.sh first."
    exit 1
fi

stop_server

echo "Starting AI server..."
echo
echo "Web UI:"
echo "http://localhost:8080"
echo
echo "Model:"
echo "$MODEL"
echo
echo "Press Ctrl+C to stop the server."
echo

exec "$LLAMA_SERVER" \
    -m "$MODEL" \
    -c "$CONTEXT" \
    -t 2 \
    -ngl 0 \
    --host 0.0.0.0 \
    --port 8080 \
    --temp "$TEMP" \
    --top-k "$TOP_K" \
    --min-p "$MIN_P" \
    --seed "$SEED"
