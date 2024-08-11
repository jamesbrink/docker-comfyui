#!/usr/bin/env bash
set -e
mkdir -p build-assets/app/models/checkpoints
cd build-assets/app/models/checkpoints
wget -c 'https://huggingface.co/stabilityai/sd-turbo/resolve/main/sd_turbo.safetensors'
wget -c 'https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt'
wget -c 'https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt_image_decoder.safetensors'
wget -c 'https://huggingface.co/stabilityai/stable-video-diffusion-img2vid/resolve/main/svd.safetensors'