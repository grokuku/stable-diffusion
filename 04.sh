#!/bin/bash
# Description: Installs and runs the SD.Next (Vladmandic Automatic) WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD04_DIR).
#   - Creates the main directory for this UI (`$SD04_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the SD.Next repository (`vladmandic/automatic`) into `$SD04_DIR/stable-diffusion-webui` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD04_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.11, pip, gcc, gxx using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/04.txt` to `$SD04_DIR/parameters.txt` if it doesn't exist.
#   - Installs additional Python requirements from `$SD04_DIR/requirements.txt` if it exists.
#   - Uses `sl_folder` to create symbolic links for various model types and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Constructs the launch command (`python launch.py`) by appending parameters read from `$SD04_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management. Installs gcc/gxx for potential compilation needs.
#   - Leverages `manage_git_repo` for handling the SD.Next source code repository.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs.
#   - Reads launch parameters from a separate file (`parameters.txt`) for configuration.
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD04_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD04_DIR/requirements.txt`.
#   - This script structure is very similar to 02.sh (Automatic1111) and 02.forge.sh (Forge).
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
