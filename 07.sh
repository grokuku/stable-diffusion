#!/bin/bash
source /sl_folder.sh

export PATH="/opt/miniconda3/bin:$PATH"

mkdir -p ${SD07_DIR}
mkdir -p /outputs/07-StableSwarm

if [ ! -d ${SD07_DIR}/env ]; then
    conda create -p ${SD07_DIR}/env -y
fi

source activate ${SD07_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

if [ -d ${SD07_DIR}/venv ]; then
    rm -rf ${SD07_DIR}/venv
fi

if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

if [ ! -d ${SD07_DIR}/StableSwarmUI ]; then
    cd "${SD07_DIR}" && git clone https://github.com/Stability-AI/StableSwarmUI
fi

cd ${SD07_DIR}/StableSwarmUI
git pull -X ours

mkdir -p ${SD07_DIR}/StableSwarmUI/Models

sl_folder ${SD07_DIR}/StableSwarmUI/Models Stable-Diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/StableSwarmUI/Models Lora ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/StableSwarmUI/Models VAE ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/StableSwarmUI/Models Embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/StableSwarmUI/Models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD07_DIR}/StableSwarmUI/Models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD07_DIR}/StableSwarmUI Output /outputs 07-StableSwarm

cd ${SD07_DIR}/StableSwarmUI
CMD="./launch-linux.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
eval $CMD

