#!/bin/bash
# Copyright (c) 2013-2015, Rethink Robotics
# All rights reserved.

# This file is to be used in the *root* of your Catkin workspace.

# This is a convenient script which will set up your ROS environment and
# should be executed with every new instance of a shell in which you plan on
# working with Baxter.

# Clear any previously set your_ip/your_hostname
unset your_ip
unset your_hostname
#-----------------------------------------------------------------------------#
#                 USER CONFIGURABLE ROS ENVIRONMENT VARIABLES                 #
#-----------------------------------------------------------------------------#
# Note: If ROS_MASTER_URI, ROS_IP, or ROS_HOSTNAME environment variables were
# previously set (typically in your .bashrc or .bash_profile), those settings
# will be overwritten by any variables set here.

# Specify Baxter's hostname
baxter_ip="169.254.7.105"


baxter_hostname="011608P0034.local"


#The following makes sure that you can properly recieve messages from baxter. Without it, the hostname won't resolve since in container.
entry="${baxter_ip} ${baxter_hostname}"

# Check if the exact entry already exists
if ! grep -Fxq "$entry" /etc/hosts; then
    # Remove any old lines with the same IP or hostname
    sudo sed -i "/[[:space:]]${baxter_hostname}$/d" /etc/hosts
    sudo sed -i "/^${baxter_ip}[[:space:]]/d" /etc/hosts

    # Add the new entry
    echo "$entry" | sudo tee -a /etc/hosts > /dev/null
fi

# 4. Define your local IP (you may want to change this to get your actual primary IP)
# Set *Either* your computers ip address or hostname. Please note if using
# your_hostname that this must be resolvable to Baxter.
your_ip=$(hostname -I | awk '{print $1}')  # Gets your primary IP
#your_hostname="my_computer.local"

# Specify ROS distribution (e.g. indigo, hydro, etc.)
ros_version="obese"
#-----------------------------------------------------------------------------#

tf=$(mktemp)
trap "rm -f -- '${tf}'" EXIT

# If this file specifies an ip address or hostname - unset any previously set
# ROS_IP and/or ROS_HOSTNAME.
# If this file does not specify an ip address or hostname - use the
# previously specified ROS_IP/ROS_HOSTNAME environment variables.
if [ -n "${your_ip}" ] || [ -n "${your_hostname}" ]; then
	unset ROS_IP && unset ROS_HOSTNAME
else
	your_ip="${ROS_IP}" && your_hostname="${ROS_HOSTNAME}"
fi

# If argument provided, set baxter_hostname to argument
# If argument is sim or local, set baxter_hostname to localhost
if [ -n "${1}" ]; then
	if [[ "${1}" == "sim" ]] || [[ "${1}" == "local" ]]; then
		baxter_hostname="localhost"
		if [[ -z ${your_ip} || "${your_ip}" == "192.168.XXX.XXX" ]] && \
		[[ -z ${your_hostname} || "${your_hostname}" == "my_computer.local" ]]; then
			your_hostname="localhost"
			your_ip=""
		fi
	else
		baxter_hostname="${1}"
	fi
fi

topdir=$(basename $(readlink -f $(dirname ${BASH_SOURCE[0]})))

cat <<-EOF > ${tf}
	[ -s "\${HOME}"/.bashrc ] && source "\${HOME}"/.bashrc
	[ -s "\${HOME}"/.bash_profile ] && source "\${HOME}"/.bash_profile

	# verify this script is moved out of baxter folder
	if [[ -e "${topdir}/baxter_sdk/package.xml" ]]; then
		echo -ne "EXITING - This script must be moved from the baxter folder \
to the root of your catkin workspace.\n"
		exit 1
	fi

	# verify ros_version lowercase
	ros_version="$(tr [A-Z] [a-z] <<< "${ros_version}")"

	# check for ros installation
	if [ ! -d "/opt/ros" ] || [ ! "$(ls -A /opt/ros)" ]; then
		echo "EXITING - No ROS installation found in /opt/ros."
		echo "Is ROS installed?"
		exit 1
	fi

	# if set, verify user has modified the baxter_hostname
	if [ -n ${baxter_hostname} ] && \
	[[ "${baxter_hostname}" == "baxter_hostname.local" ]]; then
		echo -ne "EXITING - Please edit this file, modifying the \
'baxter_hostname' variable to reflect Baxter's current hostname.\n"
		exit 1
	fi

	# if set, verify user has modified their ip address (your_ip)
	if [ -n ${your_ip} ] && [[ "${your_ip}" == "192.168.XXX.XXX" ]]; then
		echo -ne "EXITING - Please edit this file, modifying the 'your_ip' \
variable to reflect your current IP address.\n"
		exit 1
	fi

	# if set, verify user has modified their computer hostname (your_hostname)
	if [ -n ${your_hostname} ] && \
	[[ "${your_hostname}" == "my_computer.local" ]]; then
		echo -ne "EXITING - Please edit this file, modifying the \
'your_hostname' variable to reflect your current PC hostname.\n"
		exit 1
	fi

	# verify user does not have both their ip *and* hostname set
	if [ -n "${your_ip}" ] && [ -n "${your_hostname}" ]; then
		echo -ne "EXITING - Please edit this file, modifying to specify \
*EITHER* your_ip or your_hostname.\n"
		exit 1
	fi

	# verify that one of your_ip, your_hostname, ROS_IP, or ROS_HOSTNAME is set
	if [ -z "${your_ip}" ] && [ -z "${your_hostname}" ]; then
		echo -ne "EXITING - Please edit this file, modifying to specify \
your_ip or your_hostname.\n"
		exit 1	
	fi

	# verify specified ros version is installed
	ros_setup="/opt/ros/\${ros_version}"
	if [ ! -d "\${ros_setup}" ]; then
		echo -ne "EXITING - Failed to find ROS \${ros_version} installation \
in \${ros_setup}.\n"
		exit 1
	fi

	# verify the ros setup.sh file exists
	if [ ! -s "\${ros_setup}"/setup.sh ]; then
		echo -ne "EXITING - Failed to find the ROS environment script: \
"\${ros_setup}"/setup.sh.\n"
		exit 1
	fi

	# verify the user is running this script in the root of the workspace and that the workspace has been compiled.
    if [ -s "devel/setup.bash" ]; then
        WORKSPACE_SETUP="devel/setup.bash"
    elif [ -s "install/setup.bash" ]; then
        WORKSPACE_SETUP="install/setup.bash"
    else
        echo "WARNING: No setup file found to source (no packages built yet)."
        WORKSPACE_SETUP=""
    fi

    [ -n "${your_ip}" ] && export ROS_IP="${your_ip}"
    [ -n "${your_hostname}" ] && export ROS_HOSTNAME="${your_hostname}"
    [ -n "${baxter_hostname}" ] && \
        export ROS_MASTER_URI="http://${baxter_hostname}:11311"

    # source the workspace setup bash script (catkin or colcon) if it exists
    if [ -n "${WORKSPACE_SETUP}" ] && [ -f "${WORKSPACE_SETUP}" ]; then
        source "${WORKSPACE_SETUP}"
    fi

    # setup the bash prompt
    export __ROS_PROMPT=\${__ROS_PROMPT:-0}
    [ \${__ROS_PROMPT} -eq 0 -a -n "\${PROMPT_COMMAND}" ] && \
		export __ORIG_PROMPT_COMMAND=\${PROMPT_COMMAND}

	__ros_prompt () {
		if [ -n "\${__ORIG_PROMPT_COMMAND}" ]; then
			eval \${__ORIG_PROMPT_COMMAND}
		fi
		if ! echo \${PS1} | grep '\[baxter' &>/dev/null; then
			export PS1="\[\033[00;33m\][baxter - \
\${ROS_MASTER_URI}]\[\033[00m\] \${PS1}"
		fi
	}

	if [ "\${TERM}" != "dumb" ]; then
		export PROMPT_COMMAND=__ros_prompt
		__ROS_PROMPT=1
	elif ! echo \${PS1} | grep '\[baxter' &>/dev/null; then
		export PS1="[baxter - \${ROS_MASTER_URI}] \${PS1}"
	fi

EOF

export LD_LIBRARY_PATH=/opt/ros/jazzy/lib:/opt/ros/obese/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY}

${SHELL} --rcfile ${tf}

rm -f -- "${tf}"
trap - EXIT

# vim: noet