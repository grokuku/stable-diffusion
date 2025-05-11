#!/bin/bash
# Description: Installs and runs the ComfyUI WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD05_DIR).
#   - Creates the main directory for this UI (`$SD05_DIR`) and its output directory.
#   - Displays system information using `show_system_info`.
#   - Copies default parameters from `/opt/sd-install/parameters/05.txt` to `$SD05_DIR/parameters.txt` if it doesn't exist.
#   - Clones or updates the ComfyUI repository (`comfyanonymous/ComfyUI`) into `$SD05_DIR/ComfyUI` using `manage_git_repo`.
#   - Clones the ComfyUI-Manager custom node into the `custom_nodes` directory if it doesn't exist.
#   - Conditionally cleans the Conda environment (`$SD05_DIR/env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, and git using libmamba solver.
#   - If `active_clean` was true, installs requirements for custom nodes using `install_requirements` on the `custom_nodes` directory.
#   - Removes an old `venv` directory if it exists (legacy cleanup).
#   - Uses `sl_folder` to create symbolic links for various model types and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs ComfyUI's main requirements from `$SD05_DIR/ComfyUI/requirements.txt`.
#   - Installs additional Python requirements from `$SD05_DIR/requirements.txt` if it exists.
#   - Installs Python wheels found in the `/wheels/` directory within the container.
#   - Installs several specific Python packages via pip (plyfile, tqdm, spconv-cu124, llama-cpp-python, logger, sageattention).
#   - Upgrades the `diffusers[torch]` package.
#   - Constructs the launch command (`python main.py`) by appending parameters read from `$SD05_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10 specifically, likely for ComfyUI compatibility) for environment management.
#   - Leverages `manage_git_repo` for handling the ComfyUI source code repository.
#   - Includes specific handling for the popular ComfyUI-Manager custom node.
#   - Conditionally installs custom node requirements only after cleaning the environment to ensure dependencies are met.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs.
#   - Installs a mix of requirements from files, specific wheels, and direct package names, indicating complex dependency management.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment and custom node requirement installation.
#   - Launch parameters are controlled via `$SD05_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD05_DIR/requirements.txt`.
#   - Assumes necessary `.whl` files are present in `/wheels/` inside the container image.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
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
