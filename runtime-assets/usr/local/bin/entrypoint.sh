#!/bin/bash

# Update UID/GID if provided
if [ ! -z "${PUID}" ] && [ ! -z "${PGID}" ]; then
    echo "Updating UID:GID to ${PUID}:${PGID}"
    # Check if we have permission to modify users/groups
    if command -v usermod >/dev/null 2>&1 && [ "$(id -u)" = "0" ]; then
        # Recreate the user first with new UID if needed
        if [ "${PUID}" != "$(id -u comfyui 2>/dev/null)" ]; then
            userdel comfyui 2>/dev/null || true
            useradd -u "${PUID}" -g users -r -d /comfyui -s /bin/sh comfyui
        fi
        # Update the GID
        if [ "${PGID}" != "$(id -g comfyui)" ]; then
            groupmod -o -g "${PGID}" users
        fi
        # Fix ownership of key directories
        chown -R comfyui:users /comfyui /app || true
    else
        echo "Warning: Running in rootless mode or missing permissions, skipping user/group modifications"
    fi
fi

# Start Xvfb in background with retry
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
    Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
    sleep 1
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        break
    fi
    echo "Attempt $attempt: Xvfb failed to start, retrying..."
    pkill Xvfb
    attempt=$((attempt + 1))
    sleep 1
done

# Export Display for GUI applications
export DISPLAY=:99

# Ensure ComfyUI is synced to the volume, with fallback if rsync fails
if ! rsync -avP --update /app/ /comfyui/; then
    echo "Warning: rsync failed, falling back to cp"
    cp -ru /app/* /comfyui/
fi

# Activate Python virtual environment
source /comfyui/venv/bin/activate

# Get IP addresses with fallbacks
if command -v ip >/dev/null 2>&1; then
    LOCAL_ADDRESS="$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')"
else
    LOCAL_ADDRESS="127.0.0.1"
fi

# Only try to get public IP if we have curl and network access
if command -v curl >/dev/null 2>&1 && curl -s ipinfo.io >/dev/null 2>&1; then
    PUBLIC_ADDRESS="$(curl -s ipinfo.io/ip)"
else
    PUBLIC_ADDRESS="external-ip-not-available"
fi

echo -e "\n\n################################################################################\n"
echo "Server running: http://$(hostname):8188"
echo "Server will be locally available at: http://${LOCAL_ADDRESS:-localhost}:8188"
echo -e "Server will be publicly available at: http://${PUBLIC_ADDRESS:-external-ip-not-available}:8188\n"
echo -e "################################################################################\n\n"

# Setup the Comfy cli tool
yes N | comfy tracking disable || true
comfy --install-completion || true

# Install custom nodes
echo "Installing custom nodes..."
comfy node install --mode remote ComfyUI-Crystools,ComfyUI-Custom-Scripts || echo "Warning: Failed to install custom nodes"

# Ensure proper ownership (mostly for volumes) with fallback for rootless
if [ "$(id -u)" = "0" ]; then
    chown -R comfyui:users /comfyui || true
    chown -R comfyui:users /comfyui/user || true
fi

if [ $# -eq 0 ]; then
    flags="--listen --port 8188 --preview-method auto"
    echo "Start flags: $flags"
    exec gosu comfyui python main.py $flags
else
    echo "Start flags: $@"
    exec gosu comfyui python main.py "$@"
fi