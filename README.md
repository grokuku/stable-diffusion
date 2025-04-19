# Easy Image Generation Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/holaflenain/stable-diffusion)](https://hub.docker.com/r/holaflenain/stable-diffusion)

This Docker container provides a convenient way to manage and run various Stable Diffusion WebUIs and related image generation tools. It centralizes model storage and offers a consistent setup process for multiple interfaces.

## Features

*   **Multiple UIs:** Run popular Stable Diffusion interfaces like AUTOMATIC1111, SD.Next, ComfyUI, Fooocus, InvokeAI, and more.
*   **Training GUIs:** Includes interfaces for training like Kohya_ss, Fluxgym, and OneTrainer.
*   **Utility Tools:** Includes tools like IOPaint (inpainting) and FaceFusion (face swapping).
*   **Centralized Models:** Models (checkpoints, LoRAs, VAEs, etc.) are stored in a shared directory (`./data/stable-diffusion/models` by default) and symlinked into each UI's expected location, saving disk space.
*   **Environment Management:** Uses Conda to manage isolated Python environments for each UI.
*   **Configurable:** Launch parameters for each UI can be customized via text files.
*   **Docker Compose Integration:** Uses Docker Compose profiles for easy selection and management of individual UIs.
*   **Makefile Convenience:** Provides `make` commands for simpler start/stop operations.

## Prerequisites

*   **Docker:** [Install Docker](https://docs.docker.com/engine/install/)
*   **Docker Compose:** Usually included with Docker Desktop, or [install separately](https://docs.docker.com/compose/install/).
*   **(Optional but Recommended for GPU Acceleration)** NVIDIA GPU with appropriate drivers installed on the host system.
*   **(Optional but Recommended for GPU Acceleration)** [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed to allow Docker containers access to the GPU (`runtime: nvidia` in `docker-compose.yml`).

## Setup and Usage

This project uses Docker Compose profiles to manage the different UIs.

**1. Clone the Repository (Optional):**
   If you want to customize the `docker-compose.yml` or build the image locally:
   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```
   Otherwise, you can just use the provided `docker-compose.yml` or create your own based on the examples.

**2. Configure Volumes:**
   The `docker-compose.yml` maps a host directory to `/config` inside the container. By default, it uses `./data/stable-diffusion`. This directory will contain:
    *   Subdirectories for each UI (e.g., `01-easy-diffusion`, `02-sd-webui`).
    *   The shared `models` directory.
    *   The shared `outputs` directory.
    *   Log files (`sd-webui.log`).
    *   Configuration files (like `parameters.txt` or `config.yaml` for each UI).
    *   Marker files for cleaning environments or resetting permissions.
   Ensure the host directory you choose has sufficient disk space and appropriate permissions.

**3. Running a UI:**

   You can run a specific UI using its Docker Compose profile name. The `docker-compose.yml` defines profiles corresponding to the names listed in the table below (e.g., `easy-diffusion`, `automatic`, `comfy-ui`).

   *   **Using Docker Compose:**
      ```bash
      # Example: Run ComfyUI (Profile name: comfy-ui)
      # The service will run in the foreground, showing logs. Press Ctrl+C to stop.
      docker compose --profile comfy-ui up

      # Example: Run ComfyUI detached (in the background)
      docker compose --profile comfy-ui up -d
      ```
      Replace `comfy-ui` with the desired profile name from the table below. Access the UI via `http://<server_ip>:<port>` as listed.

   *   **Using Makefile (Convenience Wrappers):**
      ```bash
      # Example: Start ComfyUI detached
      make start comfy-ui

      # Example: Start ComfyUI attached (shows logs)
      make up comfy-ui

      # Example: Stop ComfyUI
      make stop comfy-ui
      ```
      Replace `comfy-ui` with the desired profile name.

**4. Stopping a UI:**
   *   If running attached (`up`), press `Ctrl+C`.
   *   If running detached (`up -d` or `make start`), use:
      ```bash
      docker compose --profile <profile_name> down
      # or
      make stop <profile_name>
      ```

## Available Projects

| Profile Name    | UI Number | Name              | Description                                                                                                                  | Repository / Website                            | Default Port |
|-----------------|-----------|-------------------|------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|--------------|
| `easy-diffusion`| 01        | Easy Diffusion    | The easiest way to install and use Stable Diffusion on your computer.                                                        | https://github.com/easydiffusion/easydiffusion  | 9001         |
| `automatic`     | 02        | AUTOMATIC1111     | A popular browser interface based on Gradio library for Stable Diffusion.                                                      | https://github.com/AUTOMATIC1111/stable-diffusion-webui | 9002         |
| `forge`         | 02.forge  | Forge             | An optimized fork of AUTOMATIC1111.                                                                                          | https://github.com/lllyasviel/stable-diffusion-webui-forge | 9022         |
| `invoke-ai`     | 03        | InvokeAI          | A leading creative engine for Stable Diffusion models.                                                                       | https://github.com/invoke-ai/InvokeAI           | 9003         |
| `sd-next`       | 04        | SD.Next           | Fork of AUTOMATIC1111 with additional features.                                                                              | https://github.com/vladmandic/automatic         | 9004         |
| `comfy-ui`      | 05        | ComfyUI           | A powerful and modular node-based stable diffusion GUI and backend.                                                          | https://github.com/comfyanonymous/ComfyUI       | 9005         |
| `fooocus`       | 06        | Fooocus           | A rethinking of Stable Diffusion and Midjourney’s designs.                                                                   | https://github.com/lllyasviel/Fooocus           | 9006         |
| `swarmui`       | 07        | SwarmUI           | A Modular Stable Diffusion Web-User-Interface with emphasis on powertools, performance, and extensibility.                   | https://github.com/mcmonkeyprojects/SwarmUI     | 9007         |
| `iopaint`       | 50        | IOPaint           | A free and open-source inpainting tool powered by SOTA AI models. (Formerly Lama Cleaner)                                    | https://github.com/Sanster/IOPaint              | 9050         |
| `face-fusion`   | 51        | FaceFusion        | Next generation face swapper and enhancer.                                                                                   | https://github.com/facefusion/facefusion        | 9051         |
| `kohya`         | 70        | Kohya_ss GUI      | Gradio GUI for Kohya's Stable Diffusion trainers.                                                                            | https://github.com/bmaltais/kohya_ss            | 9070         |
| `fluxgym`       | 71        | Fluxgym           | Web UI for training FLUX LoRA with low VRAM support.                                                                         | https://github.com/cocktailpeanut/fluxgym       | 9071         |
| `onetrainer`    | 72        | OneTrainer        | A one-stop solution for Stable Diffusion training needs.                                                                     | https://github.com/Nerogar/OneTrainer           | 9072         |

## Configuration

### Launch Parameters

Each UI script (`01.sh`, `02.sh`, etc.) reads command-line arguments from a corresponding text file within the `/config` volume mount (defaulting to `./data/stable-diffusion/<UI_NUMBER>/`).
*   Most UIs use `parameters.txt` (e.g., `./data/stable-diffusion/02-sd-webui/parameters.txt`).
*   InvokeAI (`03`) uses `config.yaml`.
*   Forge (`02.forge`) uses `parameters.forge.txt`.

These files allow you to customize how each UI is launched (e.g., adding `--listen`, `--share`, `--lowvram`, specific model paths if needed, etc.). Edit the relevant file in your mapped host directory (`./data/stable-diffusion/<UI_NUMBER>/`) to change the launch options. Lines starting with `#` are ignored.

### Environment Variables (in `docker-compose.yml`)

*   `WEBUI_VERSION`: **Required** when *not* using profiles. Specifies which UI script to run (e.g., `01`, `02`, `05`). This is automatically set when using profiles.
*   `NVIDIA_VISIBLE_DEVICES`: Controls which GPU(s) the container can access (default: `all`).
*   `UI_BRANCH`: (Optional) Specify a specific Git branch to clone/update for repository-based UIs (default: `master` or the UI's default).
*   `CLEAN_ENV`: (Optional, default: `false`) If set to `true`, the `check_remote` function (if used by a script, currently deprecated) might attempt to clean the environment if the remote Git branch is ahead. **Note:** The primary cleaning mechanism is now the marker file described below.

### Cleaning Environments

To force a clean of a specific UI's Conda environment on the next startup, **delete** the marker file named `Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch` located in the root of your mapped config volume (`./data/stable-diffusion/` by default).

The `entry.sh` script checks for the *absence* of this file. If it's missing, it sets the `active_clean=1` variable, which triggers the `clean_env` function within the individual UI scripts (`XX.sh`) when they are sourced. The `entry.sh` script then recreates the marker file.

### Resetting Access Rights

If you encounter permission issues within the mapped `/config` volume, you can trigger a recursive `chown` and `chmod` operation on the next container start. **Delete** the marker file named `Delete_this_file_to_reset_access_rights_at_next_launch` located in the root of your mapped config volume (`./data/stable-diffusion/` by default). This functionality relies on the s6-overlay setup within the Docker image (`docker/root/etc/s6-overlay/s6-rc.d/init-chown`).

### Adding Custom Python Packages

For most UIs, you can add extra Python packages by creating a `requirements.txt` file inside the UI's specific directory within the mapped volume (e.g., `./data/stable-diffusion/05-ComfyUI/requirements.txt`). The corresponding `XX.sh` script will attempt to install packages listed in this file using `pip install -r`.

### Adding Custom UIs/Scripts

A sample script `custom-sample.sh` is copied into `./data/stable-diffusion/scripts/` (if it doesn't exist). You can use this as a template to integrate your own tools or UIs. You would need to:
1.  Copy and rename `custom-sample.sh` (e.g., to `my-custom-ui.sh`).
2.  Modify the script to install and run your desired application, potentially using functions from `/functions.sh`.
3.  Define a new service and profile in `docker-compose.yml` that sets `WEBUI_VERSION=my-custom-ui` (or whatever you named the script without the `.sh`).

## Directory Structure (Inside Mapped Volume - e.g., `./data/stable-diffusion`)

```
./data/stable-diffusion/
├── 01-easy-diffusion/      # Config, env, logs, etc. for Easy Diffusion
│   ├── conda-env/
│   ├── models/ -> ../models/stable-diffusion (symlink)
│   ├── config.yaml
│   └── ...
├── 02-sd-webui/            # Config, env, logs, etc. for AUTOMATIC1111/Forge
│   ├── conda-env/
│   ├── stable-diffusion-webui/ # A1111 Repo clone
│   │   ├── models/ -> ../../models/stable-diffusion (symlink)
│   │   └── outputs/ -> ../../outputs/02-sd-webui (symlink)
│   ├── forge/                # Forge Repo clone
│   │   ├── models/ -> ../../models/stable-diffusion (symlink)
│   │   └── outputs/ -> ../../outputs/02-sd-webui (symlink)
│   ├── parameters.txt
│   └── parameters.forge.txt
├── 03-invokeai/            # Config, env, logs, etc. for InvokeAI
│   ├── env/
│   ├── invokeai/             # InvokeAI root directory (contains models, outputs internally)
│   └── config.yaml
├── ...                     # Directories for other UIs (04, 05, 06, 07, 50, 51, 70, 71, 72)
├── models/                 # SHARED models directory
│   ├── stable-diffusion/
│   ├── lora/
│   ├── vae/
│   ├── embeddings/
│   ├── hypernetwork/
│   ├── upscale/
│   ├── controlnet/
│   ├── clip_vision/
│   ├── blip/
│   ├── codeformer/
│   ├── gfpgan/
│   ├── ldsr/
│   ├── kohya/              # Symlinked into 70-kohya/kohya_ss/models
│   ├── fluxgym/            # Symlinked into 71-fluxgym/fluxgym/models
│   └── onetrainer/         # Symlinked into 72-onetrainer/OneTrainer/models
├── outputs/                # SHARED base output directory
│   ├── 01-Easy-Diffusion/  # Symlinked from 01-easy-diffusion
│   ├── 02-sd-webui/        # Symlinked from 02-sd-webui/stable-diffusion-webui and 02-sd-webui/forge
│   ├── 03-InvokeAI/        # Created by 03.sh, used internally by InvokeAI
│   ├── ...                 # Output directories for other UIs
├── scripts/                # Location for custom user scripts
│   └── custom-sample.sh
├── sd-webui.log            # Main log file from functions.sh
├── Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch # Marker file
└── Delete_this_file_to_reset_access_rights_at_next_launch          # Marker file
```

## Core Scripts

*   `entry.sh`: The main Docker entry point. Sets `active_clean`, sources the selected `XX.sh` script based on `WEBUI_VERSION`.
*   `functions.sh`: Contains shared bash functions used by the `XX.sh` scripts (logging, symlinking folders, managing git repos, installing requirements, cleaning envs).
*   `XX.sh` (e.g., `01.sh`, `02.sh`): Specific setup and launch script for each individual UI. Responsible for environment creation, dependency installation, symlinking, and running the final application.

## History

See [**CHANGELOG.md**](CHANGELOG.md)

## Support

*   **Container Support:** [Unraid Forum Thread](https://forums.unraid.net/topic/143645-support-stable-diffusion-advanced/)
*   **WebUI Support:** Please refer to the respective project's GitHub page or community channels (linked in the table above).

## Troubleshooting

*   **UI Fails to Launch:** Check the container logs (`docker logs <container_name>` or view in Docker Desktop/Portainer). Common issues include incorrect parameters, missing dependencies, or problems cloning repositories.
*   **Environment Issues:** Try cleaning the environment by deleting the `Delete_this_file_to_clean...` marker file and restarting the container.
*   **Permission Errors:** Try resetting permissions by deleting the `Delete_this_file_to_reset...` marker file and restarting the container.
*   **Model/Symlink Issues:** Verify that the `sl_folder` commands in the relevant `XX.sh` script are correct and that the target models exist in the shared `./data/stable-diffusion/models` directory.
