# ComfyUI (Stable Diffusion)

## About

Simple Docker image for the [ComfyUI web interface][ComfyUI], with [ComfyUI Manager][ComfyUIManager]. This docker image has only been tested on **Linux with NVIDIA GPUs**.

## Usage

Build and run the container container:  

```shell
make
docker run -d --gpus all -p 8188:8188 -v ./models:/comfyui/models -v ./output:/comfyui/output -v ./input:/comfyui/input --name comfyui jamesbrink/comfyui
```

Optionally run container on host nework:  

```shell
docker run -d --gpus all --network=host -v ./models:/comfyui/models -v ./output:/comfyui/output -v ./input:/comfyui/input --name comfyui jamesbrink/comfyui
```

If you want to share models between ComfyUI and tools like Fooocus, you can map the volumes like so: 

```shell
mkdir -p ~/AI/Models/StableDiffusion/
mkdir -p ~/AI/Output◊
mkdir -p ~/AI/Input
```

Then simply run the container with the newly mapped volumes:  

```shell
docker run -d --gpus all --network=host -v ~/AI/Models/StableDiffusion/:/comfyui/models -v ~/AI/Output:/comfyui/output -v ~/AI/Input:/comfyui/input --name comfyui jamesbrink/comfyui
```

[ComfyUI]: https://github.com/comfyanonymous/ComfyUI
[ComfyUIManager]: https://github.com/ltdrdata/ComfyUI-Manager