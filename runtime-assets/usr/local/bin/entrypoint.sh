#!/bin/bash

# Ensure ComfyUI is synced to the volume.
rsync -avP --update /app/ /comfyui/

# Simple helpers to make an easy clickable link on console.
export LOCAL_ADDRESS="$(ip route get 1 | awk '{print $(NF-2);exit}')"
export PUBLIC_ADDRESS="$(curl ipinfo.io/ip)"
echo -e "\n\n################################################################################\n"
echo "Server running: http://$(hostname):8188"
echo "Server will be locally available at: http://$LOCAL_ADDRESS:8188"
echo -e "Server will be publicly available at: http://$PUBLIC_ADDRESS:8188\n"
echo -e "################################################################################\n\n"

# Setup the Comfy cli tool.
yes N | comfy tracking disable
comfy --install-completion

if [ $# -eq 0 ]; then
	flags="--listen --port 8188 --preview-method auto"
	echo "Start flags: $flags"
	exec /usr/bin/python main.py $flags
else
	echo "Start flags: $@"
	exec /usr/bin/python main.py "$@"
fi
