#!/bin/bash
# Description: This script installs and runs ComfyUI.
# Functionalities:
#   - Sets up the environment for ComfyUI.
#   - Clones the ComfyUI repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs ComfyUI.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The ComfyUI is cloned from GitHub.

source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD05_DIR=${BASE_DIR}/05-ComfyUI

log_message "INFO" "Starting ComfyUI installation and setup"

mkdir -p ${SD05_DIR}
mkdir -p $BASE_DIR/outputs/05-ComfyUI

show_system_info

if [ ! -f "$SD05_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/05.txt" "$SD05_DIR/parameters.txt"
fi

# Install and update ComfyUI
if ! manage_git_repo "ComfyUI" \
    "https://github.com/comfyanonymous/ComfyUI.git" \
    "${SD05_DIR}/ComfyUI"; then
    log_message "CRITICAL" "Failed to manage ComfyUI repository. Exiting."
    exit 1
fi

if [ ! -d ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD05_DIR}/env

# Create env if missing
if [ ! -d ${SD05_DIR}/env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD05_DIR}/env -y
fi

# Activate env and install packages
log_message "INFO" "Installing conda packages"
source activate ${SD05_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y

# Install custom nodes dependencies if a clean Venv has been done
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Install Custom Nodes Dependencies"
    install_requirements ${SD05_DIR}/ComfyUI/custom_nodes
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#clean old venv if it still exists
if [ -d ${SD05_DIR}/venv ]; then
    rm -rf ${SD05_DIR}/venv
fi

# Create symbolic links for models
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD05_DIR}/ComfyUI/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD05_DIR}/ComfyUI/models loras ${BASE_DIR}/models lora
sl_folder ${SD05_DIR}/ComfyUI/models vae ${BASE_DIR}/models vae
sl_folder ${SD05_DIR}/ComfyUI/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD05_DIR}/ComfyUI/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD05_DIR}/ComfyUI/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD05_DIR}/ComfyUI/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD05_DIR}/ComfyUI/models controlnet ${BASE_DIR}/models controlnet

# Create symbolic link for outputs
sl_folder ${SD05_DIR}/ComfyUI/output ${BASE_DIR}/outputs 05-ComfyUI

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD05_DIR}/ComfyUI
pip install -r requirements.txt
if [ -f ${SD05_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD05_DIR}/requirements.txt
fi

pip install /wheels/*.whl
pip install plyfile \
    tqdm \
    spconv-cu124 \
    llama-cpp-python \
    logger \
    sageattention
pip install --upgrade diffusers[torch]

# Launch WebUI
log_message "INFO" "Launching ComfyUI WebUI"
CMD="python main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD05_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
