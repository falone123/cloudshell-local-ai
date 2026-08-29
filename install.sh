#!/usr/bin/env bash

set -e

# ──────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────

LLAMA_DIR="/opt/llama.cpp"
MODEL_DIR="/opt/models"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/models.conf"
AI_MODEL_SCRIPT="$SCRIPT_DIR/scripts/ai-model.sh"
AI_MODEL_COMMAND="/usr/local/bin/ai-model"

# ──────────────────────────────────────────
# Header
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║       CLOUD SHELL LOCAL AI INSTALLER    ║"
echo "╚══════════════════════════════════════════╝"
echo

# ──────────────────────────────────────────
# Check configuration files
# ──────────────────────────────────────────

echo "[1/6] Checking project files..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo
    echo "ERROR: config/models.conf not found."
    echo
    echo "Expected:"
    echo "$CONFIG_FILE"
    exit 1
fi

if [ ! -f "$AI_MODEL_SCRIPT" ]; then
    echo
    echo "ERROR: scripts/ai-model.sh not found."
    echo
    echo "Expected:"
    echo "$AI_MODEL_SCRIPT"
    exit 1
fi

echo "✓ Configuration files found."

# ──────────────────────────────────────────
# Check required packages
# ──────────────────────────────────────────

echo
echo "[2/6] Checking required packages..."

NEED_APT=false

if ! command -v git >/dev/null 2>&1; then
    NEED_APT=true
fi

if ! command -v cmake >/dev/null 2>&1; then
    NEED_APT=true
fi

if ! command -v g++ >/dev/null 2>&1; then
    NEED_APT=true
fi

if [ "$NEED_APT" = true ]; then

    echo "Installing build dependencies..."

    sudo apt-get update

    sudo apt-get install -y \
        git \
        cmake \
        build-essential \
        curl \
        python3 \
        python3-pip

else

    echo "✓ Required packages already installed."

fi

# ──────────────────────────────────────────
# Create directories
# ──────────────────────────────────────────

echo
echo "[3/6] Creating directories..."

sudo mkdir -p "$MODEL_DIR"

sudo chmod 777 "$MODEL_DIR"

echo "✓ Model directory:"
echo "  $MODEL_DIR"

# ──────────────────────────────────────────
# Install llama.cpp
# ──────────────────────────────────────────

echo
echo "[4/6] Checking llama.cpp..."

if [ ! -d "$LLAMA_DIR/.git" ]; then

    echo
    echo "llama.cpp not found."
    echo "Cloning llama.cpp..."

    sudo git clone \
        https://github.com/ggml-org/llama.cpp.git \
        "$LLAMA_DIR"

else

    echo
    echo "✓ llama.cpp already exists."
    echo "$LLAMA_DIR"

fi

# ──────────────────────────────────────────
# Build llama.cpp
# ──────────────────────────────────────────

echo
echo "Building llama.cpp..."

if [ ! -x "$LLAMA_DIR/build/bin/llama-server" ]; then

    echo "Configuring CMake..."

    sudo cmake \
        -B "$LLAMA_DIR/build"

    echo
    echo "Compiling llama.cpp..."

    sudo cmake \
        --build "$LLAMA_DIR/build" \
        --config Release \
        -j2

else

    echo
    echo "✓ llama-server already exists."
    echo "Skipping full build."

fi

# ──────────────────────────────────────────
# Verify llama-server
# ──────────────────────────────────────────

if [ ! -x "$LLAMA_DIR/build/bin/llama-server" ]; then

    echo
    echo "ERROR: llama-server was not built successfully."
    echo
    echo "Expected:"
    echo "$LLAMA_DIR/build/bin/llama-server"

    exit 1

fi

echo
echo "✓ llama-server ready."

# ──────────────────────────────────────────
# Install Hugging Face CLI
# ──────────────────────────────────────────

echo
echo "[5/6] Checking Hugging Face CLI..."

if command -v hf >/dev/null 2>&1; then

    echo "✓ hf command already installed."

else

    echo "Installing Hugging Face Hub..."

    python3 -m pip install \
        --user \
        -U \
        huggingface_hub

    export PATH="$HOME/.local/bin:$PATH"

fi

if ! command -v hf >/dev/null 2>&1; then

    echo
    echo "ERROR: Hugging Face CLI (hf) is not available."
    echo
    echo "Try:"
    echo "python3 -m pip install --user -U huggingface_hub"

    exit 1

fi

echo "✓ hf command ready."

# ──────────────────────────────────────────
# Model installer function
# ──────────────────────────────────────────

install_model() {

    local MODEL_NAME="$1"
    local REPO="$2"
    local FILE="$3"
    local DIR="$4"

    local TARGET_DIR="$MODEL_DIR/$DIR"
    local TARGET_FILE="$TARGET_DIR/$FILE"

    echo
    echo "╔══════════════════════════════════════════╗"
    echo "║             MODEL INSTALL                ║"
    echo "╚══════════════════════════════════════════╝"

    echo
    echo "Model:"
    echo "$MODEL_NAME"

    echo
    echo "Repository:"
    echo "$REPO"

    echo
    echo "File:"
    echo "$FILE"

    echo
    echo "Install directory:"
    echo "$TARGET_DIR"

    sudo mkdir -p "$TARGET_DIR"

    sudo chmod 777 "$TARGET_DIR"

    # ──────────────────────────────────────
    # Check existing model
    # ──────────────────────────────────────

    if [ -f "$TARGET_FILE" ]; then

        echo
        echo "✓ Model already installed."
        echo
        echo "$TARGET_FILE"
        echo
        echo "Skipping download."

        return 0

    fi

    # ──────────────────────────────────────
    # Download model
    # ──────────────────────────────────────

    echo
    echo "Downloading model..."
    echo

    hf download \
        "$REPO" \
        "$FILE" \
        --local-dir "$TARGET_DIR"

    # ──────────────────────────────────────
    # Verify download
    # ──────────────────────────────────────

    if [ ! -f "$TARGET_FILE" ]; then

        echo
        echo "ERROR: Model download failed."
        echo
        echo "Expected file:"
        echo "$TARGET_FILE"

        return 1

    fi

    echo
    echo "✓ Model installed successfully."

    echo
    ls -lh "$TARGET_FILE"
}

# ──────────────────────────────────────────
# Model menu
# ──────────────────────────────────────────

echo
echo "[6/6] Model installation"
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
# Read model configuration
# ──────────────────────────────────────────

get_model() {

    local NUMBER="$1"

    sed -n "${NUMBER}p" "$CONFIG_FILE"

}

# ──────────────────────────────────────────
# Install selected model
# ──────────────────────────────────────────

install_selected_model() {

    local NUMBER="$1"

    local LINE

    LINE="$(get_model "$NUMBER")"

    if [ -z "$LINE" ]; then

        echo
        echo "ERROR: Model configuration not found."
        echo "Line: $NUMBER"

        exit 1

    fi

    IFS='|' read -r NAME REPO FILE DIR <<< "$LINE"

    install_model \
        "$NAME" \
        "$REPO" \
        "$FILE" \
        "$DIR"
}

# ──────────────────────────────────────────
# Menu selection
# ──────────────────────────────────────────

case "$MODEL_CHOICE" in

    1)

        install_selected_model 1

        ;;

    2)

        install_selected_model 2

        ;;

    3)

        install_selected_model 3

        ;;

    4)

        install_selected_model 4

        ;;

    5)

        install_selected_model 5

        ;;

    6)

        echo
        echo "Installing ALL models..."
        echo

        while IFS='|' read -r NAME REPO FILE DIR
        do

            # Skip empty lines
            [ -z "$NAME" ] && continue

            # Skip comments
            [[ "$NAME" =~ ^# ]] && continue

            install_model \
                "$NAME" \
                "$REPO" \
                "$FILE" \
                "$DIR"

        done < "$CONFIG_FILE"

        ;;

    0)

        echo
        echo "Installation cancelled."
        exit 0

        ;;

    *)

        echo
        echo "ERROR: Invalid selection."
        echo
        echo "Please choose 0-6."

        exit 1

        ;;

esac

# ──────────────────────────────────────────
# Install ai-model command
# ──────────────────────────────────────────

echo
echo "Installing ai-model command..."

sudo cp \
    "$AI_MODEL_SCRIPT" \
    "$AI_MODEL_COMMAND"

sudo chmod +x \
    "$AI_MODEL_COMMAND"

# ──────────────────────────────────────────
# Verify ai-model command
# ──────────────────────────────────────────

if [ ! -x "$AI_MODEL_COMMAND" ]; then

    echo
    echo "ERROR: Failed to install ai-model command."
    exit 1

fi

echo
echo "✓ ai-model command installed."
echo
echo "Location:"
echo "$AI_MODEL_COMMAND"

# ──────────────────────────────────────────
# Show installed models
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║          INSTALLED GGUF MODELS           ║"
echo "╚══════════════════════════════════════════╝"
echo

if find "$MODEL_DIR" \
    -type f \
    -name "*.gguf" \
    -print -quit 2>/dev/null | grep -q .
then

    find "$MODEL_DIR" \
        -type f \
        -name "*.gguf" \
        -exec ls -lh {} \;

else

    echo "No GGUF models installed."

fi

# ──────────────────────────────────────────
# Final message
# ──────────────────────────────────────────

echo
echo "╔══════════════════════════════════════════╗"
echo "║          INSTALLATION COMPLETE           ║"
echo "╚══════════════════════════════════════════╝"
echo

echo "llama-server:"
echo "$LLAMA_DIR/build/bin/llama-server"

echo
echo "ai-model:"
echo "$AI_MODEL_COMMAND"

echo
echo "To start the AI Web UI, run:"
echo
echo "    ai-model"
echo

echo "Installation finished successfully."
echo
