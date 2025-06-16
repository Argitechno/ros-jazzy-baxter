#!/bin/bash
set -e

IMAGE_NAME="baxter-ros2-dev"
CONTAINER_NAME="baxter-ros2-dev-container"

# Script directory is ros-noetic-baxter folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WS_PATH="$SCRIPT_DIR/../baxter_ws"   # Default workspace path (can be overridden by user)
BAXTER_SH_SRC="$SCRIPT_DIR/baxter.sh"     # Path to baxter.sh script on host

# Use workspace path from first argument or default
HOST_WS_PATH="${1:-$DEFAULT_WS_PATH}"

# Extract just the folder name of the workspace path for container mapping
WS_BASENAME="$(basename "$HOST_WS_PATH")"

# Use ubuntu's home directory in the container
CONTAINER_WS_PATH="/home/ubuntu/$WS_BASENAME"

echo "[*] Using workspace path on host: $HOST_WS_PATH"
echo "[*] Mounting workspace in container as: $CONTAINER_WS_PATH"

# Ensure the workspace directory exists and is owned by the current user
if [ ! -d "$HOST_WS_PATH" ]; then
    mkdir -p "$HOST_WS_PATH"
    chown "$(id -u):$(id -g)" "$HOST_WS_PATH"
fi

# Allow Docker containers to access X server for GUI applications
xhost +local:docker

docker run -it --rm \
    --network host \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="${HOME}/.Xauthority:/home/ubuntu/.Xauthority:rw" \
    --env="XAUTHORITY=/home/ubuntu/.Xauthority" \
    --device /dev/dri \
    --privileged \
    --user "$(id -u):$(id -g)" \
    --volume="$HOST_WS_PATH:$CONTAINER_WS_PATH" \
    --volume="$BAXTER_SH_SRC:$CONTAINER_WS_PATH/baxter.sh:ro" \
    --workdir="$CONTAINER_WS_PATH" \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME"

# Revoke the X server access permission granted above
xhost -local:docker
