#!/bin/bash
set -e

IMAGE_NAME="baxter-ros2-dev"
DOCKERFILE="Dockerfile.dev"

echo "[*] Building Docker image: $IMAGE_NAME from $DOCKERFILE"
docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" .
