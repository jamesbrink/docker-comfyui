ARG BASE_IMAGE=nvidia/cuda:12.2.2-runtime-ubuntu22.04
FROM ${BASE_IMAGE}

# Install deps
RUN set -xe; \
    apt update && apt install -y \
        bash-completion \
        curl \
        ffmpeg \
        git \
        iproute2 \
        libgl1-mesa-glx \
        libglib2.0-0 \
        python-is-python3 \
        python3 \
        python3-pip \
        wget; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/cache/apt;

# Create our group & user.
RUN set -xe; \
    useradd -u 1000 -g 100 -r -d /comfyui -s /bin/sh comfyui;

# Setup ComfyUI
ARG VERSION=v0.0.5
RUN set -xe; \
    git clone --branch ${VERSION} --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui; \
    cd /comfyui; \
    pip install --no-cache-dir -r requirements.txt; \
    pip install --no-cache-dir comfy-cli; \
    chown -R comfyui:users /comfyui; \
    git config --global --add safe.directory /comfyui;

# Setup ComfyUI Manager
ARG UI_MANAGER_VERSION=2.48.6
RUN set -xe; \
    git clone --branch ${UI_MANAGER_VERSION} --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git /comfyui/custom_nodes/ComfyUI-Manager; \
    cd /comfyui/custom_nodes/ComfyUI-Manager; \
    pip install --no-cache-dir -r requirements.txt; \
    chown -R comfyui:users /comfyui/custom_nodes/ComfyUI-Manager; \
    git config --global --add safe.directory /comfyui/custom_nodes/ComfyUI-Manager;

# Copy our entrypoint into the container.
COPY ./runtime-assets /

# Ensure entrypoint is executable
RUN set -xe; \
    chmod 0755 /usr/local/bin/entrypoint.sh; \
    chown -R comfyui:users /comfyui;

ARG VCS_REF
ARG BUILD_DATE

# Labels / Metadata.
LABEL \
    org.opencontainers.image.authors="James Brink <brink.james@gmail.com>" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="ComfyUI Interface for Stable Diffusion" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/jamesbrink/comfyui" \
    org.opencontainers.image.title="comfyui" \
    org.opencontainers.image.vendor="jamesbrink" \
    org.opencontainers.image.version="${VERSION}"

# Setup our environment variables.
ENV \
    PATH="/usr/local/bin:/comfyui/.local/bin:$PATH" \
    VERSION="${VERSION}"

# Drop down to our unprivileged user.
USER comfyui
WORKDIR /comfyui

# Expose our http port.
EXPOSE 8188

# Volumes
VOLUME [ "/comfyui/models", "/comfyui/output", "/comfyui/input" ]

# Set the entrypoint.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set the default command
CMD ["python", "main.py","--listen", "--port","8188", "--preview-method", "auto"]
