#!/bin/bash
# Description: This script installs and runs Fooocus.
# Functionalities:
#   - Sets up the environment for Fooocus.
#   - Clones the Fooocus repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs Fooocus.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Fooocus is cloned from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR and SD_INSTALL_DIR, which should be defined before running the script.
#   - The script clones the Fooocus from GitHub. Ensure that the repository is accessible and up-to-date.
#   - The script creates a conda environment with Python 3.10. This version should be compatible with Fooocus.
#   - The script creates symbolic links for models and outputs. This can save disk space but may cause issues if the source files are modified or deleted.
#   - The script reads parameters from a parameters.txt file. Ensure that this file exists and contains the correct parameters.
#   - The script installs cuda-cudart from the nvidia channel. This is necessary for running Fooocus with CUDA support.
#   - The script installs requirements from requirements_versions.txt. This file should contain specific versions of the required packages.
#   - The script runs Fooocus in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
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
