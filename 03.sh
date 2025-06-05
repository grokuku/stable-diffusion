#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD03_DIR=${BASE_DIR}/03-invokeai
export INVOKEAI_ROOT=${SD03_DIR}/invokeai

mkdir -p "$SD03_DIR"
mkdir -p /config/outputs/03-InvokeAI/tensors

# Rename old parameters file for backward compatibility
if [ -f "$SD03_DIR/parameters.txt" ]; then
    mv "$SD03_DIR/parameters.txt" "$SD03_DIR/parameters(not_used_anymore).txt"
fi

# Copy default config file if it doesn't exist
if [ ! -f "$SD03_DIR/config.yaml" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/03.txt" "$SD03_DIR/config.yaml"
fi

# Clean the Conda environment if required
clean_env ${SD03_DIR}/env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD03_DIR}/env ]; then
    conda create -p ${SD03_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD03_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 --solver=libmamba -y
python3 -m pip install --upgrade pip

cd ${SD03_DIR}

# Install InvokeAI if it's not already installed
if [ ! -d "${SD03_DIR}/invokeai" ]; then
    mkdir -p ${SD03_DIR}/invokeai
    pip install "InvokeAI" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu121
fi

# Update InvokeAI on every launch
pip install --use-pep517 --upgrade InvokeAI

# Install custom user requirements if specified
pip install --upgrade pip
if [ -f ${SD03_DIR}/requirements.txt ]; then
    pip install -r ${SD03_DIR}/requirements.txt
fi

# Launch InvokeAI WebUI
invokeai-web --config ${SD03_DIR}/config.yaml
sleep infinity