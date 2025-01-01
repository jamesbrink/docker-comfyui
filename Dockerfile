ARG BASE_IMAGE=nvidia/cuda:12.6.3-runtime-ubuntu22.04
FROM ${BASE_IMAGE} AS base

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# OpenGL/EGL configuration
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_GL_VERSION_OVERRIDE=3.3
ENV PYOPENGL_PLATFORM=egl
ENV DISPLAY=:99

# Install deps
RUN set -xe; \
    apt update && apt install -y \
        bash-completion \
        build-essential \
        cmake \
        curl \
        ffmpeg \
        git \
        gosu \
        iproute2 \
        libbz2-dev \
        libegl1 \
        libgl1 \
        libgl1-mesa-dev \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libglu1-mesa-dev \
        libglvnd-dev \
        libglx0 \
        libopencv-dev \
        libopengl0 \
        libosmesa6-dev \
        libx11-dev \
        libxcursor-dev \
        libxi-dev \
        libxinerama-dev \
        libxrandr-dev \
        mesa-common-dev \
        mesa-utils \
        ninja-build \
        pkg-config \
        python-is-python3 \
        python3 \
        python3-pip \
        python3-psutil \
        python3.10-venv \
        rsync \
        sudo \
        unzip \
        vim \
        wget \
        xauth \
        xvfb \
        xorg-dev \
        mesa-vulkan-drivers \
        vulkan-tools \
        nvidia-utils-535 \
        libglfw3-dev \
        libgles2-mesa-dev \
        libegl1-mesa-dev \
        libxkbcommon-x11-0 \
        libvulkan1 \
        libosmesa6 \
        mesa-utils-extra; \
    apt clean; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/cache/apt;

# Create our group & user.
RUN set -xe; \
    useradd -u 1000 -g 100 -G sudo -r -d /comfyui -s /bin/sh comfyui; \
    echo "comfyui ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    mkdir -p /comfyui; \
    mkdir -p /app

# Create and activate Python virtual environment
ARG VIRTUAL_ENV=/app/venv
RUN set -xe; \
    python3 -m venv $VIRTUAL_ENV; \
    $VIRTUAL_ENV/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

# Add virtual environment to PATH
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Setup ComfyUI
ARG VERSION=v0.3.10
RUN set -xe; \
    git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI; \
    cd /app/ComfyUI; \
    git fetch --all --tags; \
    git checkout ${VERSION}; \
    pip install --no-warn-script-location --no-cache-dir -r requirements.txt; \
    pip install --no-warn-script-location --no-cache-dir comfy-cli

# Setup ComfyUI Manager
ARG UI_MANAGER_VERSION=main
RUN set -xe; \
    mkdir -p /app/ComfyUI/custom_nodes; \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /app/ComfyUI/custom_nodes/ComfyUI-Manager; \
    cd /app/ComfyUI/custom_nodes/ComfyUI-Manager; \
    git fetch --all --tags; \
    git checkout ${UI_MANAGER_VERSION}; \
    pip install --no-warn-script-location --no-cache-dir -r requirements.txt

# Copy our entrypoint into the container.
COPY ./runtime-assets /

# Ensure entrypoint is executable
RUN set -xe; \
    chmod 0755 /usr/local/bin/entrypoint.sh; \
    chown -R comfyui:users /app; \
    chown -R comfyui:users /comfyui;

# Labels / Metadata.
LABEL \
    org.opencontainers.image.authors="James Brink <brink.james@gmail.com>" \
    org.opencontainers.image.description="ComfyUI Interface for Stable Diffusion" \
    org.opencontainers.image.revision="1" \
    org.opencontainers.image.source="https://github.com/jamesbrink/comfyui" \
    org.opencontainers.image.title="comfyui" \
    org.opencontainers.image.vendor="jamesbrink" \
    org.opencontainers.image.version="${VERSION}"

# Setup our environment variables.
ENV \
    __GLX_VENDOR_LIBRARY_NAME=nvidia \
    HOME="/comfyui" \
    MODERNGL_BACKEND=osmesa \
    NVIDIA_DRIVER_CAPABILITIES=all \
    PATH="/usr/local/bin:/comfyui/.local/bin:$PATH" \
    PGID=100 \
    PUID=1000 \
    PYTHONUNBUFFERED=1 \
    VERSION="${VERSION}" \
    VIRTUAL_ENV=/comfyui/venv

# USER comfyui
WORKDIR /comfyui

# Setup git
RUN set -xe; \
    git config --global user.name "ComfyUI"; \
    git config --global user.email "ComfyUI@urandom.io"; \
    git config --global init.defaultBranch main; \
    git config --global core.editor "vim"; \
    git config --global --add safe.directory /comfyui; \
    git config --global --add safe.directory /comfyui/custom_nodes/ComfyUI-Manager;

# Expose our http port.
EXPOSE 8188

# Volumes
VOLUME [ "/comfyui", "/comfyui/models", "/comfyui/output", "/comfyui/input", "/comfyui/user" ]

# Set the entrypoint.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set the default command
CMD [ "--listen", "--port","8188", "--preview-method", "auto", "--multi-user" ]
