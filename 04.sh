#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export use_venv=1

# Clean if venv is present
if [ -d "${SD04_DIR}/webui/venv" ]; then
    rm -rf ${SD04_DIR}/webui/venv
fi

echo "Install and run SD-Next"

mkdir -p ${SD04_DIR}

if [ ! -d ${SD04_DIR}/env ]; then
    conda create -p ${SD04_DIR}/env -y
fi

source activate ${SD04_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx libcurand gcc gxx onnx --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

if [ ! -d ${SD04_DIR}/webui ]; then
    git clone https://github.com/vladmandic/automatic ${SD04_DIR}/webui
fi

cd ${SD04_DIR}/webui
git pull -X ours

if [ ! -f "$SD04_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/04.txt" "$SD04_DIR/parameters.txt"
fi
# Load updated malloc to fix memory leak
# https://github.com/AUTOMATIC1111/stable-diffusion-webui/issues/6850#issuecomment-1432435503
if [ ! -f "$SD04_DIR/webui/webui-user.sh" ]; then
cat >"$SD04_DIR/webui/webui-user.sh" <<EOL
export LD_PRELOAD=libtcmalloc.so
echo "libtcmalloc loaded"
EOL
fi

# Create venv
if [ ! -d ${SD04_DIR}/webui/venv ]; then
    echo "Activating venv"
    cd ${SD04_DIR}/webui
    python -m venv venv
    cd ${SD04_DIR}/webui
    source venv/bin/activate
    pip install --upgrade pip
    pip install onnxruntime-gpu
    pip install insightface
    pip install protobuf==3.20.3
    deactivate
fi

# Merge Models, vae, lora, hypernetworks, and outputs
sl_folder ${SD04_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD04_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD04_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD04_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD04_DIR}/webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD04_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD04_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD04_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD04_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD04_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD04_DIR}/webui outputs /config/outputs 04-SD-Next

cd ${SD04_DIR}/webui/
source venv/bin/activate
export PATH="/config/04-SD-Next/env/lib/python3.11/site-packages/onnxruntime/capi:$PATH"

pip install typing-extensions==4.8.0 numpy==1.24.4 huggingface_hub==0.18.0 sqlalchemy --upgrade
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD04_DIR}/parameters.txt"
eval $CMD
