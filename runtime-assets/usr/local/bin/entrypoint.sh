#!/bin/bash

# Ensure ComfyUI is synced to the volume.
rsync -avP --update /app/ /comfyui/

# Simple helpers to make an easy clickable link on console.
export LOCAL_ADDRESS="$(ip route get 1 | awk '{print $(NF-2);exit}')"
export PUBLIC_ADDRESS="$(curl ipinfo.io/ip)"
echo -e "\n\n################################################################################\n"
echo "Server will be locally available at: http://$LOCAL_ADDRESS:8188"
echo -e "Server will be publicly available at: http://$PUBLIC_ADDRESS:8188\n"
echo -e "################################################################################\n\n"

# Setup the Comfy cli tool.
yes N | comfy tracking disable
comfy --install-completion

if [ $# -eq 0 ]; then
	echo "No command was given to run, exiting."
	exit 1
else
	# git reset HEAD --hard
	exec "$@"
fi
