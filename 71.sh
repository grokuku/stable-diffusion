#!/bin/bash
# Description: Installs and runs the Fluxgym WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD71_DIR).
#   - Creates the main directory for this UI (`$SD71_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the Fluxgym repository (`cocktailpeanut/fluxgym`) into `$SD71_DIR/fluxgym` using `manage_git_repo`.
#     - Also manages a submodule (`kohya-ss/sd-scripts` on branch `sd3`) specified in the `manage_git_repo` call.
#   - Conditionally cleans the Conda environment (`$SD71_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, and git using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/71.txt` to `$SD71_DIR/parameters.txt` if it doesn't exist.
#   - Uses `sl_folder` to create symbolic links for the `models` directory and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs Fluxgym's main requirements from `$SD71_DIR/fluxgym/requirements.txt`.
#   - Installs additional Python requirements from `$SD71_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`python app.py`) by appending parameters read from `$SD71_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10) for environment management.
#   - Leverages `manage_git_repo` for handling the Fluxgym source code repository and its specified submodule dependency (sd-scripts).
#   - Uses symbolic links (`sl_folder`) for models and outputs.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR`, `SD_INSTALL_DIR`, and optionally `UI_BRANCH` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD71_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD71_DIR/requirements.txt`.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
export SD71_DIR=${BASE_DIR}/71-fluxgym

log_message "INFO" "Starting Fluxgym installation and setup"

mkdir -p ${SD71_DIR}
show_system_info

# Install and update Fluxgym with SD-Scripts dependency
if ! manage_git_repo "Fluxgym" \
    "https://github.com/cocktailpeanut/fluxgym" \
    "${SD71_DIR}/fluxgym" \
    "${UI_BRANCH:-master}" \
    "https://github.com/kohya-ss/sd-scripts:sd3"; then
    log_message "CRITICAL" "Failed to manage Fluxgym repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD71_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD71_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD71_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD71_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip git --solver=libmamba -y

if [ ! -f "$SD71_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/71.txt" "$SD71_DIR/parameters.txt"
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD71_DIR}/fluxgym/models models ${BASE_DIR}/models fluxgym

sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD71_DIR}/fluxgym
pip install -r requirements.txt
if [ -f ${SD71_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD71_DIR}/requirements.txt
fi

# Run WebUI
log_message "INFO" "Launching Fluxgym WebUI"
cd ${SD71_DIR}/fluxgym
CMD="python app.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD71_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
