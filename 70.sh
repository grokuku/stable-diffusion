#!/bin/bash
# Description: Installs and runs the Kohya_ss GUI for training.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD70_DIR).
#   - Creates the main directory for this UI (`$SD70_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the Kohya_ss repository (`bmaltais/kohya_ss`) into `$SD70_DIR/kohya_ss` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD70_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.10, pip, and git using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/70.txt` to `$SD70_DIR/parameters.txt` if it doesn't exist.
#   - Uses `sl_folder` to create symbolic links for the `models` directory and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Installs PyTorch, Torchvision, and Torchaudio with CUDA 12.1 support from the official PyTorch index.
#   - Installs Kohya's main requirements from `$SD70_DIR/kohya_ss/requirements.txt`.
#   - Installs additional Python requirements from `$SD70_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`python kohya_gui.py`) by appending parameters read from `$SD70_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.10) for environment management.
#   - Leverages `manage_git_repo` for handling the Kohya_ss source code repository.
#   - Installs specific PyTorch versions with CUDA support, crucial for training performance.
#   - Uses symbolic links (`sl_folder`) for models and outputs.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD70_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD70_DIR/requirements.txt`.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
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
