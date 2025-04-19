#!/bin/bash
# Description: This script installs and runs InvokeAI.
# Functionalities:
#   - Sets up the environment for InvokeAI.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages, including InvokeAI.
#   - Configures InvokeAI.
#   - Launches the InvokeAI web interface.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Pip is used to install InvokeAI and its dependencies.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR, SD_INSTALL_DIR, and UI_BRANCH, which should be defined before running the script.
#   - The script creates a conda environment with Python 3.11. This version should be compatible with InvokeAI.
#   - The script installs InvokeAI from pip, using the --use-pep517 flag. This flag is recommended for installing packages that use the modern build system.
#   - The script installs InvokeAI with the xformers extra. This extra provides optimized implementations of certain operations, which can improve performance.
#   - The script installs custom requirements from a requirements.txt file. Ensure that this file exists and contains the necessary dependencies.
#   - The script launches the InvokeAI web interface using the invokeai-web command.
#   - The script runs InvokeAI in an infinite loop using `sleep infinity`. This is likely intended to keep the process running, but it may be better to use a process manager like systemd or supervisord.
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
