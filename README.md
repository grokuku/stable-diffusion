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

Use the environmental variable `WEBUI_VERSION` to choose which [project](#projects) to install and use based on the number in the **WEBUI** column. [easy diffusion](https://github.com/easydiffusion/easydiffusion) (`01`) is installed if none is specified. 

Example: To use SD.Next => `WEBUI_VERSION=04`

```
docker run ... -e WEBUI_VERSION=04 ... holaflenain/stable-diffusion
```

or modify `WEBUI_VERSION` in [docker-compose.yml](/docker-compose.yml)

## Docker Notes

### Using PUID and PGID

If you are 

* running on a **linux host** (ie unraid) and
* **not** using [rootless containers with Podman](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics#why_podman_)

then you must set the [environmental variables **PUID** and **PGID**.](https://docs.linuxserver.io/general/understanding-puid-and-pgid) in the container in order for it to generate files/folders your normal user can interact it.

Run these commands from your terminal

* `id -u` -- prints UID for **PUID**
* `id -g` -- prints GID for **PGID**

Then add to your docker command like so:

```shell
docker run -d ... -e "PUID=1000" -e "PGID=1000" ... holaflenain/stable-diffusion
```

or substitute them in [docker-compose.yml](/docker-compose.yml)

### Docker Compose
  
Reference [docker-compose.yml](/docker-compose.yml) which uses Easy-Diffusion as an example.

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

Due to the initial emphasis on simplifying the container's usability and setup process, certain project-specific details, such as the variable for triggering environment cleanup, have been left out.   
VoltaML (08) and Kubin (20) have been excluded to maintain focus on Stable-Diffusion for image generation.

General changes are listed below and **specified in notes if they apply.** Specific project modifications are listed below these.

###### Clean Environment

Auto-clean of environment when a project is behind the remote branch is removed.
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
