#!/bin/bash
# Description: Installs and runs the SwarmUI WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD07_DIR).
#   - Creates the main directory for this UI (`$SD07_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the SwarmUI repository (`mcmonkeyprojects/SwarmUI.git`) into `$SD07_DIR/SwarmUI` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD07_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, and git using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/07.txt` to `$SD07_DIR/parameters.txt` if it doesn't exist.
#   - Uses `sl_folder` to create symbolic links for various model types and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs SwarmUI's main requirements from `$SD07_DIR/SwarmUI/requirements.txt`.
#   - Installs additional Python requirements from `$SD07_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`python launch.py`) by appending parameters read from `$SD07_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10) for environment management.
#   - Leverages `manage_git_repo` for handling the SwarmUI source code repository.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD07_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD07_DIR/requirements.txt`.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
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
