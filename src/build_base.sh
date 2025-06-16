#!/bin/bash
set -e

IMAGE_NAME="baxter-ros2-jazzy"
DOCKERFILE="Dockerfile.base"

echo "[*] Building Docker image: $IMAGE_NAME from $DOCKERFILE"
docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" .
