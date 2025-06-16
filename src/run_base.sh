#!/bin/bash
set -e

IMAGE_NAME="baxter-ros2-jazzy"
CONTAINER_NAME="baxter-ros1-jazzy-container"

docker run -it --rm --name "$CONTAINER_NAME" "$IMAGE_NAME"
