#!/bin/bash
# Description: Installs and runs the Fooocus WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD06_DIR).
#   - Creates the main directory for this UI (`$SD06_DIR`) and its output directory.
#   - Displays system information using `show_system_info`.
#   - Removes an old `venv` directory if it exists (legacy cleanup).
#   - Copies default parameters from `/opt/sd-install/parameters/06.txt` to `$SD06_DIR/parameters.txt` if it doesn't exist.
#   - Clones or updates the Fooocus repository (`lllyasviel/Fooocus`) into `$SD06_DIR/Fooocus` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD06_DIR/env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, git, and cuda-cudart (from nvidia channel) using libmamba solver.
#   - Uses `sl_folder` to create symbolic links for various model types and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs Fooocus's main requirements from `$SD06_DIR/Fooocus/requirements_versions.txt`.
#   - Installs additional Python requirements from `$SD06_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`python launch.py`) by appending parameters read from `$SD06_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10) for environment management. Installs `cuda-cudart` specifically, indicating a CUDA dependency for Fooocus.
#   - Leverages `manage_git_repo` for handling the Fooocus source code repository.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs.
#   - Installs requirements from `requirements_versions.txt`, suggesting Fooocus pins specific dependency versions.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD06_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD06_DIR/requirements.txt`.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD06_DIR=${BASE_DIR}/06-Fooocus

log_message "INFO" "Starting Fooocus installation and setup"

mkdir -p ${SD06_DIR}
mkdir -p $BASE_DIR/outputs/06-Fooocus

show_system_info

# Remove old venv if still present
if [ -d ${SD06_DIR}/venv ]; then
    log_message "INFO" "Removing old virtual environment"
    rm -rf ${SD06_DIR}/venv
fi

# Copy parameters if absent
if [ ! -f "$SD06_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "${SD_INSTALL_DIR}/parameters/06.txt" "$SD06_DIR/parameters.txt"
fi

# Install and update Fooocus
if ! manage_git_repo "Fooocus" \
    "https://github.com/lllyasviel/Fooocus.git" \
    "${SD06_DIR}/Fooocus"; then
    log_message "CRITICAL" "Failed to manage Fooocus repository. Exiting."
    exit 1
fi

# Clean conda env if needed
log_message "INFO" "Cleaning conda environment"
clean_env ${SD06_DIR}/env

# Create env if missing
if [ ! -d ${SD06_DIR}/env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD06_DIR}/env -y
fi

# Activate env and install packages
log_message "INFO" "Installing conda packages"
source activate ${SD06_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

# Create symbolic links for models
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD06_DIR}/Fooocus/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD06_DIR}/Fooocus/models loras ${BASE_DIR}/models lora
sl_folder ${SD06_DIR}/Fooocus/models vae ${BASE_DIR}/models vae
sl_folder ${SD06_DIR}/Fooocus/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD06_DIR}/Fooocus/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD06_DIR}/Fooocus/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD06_DIR}/Fooocus/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD06_DIR}/Fooocus/models controlnet ${BASE_DIR}/models controlnet

# Create symbolic link for outputs
sl_folder ${SD06_DIR}/Fooocus outputs ${BASE_DIR}/outputs 06-Fooocus

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD06_DIR}/Fooocus
pip install -r requirements_versions.txt
if [ -f ${SD06_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD06_DIR}/requirements.txt
fi

# Launch WebUI
log_message "INFO" "Launching Fooocus WebUI"
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD06_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
