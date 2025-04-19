#!/bin/bash
# Description: This script installs and runs SwarmUI.
# Functionalities:
#   - Sets up the environment for SwarmUI.
#   - Clones the SwarmUI repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs SwarmUI.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The SwarmUI is cloned from GitHub.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD07_DIR=${BASE_DIR}/07-swarm-ui

log_message "INFO" "Starting SwarmUI installation and setup"

mkdir -p ${SD07_DIR}
show_system_info

# Install and update SwarmUI
if ! manage_git_repo "SwarmUI" \
    "https://github.com/mcmonkeyprojects/SwarmUI.git" \
    "${SD07_DIR}/SwarmUI"; then
    log_message "CRITICAL" "Failed to manage SwarmUI repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD07_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD07_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD07_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD07_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip git --solver=libmamba -y

if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD07_DIR}/SwarmUI/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/SwarmUI/models loras ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/SwarmUI/models vae ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/SwarmUI/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/SwarmUI/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD07_DIR}/SwarmUI/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD07_DIR}/SwarmUI/models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD07_DIR}/SwarmUI outputs ${BASE_DIR}/outputs 07-swarm-ui

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD07_DIR}/SwarmUI
pip install -r requirements.txt
if [ -f ${SD07_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD07_DIR}/requirements.txt
fi

# Run WebUI
log_message "INFO" "Launching SwarmUI WebUI"
cd ${SD07_DIR}/SwarmUI
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
