#!/bin/bash
set -e

echo "[*] Starting full build process"

./build_base.sh
./build_dev.sh

echo "[*] All images built successfully"
