#!/usr/bin/env bash

set -e

LLAMA_DIR="/opt/llama.cpp"
MODEL_DIR="/opt/models"
CONFIG_FILE="$(dirname "$0")/config/models.conf"

echo
echo "╔══════════════════════════════════════════╗"
echo "║       CLOUD SHELL LOCAL AI INSTALLER    ║"
echo "╚══════════════════════════════════════════╝"
echo

# ──────────────────────────────────────────
# Check configuration
# ──────────────────────────────────────────

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config/models.conf not found."
    exit 1
fi

# ──────────────────────────────────────────
# Install required packages
# ──────────────────────────────────────────

echo "[1/4] Checking required packages..."

if ! command -v git >/dev/null 2>&1 || \
   ! command -v cmake >/dev/null 2>&1; then

    echo "Installing build dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        git \
        cmake \
        build-essential \
        curl
fi

# ──────────────────────────────────────────
# Create directories
# ──────────────────────────────────────────

echo
echo "[2/4] Creating model directory..."

sudo mkdir -p "$MODEL_DIR"
sudo chmod 777 "$MODEL_DIR"

# ──────────────────────────────────────────
# Install llama.cpp
# ──────────────────────────────────────────

echo
echo "[3/4] Checking llama.cpp..."

if [ ! -d "$LLAMA_DIR/.git" ]; then

    echo "Cloning llama.cpp..."

    sudo git clone \
        https://github.com/ggml-org/llama.cpp.git \
        "$LLAMA_DIR"

else

    echo "llama.cpp already installed."
fi

echo
echo "Building llama.cpp..."

cd "$LLAMA_DIR"

if [ ! -f "$LLAMA_DIR/build/bin/llama-server" ]; then

    sudo cmake -B build

    sudo cmake \
        --build build \
        --config Release \
        -j2

else

    echo "llama-server already exists."
fi

# ──────────────────────────────────────────
# Model menu
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║             MODEL INSTALLER              ║"
echo "╠══════════════════════════════════════════╣"

echo "║ 1. Qwen2.5-Coder-7B Abliterated          ║"
echo "║ 2. Qwen3.5-4B Super Coder                ║"
echo "║ 3. Gemma 4 E4B-it                        ║"
echo "║ 4. Gemma 4 E2B-it                        ║"
echo "║ 5. Qwen2.5-Coder-3B                      ║"
echo "║ 6. Install ALL models                    ║"
echo "║ 0. Exit                                  ║"
echo "╚══════════════════════════════════════════╝"
echo

read -rp "Select model: " MODEL_CHOICE

# ──────────────────────────────────────────
# Model installer
# ──────────────────────────────────────────

install_model() {

    local MODEL_NAME="$1"
    local REPO="$2"
    local FILE="$3"
    local DIR="$4"

    local TARGET_DIR="$MODEL_DIR/$DIR"
    local TARGET_FILE="$TARGET_DIR/$FILE"

    echo
    echo "=========================================="
    echo "Installing: $MODEL_NAME"
    echo "=========================================="

    sudo mkdir -p "$TARGET_DIR"
    sudo chmod 777 "$TARGET_DIR"

    if [ -f "$TARGET_FILE" ]; then

        echo
        echo "Model already exists:"
        echo "$TARGET_FILE"
        echo
        echo "Skipping download."

        return
    fi

    echo
    echo "Downloading:"
    echo "$FILE"
    echo

    if ! command -v hf >/dev/null 2>&1; then

        echo "Installing Hugging Face CLI..."

        python3 -m pip install --user -U huggingface_hub

    fi

    hf download "$REPO" \
        "$FILE" \
        --local-dir "$TARGET_DIR"

    echo
    echo "✓ $MODEL_NAME installed successfully."
}

# ──────────────────────────────────────────
# Read model configuration
# ──────────────────────────────────────────

get_model() {

    local NUMBER="$1"

    sed -n "${NUMBER}p" "$CONFIG_FILE"
}

# ──────────────────────────────────────────
# Execute selection
# ──────────────────────────────────────────

case "$MODEL_CHOICE" in

    1)
        IFS='|' read -r NAME REPO FILE DIR <<< "$(get_model 1)"

        install_model \
            "$NAME" \
            "$REPO" \
            "$FILE" \
            "$DIR"
        ;;

    2)
        IFS='|' read -r NAME REPO FILE DIR <<< "$(get_model 2)"

        install_model \
            "$NAME" \
            "$REPO" \
            "$FILE" \
            "$DIR"
        ;;

    3)
        IFS='|' read -r NAME REPO FILE DIR <<< "$(get_model 3)"

        install_model \
            "$NAME" \
            "$REPO" \
            "$FILE" \
            "$DIR"
        ;;

    4)
        IFS='|' read -r NAME REPO FILE DIR <<< "$(get_model 4)"

        install_model \
            "$NAME" \
            "$REPO" \
            "$FILE" \
            "$DIR"
        ;;

    5)
        IFS='|' read -r NAME REPO FILE DIR <<< "$(get_model 5)"

        install_model \
            "$NAME" \
            "$REPO" \
            "$FILE" \
            "$DIR"
        ;;

    6)

        echo
        echo "Installing all models..."
        echo

        while IFS='|' read -r NAME REPO FILE DIR
        do

            [ -z "$NAME" ] && continue
            [[ "$NAME" =~ ^# ]] && continue

            install_model \
                "$NAME" \
                "$REPO" \
                "$FILE" \
                "$DIR"

        done < "$CONFIG_FILE"

        ;;

    0)

        echo "Exiting."
        exit 0
        ;;

    *)

        echo
        echo "Invalid selection."
        exit 1
        ;;

esac

# ──────────────────────────────────────────
# Final status
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║          INSTALLATION COMPLETE           ║"
echo "╚══════════════════════════════════════════╝"
echo

echo "llama-server:"
echo "$LLAMA_DIR/build/bin/llama-server"

echo
echo "Models:"
find "$MODEL_DIR" \
    -type f \
    -name "*.gguf" \
    -exec ls -lh {} \;

echo
echo "Next step:"
echo "Run the ai-model command."
echo
