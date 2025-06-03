#!/bin/bash

# ------------- SETTINGS -------------
IMAGE_NAME=baxter-ros2-jazzy

# Set this to use a different workspace folder placed next to this script
USER_WS_NAME="${1:-baxter_ws}"  # default to "baxter_ws" unless passed as argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_WS_PATH="$SCRIPT_DIR/$USER_WS_NAME"


# Container workspace and prebuilt package location
CONTAINER_WS_PATH="/home/baxter/$USER_WS_NAME"
CONTAINER_SRC_PATH="$CONTAINER_WS_PATH/src"
PREBUILT_SRC_PATH="/ros2_ws/src/baxter_common_ros2"
PREBUILT_WS_INSTALL="/ros2_ws/install"

# ----- BUILD IMAGE -----
docker build --no-cache -t baxter-ros2-jazzy .

# ----- ALLOW GUI FOR DOCKER -----
xhost +local:docker

# ----- NETWORK SETUP -----
ROS_IP=$(hostname -I | awk '{print $1}')
baxter_hostname=172.16.208.51

# ----- ENSURE WORKSPACE EXISTS ON HOST -----
mkdir -p "$HOST_WS_PATH"
chmod -R a+rw "$HOST_WS_PATH"

# ----- RUN CONTAINER -----
docker run -it --rm \
    #--user $(id -u):$(id -g) \
    --net=host \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="baxter_hostname=$baxter_hostname" \
    --env="ROS_IP=$ROS_IP" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="$HOST_WS_PATH:$CONTAINER_SRC_PATH" \
    --volume="/dev:/dev" \
    --workdir="$CONTAINER_WS_PATH" \
    --name baxter-ros2-jazzy-container \
    $IMAGE_NAME \
    bash -c "
        source /opt/ros/jazzy/setup.bash
        cd $CONTAINER_WS_PATH
        if [ -n \"\$(find src/$USER_WS_NAME -type f -newer build -print -quit)\" ]; then
            echo '[INFO] Changes detected. Building user packages...'
            colcon build --symlink-install --packages-skip baxter_common_ros2
        else
            echo '[INFO] No changes detected in user packages. Skipping build.'
        fi
        exec bash"
