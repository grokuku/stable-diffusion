#!/bin/bash
# Description: This script installs and runs Stable Diffusion WebUI Forge.
# Functionalities:
#   - Sets up the environment for Stable Diffusion WebUI Forge.
#   - Clones the Stable Diffusion WebUI Forge repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs Stable Diffusion WebUI Forge.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Stable Diffusion WebUI Forge is cloned from GitHub.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# Disable the use of a python venv
export venv_dir="-"

# Create necessary directories
mkdir -p ${SD02_DIR}

show_system_info

# Install and update Forge WebUI
if ! manage_git_repo "Forge" \
    "https://github.com/lllyasviel/stable-diffusion-webui-forge" \
    "${SD02_DIR}/forge"; then    # Changed from stable-diffusion-webui to forge to match later references
    exit 1
fi

# Clean conda env
clean_env ${SD02_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate conda env + install base tools
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

# Copy default parameters if they don't exist
if [ ! -f "$SD02_DIR/parameters.forge.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.forge.txt" "$SD02_DIR/parameters.forge.txt"
fi

# Install custom requirements 
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Create symbolic links for models and outputs
sl_folder ${SD02_DIR}/forge/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/forge/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/forge/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/forge/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/forge embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/forge/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/forge/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/forge/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/forge/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/forge/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/forge/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/forge outputs ${BASE_DIR}/outputs 02-sd-webui

# Force using correct version of Python
export python_cmd="$(which python)"

# Run WebUI
echo "Running Stable-Diffusion-WebUI-Forge"
cd ${SD02_DIR}/forge
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.forge.txt"
eval $CMD
sleep infinity
