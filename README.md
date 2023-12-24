# Easy Image Generation

/!\ FOLDERS PATH CHANGED since V3.0.0 /!\  
be sure to check the usage section 

The goal of this docker container is to provide an easy way to run different WebUI and other tools related to Image Generation (mostly stable-diffusion).
  
Please consult each respective website for a comprehensive description and usage guidelines.  
| WEBUI | Name              |                                                                                                                                              |                                                         |
|-------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| 01    | easy diffusion    | The easiest way to install and use Stable Diffusion on your computer.                                                                        | https://github.com/easydiffusion/easydiffusion          |
| 02    | automatic1111     | A browser interface based on Gradio library for Stable Diffusion                                                                             | https://github.com/AUTOMATIC1111/stable-diffusion-webui |
| 03    | InvokeAI          | InvokeAI is a leading creative engine for Stable Diffusion models                                                                            | https://github.com/invoke-ai                            |
| 04    | SD.Next           | This project started as a fork from Automatic1111 WebUI and it grew significantly                                                            | https://github.com/vladmandic/automatic                 |
| 05    | ComfyUI           | A powerful and modular stable diffusion GUI and backend                                                                                      | https://github.com/comfyanonymous/ComfyUI               |
| 06    | Fooocus           | Fooocus is a rethinking of Stable Diffusion and Midjourney’s designs                                                                         | https://github.com/lllyasviel/Fooocus                   |
| 07    | StableSwarm       | A Modular Stable Diffusion Web-User-Interface, with an emphasis on making powertools easily accessible, high performance, and extensibility. | https://github.com/Stability-AI/StableSwarmUI           |
| 08    | VoltaML           | Stable Diffusion WebUI and API accelerated by AITemplate                                                                                     | https://github.com/lllyasviel/Fooocus                   |
| 20    | kubin (Kandinsky) | Kubin is a Web-GUI for Kandinsky 2.x 🚧 WIP 🚧 NOT PRODUCTION-READY 🚧                                                                      | https://github.com/seruva19/kubin                       |
| 50    | Lama Cleaner      | A free and open-source inpainting tool powered by SOTA AI model.                                                                             | https://github.com/Sanster/lama-cleaner                 |
| 51    | FaceFusion        | Next generation face swapper and enhancer                                                                                                    | https://github.com/facefusion/facefusion                |
| 70    | Kohya             | Kohya's GUI provides a Windows-focused Gradio GUI for Kohya's Stable Diffusion trainers                                                      | https://github.com/bmaltais/kohya_ss                    |
  

## Usage


Unraid template available on superboki's Repository (search diffusion in community apps)
  
Docker-Compose example for Easy-Diffusion: 

```yaml
version: '3.1'
services:
  stable-diffusion-test:
    image: holaflenain/stable-diffusion:latest
    container_name: stable-diffusion
    environment:
      - WEBUI_VERSION=01
      - NVIDIA_VISIBLE_DEVICES=all
      - TZ=Europe/Paris
      - PUID=99
      - PGID=100
    ports:
      - '9000:9000/tcp'
    volumes:
      - '/my/own/datadir:/config:rw'
    runtime: nvidia

```
Steps to migrate to V3 :  
- Edit Stable-Diffusion UI Path :  
    Container Path => /config  
    Remove Outputs (Images will still be generated at /mnt/user/appdata/stable-diffusion/outputs)
- Add Variables :  
    Name/Key => PUID  
    Value => 99  
  
    Name/Key => PGID  
    Value => 100


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


## History
- **Version 3.0.0** :  
Rework base image to use Linuxserverio + Memory leak fix For SD-Next (thanks @FoxxMD)  
Fix for Fooocus (thanks @dominickp)

- **Version 2.0.2** :  
move .cache folder to stable-diffusion/temp to avoid filling unraid's docker.img file.  
(hopefully) fix all the things I broke in the last update :)  
  
- **Version 2.0.0** :  
Utilize Conda to manage dependencies efficiently.  
Prepared for Reactor in Auto1111, SD-Next, and ComfyUI.  
More common folders merged in the models folder.  
Split install scripts for easier maintenance.  
Implemented various fixes.  
  
- **Version 1.5.1** :  
Added a fix for Automatic1111/dreambooth
  
- **Version 1.5.0** :  
Added StableSwarm and VoltaML
  
- **Version 1.4.0** :  
Added FaceFusion
  
- **Version 1.3.0** :  
Added Kubin  (Kubin is only for testing, not production ready)
Corrected update of ComfyUI at startup not working
  
- **Version 1.2.0** :  
Added Lama-cleaner and Kohya
  
- **Version 1.1.0** :  
Added Focus as interface 06  
Small Fixes  
  
- **Version 1.0.0** :  
Lots of modifications on directory structure.  
Before using this version it's best to do a backup, do a clean install and restore models,loras, ect from the backup.

## Troubleshoot :  
First thing to try when a UI refuse to launch, remove the cache and the numbered folder (ex :02-sd-webui ) then relaunch the container  
  
## Support :  
Support for the container available here : https://forums.unraid.net/topic/143645-support-stable-diffusion-advanced/  
Support for the WebUIs available on their respective pages.