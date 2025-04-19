#!/bin/bash
# Description: This script installs and runs OneTrainer.
# Functionalities:
#   - Sets up the environment for OneTrainer.
#   - Clones the OneTrainer repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs OneTrainer.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The OneTrainer is cloned from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR and SD_INSTALL_DIR, which should be defined before running the script.
#   - The script clones the OneTrainer from GitHub. Ensure that the repository is accessible and up-to-date.
#   - The script creates a conda environment with Python 3.10. This version should be compatible with OneTrainer.
#   - The script creates symbolic links for models and outputs. This can save disk space but may cause issues if the source files are modified or deleted.
#   - The script reads parameters from a parameters.txt file. Ensure that this file exists and contains the correct parameters.
#   - The script runs OneTrainer in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD72_DIR=${BASE_DIR}/72-onetrainer

log_message "INFO" "Starting OneTrainer installation and setup"

mkdir -p ${SD72_DIR}
show_system_info

# Install and update OneTrainer
if ! manage_git_repo "OneTrainer" \
    "https://github.com/Nerogar/OneTrainer" \
    "${SD72_DIR}/OneTrainer"; then
    log_message "CRITICAL" "Failed to manage OneTrainer repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD72_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD72_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD72_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD72_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip git --solver=libmamba -y

if [ ! -f "$SD72_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/72.txt" "$SD72_DIR/parameters.txt"
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD72_DIR}/OneTrainer/models models ${BASE_DIR}/models onetrainer

sl_folder ${SD72_DIR}/OneTrainer outputs ${BASE_DIR}/outputs 72-onetrainer

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD72_DIR}/OneTrainer
pip install -r requirements.txt
if [ -f ${SD72_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD72_DIR}/requirements.txt
fi

# Run WebUI
log_message "INFO" "Launching OneTrainer WebUI"
cd ${SD72_DIR}/OneTrainer
CMD="python main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD72_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
