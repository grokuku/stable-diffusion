#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export use_venv=0
export SD03_DIR=${BASE_DIR}/03-invokeai
export INVOKEAI_ROOT=${SD03_DIR}/invokeai

mkdir -p "$SD03_DIR"
mkdir -p /config/outputs/03-InvokeAI

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
    pip install "InvokeAI" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu121
#    invokeai-configure --yes --root ${SD03_DIR}/invokeai
fi

# Update if the folder is present
pip install --use-pep517 --upgrade InvokeAI
#invokeai-configure --yes --root ${SD03_DIR}/invokeai --skip-sd-weights

# Merge Models, vae, lora, hypernetworks, and outputs
sl_folder ${SD03_DIR}/invokeai/models/any embedding ${BASE_DIR}/models embeddings
sl_folder ${SD03_DIR}/invokeai/models/any clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD03_DIR}/invokeai/models/any lora ${BASE_DIR}/models lora
sl_folder ${SD03_DIR}/invokeai/models/any controlnet ${BASE_DIR}/models controlnet
sl_folder ${SD03_DIR}/invokeai/models/any vae ${BASE_DIR}/models vae

sl_folder ${SD03_DIR}/invokeai outputs ${BASE_DIR}/outputs 03-InvokeAI

# launch WebUI
invokeai-web --config ${SD03_DIR}/config.yaml
wait 99999