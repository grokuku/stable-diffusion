#!/bin/bash
# Description: Installs and runs the Stable Diffusion WebUI Forge variant.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD02_DIR). Note: SD02_DIR is used, potentially conflicting if 02.sh is also used without cleaning.
#   - Disables the webui's internal venv creation by setting `venv_dir="-`.
#   - Creates the main directory for this UI (`$SD02_DIR`).
#   - Displays system information using `show_system_info`.
#   - Clones or updates the Forge repository (`lllyasviel/stable-diffusion-webui-forge`) into `$SD02_DIR/forge` using `manage_git_repo`.
#   - Conditionally cleans the Conda environment (`$SD02_DIR/conda-env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`conda-env`) if needed.
#   - Activates the Conda environment and installs Python 3.11, pip, gcc, gxx, libcurand using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/02.forge.txt` to `$SD02_DIR/parameters.forge.txt` if it doesn't exist.
#   - Installs additional Python requirements from `$SD02_DIR/requirements.txt` if it exists (Note: This might be intended to be `$SD02_DIR/forge/requirements.txt` or a forge-specific file).
#   - Uses `sl_folder` to create symbolic links for various model types and the main output directory, pointing to shared locations under `$BASE_DIR` but within the `$SD02_DIR/forge` subdirectory.
#   - Explicitly sets `python_cmd` to the path of the python executable within the activated Conda environment.
#   - Constructs the launch command (`bash webui.sh`) by appending parameters read from `$SD02_DIR/parameters.forge.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management. Installs `libcurand` which might be a specific Forge dependency.
#   - Leverages `manage_git_repo` for handling the Forge source code repository.
#   - Uses symbolic links (`sl_folder`) extensively to share models and outputs.
#   - Reads launch parameters from a Forge-specific file (`parameters.forge.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - Shares the `SD02_DIR` and `conda-env` with `02.sh`. Running both without cleaning (`active_clean=1`) might lead to conflicts.
#   - Launch parameters are controlled via `$SD02_DIR/parameters.forge.txt`.
#   - Check the source of `$SD02_DIR/requirements.txt` if used, as it might conflict with Forge's own dependencies.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# Disable the use of a python venv
export venv_dir="-"

# Create necessary directories
mkdir -p ${SD02_DIR}

show_system_info

# Install and update Forge WebUI
if ! manage_git_repo "Forge" \
    "https://github.com/lllyasviel/stable-diffusion-webui-forge" \
    "${SD02_DIR}/forge"; then    # Changed from stable-diffusion-webui to forge to match later references
    exit 1
fi

# Clean conda env
clean_env ${SD02_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate conda env + install base tools
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

# Copy default parameters if they don't exist
if [ ! -f "$SD02_DIR/parameters.forge.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.forge.txt" "$SD02_DIR/parameters.forge.txt"
fi

# Install custom requirements 
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Create symbolic links for models and outputs
sl_folder ${SD02_DIR}/forge/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/forge/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/forge/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/forge/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/forge embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/forge/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/forge/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/forge/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/forge/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/forge/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/forge/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/forge outputs ${BASE_DIR}/outputs 02-sd-webui

# Force using correct version of Python
export python_cmd="$(which python)"

# Run WebUI
echo "Running Stable-Diffusion-WebUI-Forge"
cd ${SD02_DIR}/forge
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.forge.txt"
eval $CMD
sleep infinity
