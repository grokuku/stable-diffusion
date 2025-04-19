#!/bin/bash
# Description: This script installs and runs Automatic1111 Stable Diffusion WebUI.
# Functionalities:
#   - Sets up the environment for Automatic1111 Stable Diffusion WebUI.
#   - Clones the Automatic1111 Stable Diffusion WebUI repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs Automatic1111 Stable Diffusion WebUI.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Automatic1111 Stable Diffusion WebUI is cloned from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR, which should be defined before running the script.
#   - The script clones the Automatic1111 Stable Diffusion WebUI from GitHub. Ensure that the repository is accessible and up-to-date.
#   - The script creates a conda environment with Python 3.11. This version should be compatible with Automatic1111 Stable Diffusion WebUI.
#   - The script installs custom requirements from a requirements.txt file. Ensure that this file exists and contains the necessary dependencies.
#   - The script creates symbolic links for models and outputs. This can save disk space but may cause issues if the source files are modified or deleted.
#   - The script reads parameters from a parameters.txt file. Ensure that this file exists and contains the correct parameters.
#   - The script uses log_message function for logging. Ensure that this function is defined in /functions.sh.
#   - The script runs Automatic1111 Stable Diffusion WebUI in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

log_message "INFO" "Starting Automatic1111 installation and setup"

# Disable the use of a python venv
export venv_dir="-"

mkdir -p ${SD02_DIR}
show_system_info

# Install and update Automatic1111
if ! manage_git_repo "Automatic1111" \
    "https://github.com/AUTOMATIC1111/stable-diffusion-webui" \
    "${SD02_DIR}/stable-diffusion-webui"; then
    log_message "CRITICAL" "Failed to manage Automatic1111 repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD02_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Install custom requirements
log_message "INFO" "Installing Python requirements"
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/stable-diffusion-webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/stable-diffusion-webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/stable-diffusion-webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/stable-diffusion-webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/stable-diffusion-webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/stable-diffusion-webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/stable-diffusion-webui outputs ${BASE_DIR}/outputs 02-sd-webui

# Force using correct version of Python
export python_cmd="$(which python)"

# Run WebUI
log_message "INFO" "Launching Automatic1111 WebUI"
cd ${SD02_DIR}/stable-diffusion-webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
