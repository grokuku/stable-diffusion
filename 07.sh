#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD07_DIR=${BASE_DIR}/07-StableSwarm

mkdir -p ${SD07_DIR}
mkdir -p /config/outputs/07-StableSwarm

#remove old venv if still exists
if [ -d ${SD07_DIR}/venv ]; then
    rm -rf ${SD07_DIR}/venv
fi

#copy default parameters if missing
if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

#clone repository if new install
if [ ! -d ${SD07_DIR}/StableSwarmUI ]; then
    cd "${SD07_DIR}" && git clone https://github.com/Stability-AI/StableSwarmUI.git
fi

# check if remote is ahead of local
# https://stackoverflow.com/a/25109122/1469797
cd ${SD07_DIR}/StableSwarmUI
if [ "$CLEAN_ENV" != "true" ] && [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ]; then
    echo "Local branch up-to-date, keeping existing venv"
    else
        if [ "$CLEAN_ENV" = "true" ]; then
        echo "Forced wiping venv for clean packages install"
        else
        echo "Remote branch is ahead. Wiping venv for clean packages install"
        fi
    export active_clean=1
#    git reset --hard HEAD
    git pull -X ours
fi

#clean conda env if needed
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${SD07_DIR}/env
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#create env if missing
if [ ! -d ${SD07_DIR}/env ]; then
    conda create -p ${SD07_DIR}/env -y
fi

#activate env and install packages
source activate ${SD07_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

#move models to common folder and create symlinks
mkdir -p ${SD07_DIR}/StableSwarmUI/Models

sl_folder ${SD07_DIR}/StableSwarmUI/Models Stable-Diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/StableSwarmUI/Models Lora ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/StableSwarmUI/Models VAE ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/StableSwarmUI/Models Embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/StableSwarmUI/Models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD07_DIR}/StableSwarmUI/Models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD07_DIR}/StableSwarmUI Output ${BASE_DIR}/outputs 07-StableSwarm

#launch Stable Swarm
cd ${SD07_DIR}/StableSwarmUI
CMD="./launch-linux.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
eval $CMD
