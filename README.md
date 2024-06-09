# Easy Image Generation

[![Docker Pulls](https://img.shields.io/docker/pulls/holaflenain/stable-diffusion)](https://hub.docker.com/r/holaflenain/stable-diffusion)

The goal of this docker container is to provide an easy way to run different WebUI/projects and other tools related to Image Generation (mostly stable-diffusion).

# Projects 

Please consult each respective website for a comprehensive description and usage guidelines.  
| WEBUI | Name              |                                                                                                                                              |                                                         |
|-------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| 01    | easy diffusion    | The easiest way to install and use Stable Diffusion on your computer.                                                                        | https://github.com/easydiffusion/easydiffusion          |
| 02    | automatic1111     | A browser interface based on Gradio library for Stable Diffusion                                                                             | https://github.com/AUTOMATIC1111/stable-diffusion-webui |
| 02.forge    | forge     | An optimized fork of Automatic1111                                                                             | https://github.com/lllyasviel/stable-diffusion-webui-forge |
| 03    | InvokeAI          | InvokeAI is a leading creative engine for Stable Diffusion models                                                                            | https://github.com/invoke-ai                            |
| 04    | SD.Next           | This project started as a fork from Automatic1111 WebUI and it grew significantly                                                            | https://github.com/vladmandic/automatic                 |
| 05    | ComfyUI           | A powerful and modular stable diffusion GUI and backend                                                                                      | https://github.com/comfyanonymous/ComfyUI               |
| 06    | Fooocus           | Fooocus is a rethinking of Stable Diffusion and Midjourney’s designs                                                                         | https://github.com/lllyasviel/Fooocus                   |
| 07    | StableSwarm       | A Modular Stable Diffusion Web-User-Interface, with an emphasis on making powertools easily accessible, high performance, and extensibility. | https://github.com/Stability-AI/StableSwarmUI           |
| 50    | Lama Cleaner      | A free and open-source inpainting tool powered by SOTA AI model.                                                                             | https://github.com/Sanster/lama-cleaner                 |
| 51    | FaceFusion        | Next generation face swapper and enhancer                                                                                                    | https://github.com/facefusion/facefusion                |
| 70    | Kohya             | Kohya's GUI provides a Windows-focused Gradio GUI for Kohya's Stable Diffusion trainers                                                      | https://github.com/bmaltais/kohya_ss                    |
  

# Usage

Unraid template available on [superboki's Repository](https://github.com/superboki/UNRAID-FR/tree/main/stable-diffusion-advanced) (search stable-diffusion in community apps)

## Choosing a Project

```
docker compose --profile easy-diffusion up    # http://<server_ip>:9001
docker compose --profile automatic up         # http://<server_ip>:9002
docker compose --profile forge up             # http://<server_ip>:9022
docker compose --profile invoke-ai up         # http://<server_ip>:9003
docker compose --profile sd-next up           # http://<server_ip>:9004
docker compose --profile comfy-ui up          # http://<server_ip>:9005
docker compose --profile fooocus up           # http://<server_ip>:9006
docker compose --profile stable-swarm up      # http://<server_ip>:9007
docker compose --profile lama-cleaner up      # http://<server_ip>:9050
docker compose --profile face-fusion up       # http://<server_ip>:9051
docker compose --profile kohya up             # http://<server_ip>:9070

```

or 
( Although not recommended as it will requires significant system resources, 64GB+ system memory and at bare minimum 16GB VRAM card, you have been warned! ) 

```
docker compose up       # to run all the services at once
```

## Make

alternatively you can use make to start and stop the services

there are two variations 

```
# will start the service detached from the terminal (running in the background)
make start <profile_name> 

# will start the service and leave its output attached to the terminal
make up <profile_name>
```
Here is a complete list for starting services
```
make start easy-diffusion    # http://<server_ip>:9001
make start automatic         # http://<server_ip>:9002
make start forge             # http://<server_ip>:9022
make start invoke-ai         # http://<server_ip>:9003
make start sd-next           # http://<server_ip>:9004
make start comfy-ui          # http://<server_ip>:9005
make start fooocus           # http://<server_ip>:9006
make start stable-swarm      # http://<server_ip>:9007
make start lama-cleaner      # http://<server_ip>:9050
make start face-fusion       # http://<server_ip>:9051
make start kohya             # http://<server_ip>:9070
```


## Directory Structure

Each interface has its own folder :  
- **stable-diffusion** folder tree:  
├── 01-easy-diffusion  
├── 02-sd-webui  
...  
├── 51-facefusion   
├── 70-kohya   
└── models  

Models, VAEs, and other files are located in the shared models directory and symlinked for each user interface, excluding InvokeAI:    
- **Models** folder tree :  
├── embeddings  
├── hypernetwork  
├── lora  
├── stable-diffusion  
├── upscale  
└── vae  
  
By default, each user interface will save data in its own directory, which is automatically created during the initial installation of the UI. To modify the storage path, you can edit the 'parameters.txt' file for InvokeAI and ComfyUI, while for the others, it can be adjusted via the WebUI.  
- **Outputs** folder tree :  
├── 01-Easy-Diffusion  
├── 02-sd-webui  
...   
├── 20-kubin   
├── 50-lama-cleaner   
└── 51-facefusion   

## Project Notes

VoltaML (08) and Kubin (20) have been excluded to maintain focus on Stable-Diffusion for image generation.

General changes are listed below and **specified in notes if they apply.** Specific project modifications are listed below these.

###### Clean Environment

Auto-clean of environment when a project is behind the remote branch is only launched if varaible CLEAN_ENV is set to true.  
To trigger a clean, now you have to delete the file names "Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch" in the root folder.
This applies to the launching project only.

#### Access rights reset

If something went wrong and you can't access certain files, you can reset access rights by deleting the file named 'Delete_this_file_to_reset_access_rights_at_next_launch' in the root folder.   
This applies to all the /config folder.   

# History

See [**Changelog**](/CHANGELOG.md)
  
# Support

Support for the container available here : https://forums.unraid.net/topic/143645-support-stable-diffusion-advanced/  
Support for the WebUIs available on their respective pages.

## Troubleshooting

First thing to try when a UI refuse to launch, remove the cache and the numbered folder (ex :02-sd-webui ) then relaunch the container  
