#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"

mkdir -p ${SD06_DIR}
mkdir -p /config/outputs/06-Fooocus

if [ ! -d ${SD06_DIR}/env ]; then
    conda create -p ${SD06_DIR}/env -y
fi

source activate ${SD06_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

if [ ! -f "$SD06_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/06.txt" "$SD06_DIR/parameters.txt"
fi

if [ ! -d ${SD06_DIR}/Fooocus ]; then
    cd "${SD06_DIR}" && git clone https://github.com/lllyasviel/Fooocus.git
fi

cd ${SD06_DIR}/Fooocus
git pull -X ours

mkdir -p ${SD06_DIR}/StableSwarmUI/models

sl_folder ${SD06_DIR}/Fooocus/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD06_DIR}/Fooocus/models loras ${BASE_DIR}/models lora
sl_folder ${SD06_DIR}/Fooocus/models vae ${BASE_DIR}/models vae
sl_folder ${SD06_DIR}/Fooocus/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD06_DIR}/Fooocus/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD06_DIR}/Fooocus/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD06_DIR}/Fooocus/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD06_DIR}/Fooocus/models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD06_DIR}/Fooocus Output /config/outputs 06-Fooocus

if [ -d ${SD06_DIR}/venv ]; then
    rm -rf ${SD06_DIR}/venv
fi

cd ${SD06_DIR}/Fooocus
pip install -r requirements_versions.txt
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD06_DIR}/parameters.txt"
eval $CMD
