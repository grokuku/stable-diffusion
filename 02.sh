#!/bin/bash
source /sl_folder.sh

export PATH="/opt/miniconda3/bin:$PATH"

export use_venv=1

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

if [ ! -d ${SD02_DIR}/env ]; then
    conda create -p ${SD02_DIR}/env -y
fi

source activate ${SD02_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gcc gxx libcurand --solver=libmamba -y



if [ ! -d ${SD02_DIR}/webui ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ${SD02_DIR}/webui
fi

cd ${SD02_DIR}/webui
git pull -X ours

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Clean if venv is present
if [ -d "${SD02_DIR}/venv" ]; then
    rm -rf ${SD02_DIR}/venv
fi

# Create venv
if [ ! -d ${SD02_DIR}/webui/venv ]; then
    cd ${SD02_DIR}/webui
    python -m venv venv
    cd ${SD02_DIR}/webui
    source venv/bin/activate
    pip install --upgrade pip
    pip install onnxruntime-gpu
    pip install insightface 
    pip install protobuf==3.20.3
    deactivate
fi

# Merge Models, vae, lora, and hypernetworks, and outputs
# Ignore move errors if they occur
sl_folder ${SD02_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr

sl_folder ${SD02_DIR}/webui outputs /outputs 02-sd-webui

echo "Run Stable-Diffusion-WebUI"
cd ${SD02_DIR}/webui
source venv/bin/activate
export PATH="/opt/stable-diffusion/02-sd-webui/webui/venv/lib/python3.11/site-packages/onnxruntime/capi:$PATH"
pip install --upgrade pip

CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD

