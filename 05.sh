#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD05_DIR=${BASE_DIR}/05-comfy-ui

echo "Install and run Comfy-UI"
mkdir -p ${SD05_DIR}
mkdir -p /config/outputs/05-comfy-ui

if [ ! -d ${SD05_DIR}/env ]; then
    conda create -p ${SD05_DIR}/env -y
fi

source activate ${SD05_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx libcurand --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y
pip install onnxruntime-gpu
pip install insightface torch torchvision

if [ ! -f "$SD05_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/05.txt" "$SD05_DIR/parameters.txt"
fi

if [ ! -d ${SD05_DIR}/ComfyUI ]; then
    git clone https://github.com/comfyanonymous/ComfyUI ${SD05_DIR}/ComfyUI
fi

if [ ! -d ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager
fi

cd ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager
git pull -X ours

cd ${SD05_DIR}/ComfyUI
git pull -X ours

# Merge Models, vae, lora, hypernetworks, and outputs
sl_folder ${SD05_DIR}/ComfyUI/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD05_DIR}/ComfyUI/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD05_DIR}/ComfyUI/models loras ${BASE_DIR}/models lora
sl_folder ${SD05_DIR}/ComfyUI/models vae ${BASE_DIR}/models vae
sl_folder ${SD05_DIR}/ComfyUI/models vae_approx ${BASE_DIR}/models vae_approx
sl_folder ${SD05_DIR}/ComfyUI/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD05_DIR}/ComfyUI/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD05_DIR}/ComfyUI/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD05_DIR}/ComfyUI/models clip ${BASE_DIR}/models clip
sl_folder ${SD05_DIR}/ComfyUI/models controlnet ${BASE_DIR}/models controlnet

if [ -d ${SD05_DIR}/venv ]; then
    rm -rf ${SD05_DIR}/venv
fi

cd ${SD05_DIR}/ComfyUI
pip install -r requirements.txt

CMD="python3 main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD05_DIR}/parameters.txt"
eval $CMD
