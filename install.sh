#!/usr/bin/env bash

set -e

PROJECT_DIR="/opt"
LLAMA_DIR="/opt/llama.cpp"
MODEL_DIR="/opt/models"

echo "=========================================="
echo "   Cloud Shell Local AI Installer"
echo "=========================================="
echo

echo "[1/5] Checking system..."

if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

if ! command -v cmake >/dev/null 2>&1; then
    echo "Installing cmake..."
    sudo apt-get update
    sudo apt-get install -y cmake build-essential
fi

echo "[2/5] Creating directories..."

sudo mkdir -p "$MODEL_DIR"

echo "[3/5] Installing llama.cpp..."

if [ ! -d "$LLAMA_DIR/.git" ]; then
    sudo git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
else
    echo "llama.cpp already exists. Skipping clone."
fi

echo "[4/5] Building llama.cpp..."

cd "$LLAMA_DIR"

sudo cmake -B build
sudo cmake --build build --config Release -j2

echo "[5/5] Checking installation..."

if [ -x "$LLAMA_DIR/build/bin/llama-server" ]; then
    echo
    echo "llama.cpp installation successful!"
    echo
    "$LLAMA_DIR/build/bin/llama-server" --version || true
else
    echo
    echo "ERROR: llama-server was not built."
    exit 1
fi

echo
echo "=========================================="
echo " Installation complete"
echo "=========================================="
