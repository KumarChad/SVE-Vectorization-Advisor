#!/usr/bin/env bash
# One-shot setup + build + test + benchmark on Ubuntu 24.04 (or WSL Ubuntu 24.04).
set -euo pipefail
cd "$(dirname "$0")"

sudo apt-get update
sudo apt-get install -y clang llvm-18-dev cmake qemu-user \
    gcc-aarch64-linux-gnu libc6-dev-arm64-cross python3-pip
pip install --break-system-packages lit

cmake -S . -B build -DLLVM_DIR="$(llvm-config-18 --cmakedir)" -DCMAKE_CXX_COMPILER=clang++
cmake --build build

lit -v test/
python3 bench/run_bench.py
