#!/bin/bash
# Description: Installs and runs the OneTrainer training UI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD72_DIR).
#   - Creates the main directory for this UI (`$SD72_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the OneTrainer repository (`Nerogar/OneTrainer`) into `$SD72_DIR/OneTrainer` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD72_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, and git using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/72.txt` to `$SD72_DIR/parameters.txt` if it doesn't exist.
#   - Uses `sl_folder` to create symbolic links for the `models` directory and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs OneTrainer's main requirements from `$SD72_DIR/OneTrainer/requirements.txt`.
#   - Installs additional Python requirements from `$SD72_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`python main.py`) by appending parameters read from `$SD72_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10) for environment management.
#   - Leverages `manage_git_repo` for handling the OneTrainer source code repository.
#   - Uses symbolic links (`sl_folder`) for models and outputs.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD72_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD72_DIR/requirements.txt`.
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
