#!/bin/bash
# Description: This script installs and runs Easy Diffusion.
# Functionalities:
#   - Sets up the environment for Easy Diffusion.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Downloads and installs the Easy Diffusion UI.
#   - Merges models, VAEs, LoRAs, and hypernetworks.
#   - Copies default parameters.
#   - Runs Easy Diffusion.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Easy Diffusion UI is downloaded from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR and SD_INSTALL_DIR, which should be defined before running the script.
#   - The script installs a specific version of Easy Diffusion (v3.0.2). Consider updating the script to use the latest version.
#   - The script uses symbolic links to merge models, which can save disk space but may cause issues if the source files are modified or deleted.
#   - The script installs the plugin-manager plugin from a raw GitHub URL. Consider using a more reliable method for installing plugins.
#   - The script runs Easy Diffusion in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD01_DIR=${BASE_DIR}/01-easy-diffusion

#clean conda env
clean_env ${SD01_DIR}/conda-env
clean_env ${SD01_DIR}/installer_files

#Create Conda Env
if [ ! -d ${SD01_DIR}/conda-env ]; then
    conda create -p ${SD01_DIR}/conda-env -y
fi

#active env and install python
source activate ${SD01_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c python=3.11 pip --solver=libmamba -y

#create 'models' folders
mkdir -p ${SD01_DIR}/{models,version,plugins/ui,scripts}
cd ${SD01_DIR}

#install manager plugin
if [ ! -f ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js ]; then
    curl -L https://raw.githubusercontent.com/patriceac/Easy-Diffusion-Plugins/main/plugin-manager.plugin.js --output ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js
fi

# Merge Models, vae, lora, hypernetworks, etc.
sl_folder ${SD01_DIR}/models stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD01_DIR}/models hypernetwork ${BASE_DIR}/models hypernetwork
sl_folder ${SD01_DIR}/models lora ${BASE_DIR}/models lora
sl_folder ${SD01_DIR}/models vae ${BASE_DIR}/models vae
sl_folder ${SD01_DIR}/models controlnet ${BASE_DIR}/models controlnet
sl_folder ${SD01_DIR}/models realesrgan ${BASE_DIR}/models upscale
sl_folder ${SD01_DIR}/models codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD01_DIR}/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD01_DIR}/models gfpgan ${BASE_DIR}/models gfpgan

sl_folder ${HOME} "Stable Diffusion UI" ${BASE_DIR}/outputs 01-Easy-Diffusion

#copy default parameters if they don't exists
if [ ! -f "$SD01_DIR/config.yaml" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/01.txt" "$SD01_DIR/config.yaml"
fi

#download installer if it isn't present
if [ ! -f "$SD01_DIR/start.sh" ]; then
    curl -L https://github.com/easydiffusion/easydiffusion/releases/download/v3.0.2/Easy-Diffusion-Linux.zip --output edui.zip
    unzip edui.zip
    cp -rf easy-diffusion/* .
    rm -rf easy-diffusion
    rm -f edui.zip
fi

#run easy-diffusion
cd $SD01_DIR
bash start.sh
sleep infinity
