#!/bin/bash
# Description: Installs and runs the InvokeAI WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD03_DIR, INVOKEAI_ROOT). Sets `use_venv=0`.
#   - Creates the main directory for this UI (`$SD03_DIR`) and a specific output directory (`/config/outputs/03-InvokeAI/tensors`).
#   - Renames an old `parameters.txt` file if it exists, favoring `config.yaml`.
#   - Copies a default configuration from `/opt/sd-install/parameters/03.txt` to `$SD03_DIR/config.yaml` if it doesn't exist.
#   - Conditionally cleans the Conda environment (`$SD03_DIR/env`) based on `active_clean`.
#   - Creates a dedicated Conda environment (`$SD03_DIR/env`) if needed.
#   - Activates the Conda environment, installs Python 3.11, and upgrades pip.
#   - Installs InvokeAI using pip (`InvokeAI[xformers]`) if the `$SD03_DIR/invokeai` directory doesn't exist. The version is determined by `$UI_BRANCH` (defaulting to 'latest'). Includes PyTorch index URL.
#   - Upgrades InvokeAI using pip if the directory already exists.
#   - Installs additional Python requirements from `$SD03_DIR/requirements.txt` if it exists.
#   - Launches the InvokeAI web UI using the `invokeai-web` command, pointing it to the configuration file.
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management.
#   - Installs/upgrades InvokeAI directly via pip, including the performance-enhancing `xformers` extra. Uses `--use-pep517` for modern build systems.
#   - Manages configuration via `$SD03_DIR/config.yaml`, migrating away from an older `parameters.txt`.
#   - Sets `INVOKEAI_ROOT` which InvokeAI uses to find its models, outputs, and configuration internally. Model symlinking (`sl_folder`) is not used here, assuming InvokeAI handles model locations based on its config.
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR`, `SD_INSTALL_DIR`, and optionally `UI_BRANCH` environment variables.
#   - `active_clean` controls environment cleaning.
#   - Configuration is primarily managed through `$SD03_DIR/config.yaml`.
#   - Additional Python dependencies can be added to `$SD03_DIR/requirements.txt`.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export use_venv=0
export SD03_DIR=${BASE_DIR}/03-invokeai
export INVOKEAI_ROOT=${SD03_DIR}/invokeai

mkdir -p "$SD03_DIR"
mkdir -p /config/outputs/03-InvokeAI/tensors

#rename old parameters file
if [ -f "$SD03_DIR/parameters.txt" ]; then
    mv "$SD03_DIR/parameters.txt" "$SD03_DIR/parameters(not_used_anymore).txt"
fi

# copy default parameters if absent
if [ ! -f "$SD03_DIR/config.yaml" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/03.txt" "$SD03_DIR/config.yaml"
fi

#clean conda env
clean_env ${SD03_DIR}/env

# create conda env if absent
if [ ! -d ${SD03_DIR}/env ]; then
    conda create -p ${SD03_DIR}/env -y
fi

# activate conda env and install basic tools
source activate ${SD03_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 --solver=libmamba -y
python3 -m pip install --upgrade pip

cd ${SD03_DIR}

# Install if the folder is not present
if [ ! -d "${SD03_DIR}/invokeai" ]; then
    mkdir -p ${SD03_DIR}/invokeai
    pip install "InvokeAI[xformers]==${UI_BRANCH:-latest}" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu121
#    invokeai-configure --yes --root ${SD03_DIR}/invokeai
fi

# Update if the folder is present
pip install --use-pep517 --upgrade InvokeAI
#invokeai-configure --yes --root ${SD03_DIR}/invokeai --skip-sd-weights

# install custom requirements
pip install --upgrade pip

if [ -f ${SD03_DIR}/requirements.txt ]; then
    pip install -r ${SD03_DIR}/requirements.txt
fi

# launch WebUI
invokeai-web --config ${SD03_DIR}/config.yaml
sleep infinity
