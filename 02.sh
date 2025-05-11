#!/bin/bash
# Description: Installs and runs the AUTOMATIC1111 Stable Diffusion WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD02_DIR).
#   - Disables the webui's internal venv creation by setting `venv_dir="-`.
#   - Creates the main directory for this UI (`$SD02_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the AUTOMATIC1111 repository using `manage_git_repo`.
#   - Conditionally cleans the Conda environment based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.11, pip, gcc, gxx using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/02.txt` to `$SD02_DIR/parameters.txt` if it doesn't exist.
#   - Installs additional Python requirements from `$SD02_DIR/requirements.txt` if it exists.
#   - Uses `sl_folder` to create symbolic links for various model types (Stable Diffusion, Lora, VAE, etc.) and the main output directory, pointing to shared locations under `$BASE_DIR`.
#   - Explicitly sets `python_cmd` to the path of the python executable within the activated Conda environment.
#   - Constructs the launch command (`bash webui.sh`) by appending parameters read from `$SD02_DIR/parameters.txt` (ignoring lines starting with #).
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk if the parameters file can be manipulated.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management, chosen over the webui's built-in venv likely for consistency or specific package needs. Libmamba solver is used.
#   - Installs gcc/gxx, suggesting some dependencies might require compilation.
#   - Leverages `manage_git_repo` for handling the webui's source code repository.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs, saving disk space.
#   - Reads launch parameters from a separate file (`parameters.txt`) for configuration flexibility.
#   - Uses `eval` to execute the final command string. This is convenient but potentially unsafe. A safer approach would be to build a command array.
#   - `sleep infinity` keeps the container alive, but a proper process manager is generally preferred.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Launch parameters are controlled via `$SD02_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD02_DIR/requirements.txt`.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

log_message "INFO" "Starting Automatic1111 installation and setup"

# Disable the use of a python venv
export venv_dir="-"

mkdir -p ${SD02_DIR}
show_system_info

# Install and update Automatic1111
if ! manage_git_repo "Automatic1111" \
    "https://github.com/AUTOMATIC1111/stable-diffusion-webui" \
    "${SD02_DIR}/stable-diffusion-webui"; then
    log_message "CRITICAL" "Failed to manage Automatic1111 repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD02_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Install custom requirements
log_message "INFO" "Installing Python requirements"
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/stable-diffusion-webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/stable-diffusion-webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/stable-diffusion-webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/stable-diffusion-webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/stable-diffusion-webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/stable-diffusion-webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/stable-diffusion-webui outputs ${BASE_DIR}/outputs 02-sd-webui

# Force using correct version of Python
export python_cmd="$(which python)"

# Run WebUI
log_message "INFO" "Launching Automatic1111 WebUI"
cd ${SD02_DIR}/stable-diffusion-webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity
