#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD07_DIR=${BASE_DIR}/07-SwarmUI

mkdir -p ${SD07_DIR}
mkdir -p /config/outputs/07-SwarmUI

#remove old venv if still exists
if [ -d ${SD07_DIR}/venv ]; then
    rm -rf ${SD07_DIR}/venv
fi

#copy default parameters if missing
if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

#clone repository if new install
if [ ! -d ${SD07_DIR}/SwarmUI ]; then
    cd "${SD07_DIR}" && git clone https://github.com/mcmonkeyprojects/SwarmUI.git
fi

# check if remote is ahead of local
cd ${SD07_DIR}/SwarmUI
check_remote

#clean conda env if needed
clean_env ${SD07_DIR}/env

#create env if missing
if [ ! -d ${SD07_DIR}/env ]; then
    conda create -p ${SD07_DIR}/env -y
fi

#activate env and install packages
source activate ${SD07_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

#move models to common folder and create symlinks
mkdir -p ${SD07_DIR}/SwarmUI/Models

sl_folder ${SD07_DIR}/SwarmUI/Models Stable-Diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/SwarmUI/Models Lora ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/SwarmUI/Models VAE ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/SwarmUI/Models Embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/SwarmUI/Models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD07_DIR}/SwarmUI/Models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD07_DIR}/SwarmUI Output ${BASE_DIR}/outputs 07-SwarmUI

# install dependencies
pip install --upgrade pip

if [ -f ${SD07_DIR}/requirements.txt ]; then
    pip install -r ${SD07_DIR}/requirements.txt
fi

#launch SwarmUI
cd ${SD07_DIR}/SwarmUI
CMD="./launch-linux.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
eval $CMD
wait 99999
