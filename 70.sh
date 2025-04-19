#!/bin/bash
# Description: This script installs and runs Kohya.
# Functionalities:
#   - Sets up the environment for Kohya.
#   - Clones the Kohya repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs Kohya.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Kohya is cloned from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR and SD_INSTALL_DIR, which should be defined before running the script.
#   - The script clones the Kohya from GitHub. Ensure that the repository is accessible and up-to-date.
#   - The script creates a conda environment with Python 3.10. This version should be compatible with Kohya.
#   - The script creates symbolic links for models and outputs. This can save disk space but may cause issues if the source files are modified or deleted.
#   - The script reads parameters from a parameters.txt file. Ensure that this file exists and contains the correct parameters.
#   - The script installs torch, torchvision, and torchaudio from pytorch.org. This is necessary for running Kohya with GPU support.
#   - The script runs Kohya in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD70_DIR=${BASE_DIR}/70-kohya

log_message "INFO" "Starting Kohya installation and setup"

mkdir -p ${SD70_DIR}
show_system_info

# Install and update Kohya
if ! manage_git_repo "Kohya" \
    "https://github.com/bmaltais/kohya_ss" \
    "${SD70_DIR}/kohya_ss"; then
    log_message "CRITICAL" "Failed to manage Kohya repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD70_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD70_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD70_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD70_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip git --solver=libmamba -y

if [ ! -f "$SD70_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/70.txt" "$SD70_DIR/parameters.txt"
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD70_DIR}/kohya_ss/models models ${BASE_DIR}/models kohya

sl_folder ${SD70_DIR}/kohya_ss outputs ${BASE_DIR}/outputs 70-kohya

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD70_DIR}/kohya_ss
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt
if [ -f ${SD70_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD70_DIR}/requirements.txt
fi

# Run WebUI
log_message "INFO" "Launching Kohya WebUI"
cd ${SD70_DIR}/kohya_ss
CMD="python kohya_gui.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD70_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
