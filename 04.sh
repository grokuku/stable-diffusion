#!/bin/bash
# Description: This script installs and runs SD.Next (Stable Diffusion WebUI).
# Functionalities:
#   - Sets up the environment for SD.Next.
#   - Clones the SD.Next repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs SD.Next.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The SD.Next is cloned from GitHub.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD04_DIR=${BASE_DIR}/04-sd-next

log_message "INFO" "Starting SD.Next installation and setup"

mkdir -p ${SD04_DIR}
show_system_info

# Install and update SD.Next
if ! manage_git_repo "SD.Next" \
    "https://github.com/vladmandic/automatic" \
    "${SD04_DIR}/stable-diffusion-webui"; then
    log_message "CRITICAL" "Failed to manage SD.Next repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD04_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD04_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD04_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD04_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

if [ ! -f "$SD04_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/04.txt" "$SD04_DIR/parameters.txt"
fi

# Install custom requirements
log_message "INFO" "Installing Python requirements"
pip install --upgrade pip

if [ -f ${SD04_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD04_DIR}/requirements.txt
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD04_DIR}/stable-diffusion-webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD04_DIR}/stable-diffusion-webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD04_DIR}/stable-diffusion-webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD04_DIR}/stable-diffusion-webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD04_DIR}/stable-diffusion-webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD04_DIR}/stable-diffusion-webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD04_DIR}/stable-diffusion-webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD04_DIR}/stable-diffusion-webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD04_DIR}/stable-diffusion-webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD04_DIR}/stable-diffusion-webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD04_DIR}/stable-diffusion-webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD04_DIR}/stable-diffusion-webui outputs ${BASE_DIR}/outputs 04-sd-next

# Run WebUI
log_message "INFO" "Launching SD.Next WebUI"
cd ${SD04_DIR}/stable-diffusion-webui
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD04_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
