# ROS Jazzy Baxter Docker Workspace

This repository provides a Docker-based development environment for working with the Baxter robot using ROS 2 Jazzy and a legacy ROS 1 bridge. It includes scripts to build and run both base and development containers, as well as utilities for configuring your ROS environment.

## Project Structure

```
src/
  ├── baxter.sh              # ROS environment setup script for Baxter
  ├── build_all.sh           # Builds both base and dev Docker images
  ├── build_base.sh          # Builds the base Docker image (ROS1+ROS2)
  ├── build_dev.sh           # Builds the development Docker image
  ├── Dockerfile.base        # Dockerfile for the base image
  ├── Dockerfile.dev         # Dockerfile for the development image
  ├── entrypoint_dev.sh      # Entrypoint for the dev container
  ├── run_base.sh            # Runs the base container
  ├── run_dev.sh             # Runs the dev container with workspace mounting
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [xhost](https://linux.die.net/man/1/xhost) for GUI applications (Linux)
- (Optional) A Baxter robot or simulator

## Building Docker Images

From the `src/` directory, run:

```sh
./build_all.sh
```

Or build individually:

```sh
./build_base.sh
./build_dev.sh
```

## Running Containers

### Base Container (minimal, for bridge/testing)

```sh
./run_base.sh
```

### Development Container (with user workspace and GUI)

```sh
./run_dev.sh [PATH_TO_YOUR_WORKSPACE]
```

- If no workspace path is provided, it defaults to `../baxter_ws`.

## ROS Environment Setup

- Use `baxter.sh` to configure your ROS environment variables and networking.
- Edit `baxter.sh` to set your Baxter's IP/hostname and your own IP/hostname as needed.
- The script updates `/etc/hosts` for proper name resolution.

## Notes

- The development container runs as a non-root user (`ubuntu`) with sudo privileges.
- The workspace is mounted at `/home/ubuntu/<workspace_name>` inside the container.
- GUI applications (e.g., `rqt`, `rviz`) are supported via X11 forwarding.
- The ROS1 bridge and Baxter packages are pre-installed in the base image.

## Troubleshooting

- If you encounter networking or hostname resolution issues, ensure your IP/hostname settings in `baxter.sh` are correct.
- For GUI issues, make sure `xhost +local:docker` is run on your host before starting the container.

## Using the Bridge in the Dev Container

Once inside the development container, set up your ROS environments and launch the bridge:

```sh
source /opt/ros/jazzy/setup.sh
source /opt/ros/obese/setup.sh
./baxter.sh
ros2 launch baxter_bridge baxter_bridge_launch.py
```

> **Note:** You may see warnings from `sed` about renaming files in `/etc`—these are harmless in most container environments.

### Accessing Baxter Topics from ROS 2

In a **new terminal** (or tab), enter the dev container and source ROS 2:

```sh
source /opt/ros/jazzy/setup.sh
```

You can now list and interact with bridged topics:

```sh
ros2 topic list
```

Example output:
```
/clicked_point
/goal_pose
/initialpose
/parameter_events
/robot/joint_states
/robot/limb/left/joint_command
/robot/limb/right/joint_command
/robot/range/left_hand_range/state
/robot/range/right_hand_range/state
/robot/robot_description
/robot/sonar/head_sonar/state
/rosout
/tf
/tf_static
```

### Commanding Baxter's Joints

To command joint positions, publish to the appropriate topic (e.g., `/robot/limb/left/joint_command`):

```sh
ros2 topic pub -r 100 /robot/limb/left/joint_command baxter_core_msgs/msg/JointCommand "mode: 1
command: [0.08, 0.443, -1.657, 1.218, 0.068, 1.396, -0.50]
names: ['left_s0', 'left_s1', 'left_e0', 'left_e1', 'left_w0', 'left_w1', 'left_w2']"
```

> **Tip:** Adjust the `command` values for your desired pose. Use `-r` to set the publish rate (e.g., `-r 100` for 100 Hz).

### Bridge Runtime Options

The following options can be passed to the baxter_bridge  `bridge` node:

- `-s` &nbsp;&nbsp;&nbsp;&nbsp;: Forward **all** topics (can be a lot of data).
- `--server` : Instantiate the synchronization server (only one per network). Without this, the first `bridge` will instantiate it automatically.

> **Note:**  
> If you want to use these runtime options, you will need to create your own launch file that launches the bridge node with custom arguments, or run the bridge node directly from the command line.  
> The provided `baxter_bridge_launch.py` launches the bridge node automatically, but does not pass these runtime arguments.  
> For advanced use (e.g., passing `-s` or `--server`, or launching additional nodes like RViz), create a custom launch file or run the bridge node manually:

```sh
ros2 run baxter_bridge bridge -s --server --ros-args -p use_baxter_description:=true
```

You may need to force additional topics to forward if you want to control other aspects of Baxter.

## Workspace Build Requirement

> **Note:**  
> The `baxter.sh` script requires a **built ROS workspace** (e.g., `<workspace_path>`) to function properly.

If you are using a linked workspace or the default `<workspace_path>`, make sure:

1. The workspace directory exists and contains a `src/` folder:
    ```sh
    ls <workspace_path>/src
    ```
    If it does not exist, create it:
    ```sh
    mkdir -p <workspace_path>/src
    ```

2. The workspace is built:
    - For **catkin** (ROS 1):
      ```sh
      cd <workspace_path>
      catkin_make
      ```
    - For **colcon** (ROS 2 or mixed):
      ```sh
      cd <workspace_path>
      colcon build
      ```

3. After building, source the appropriate setup file before running `baxter.sh`:
    ```sh
    source <workspace_path>/devel/setup.bash   # for catkin
    # or
    source <workspace_path>/install/setup.bash # for colcon
    ```

If the workspace is not built, `baxter.sh` will not function correctly.  
**Always ensure your workspace is built before running the script.**

---

**Maintainers:**  
- name: Caleb Blondell  
  email: crblondell@nic.edu
