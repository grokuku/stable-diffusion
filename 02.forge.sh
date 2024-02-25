#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"

export use_venv=1

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gcc gxx libcurand --solver=libmamba -y



if [ ! -d ${SD02_DIR}/forge ]; then
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git ${SD02_DIR}/forge
fi

cd ${SD02_DIR}/forge

if [ -d "${SD02_DIR}/python-venv" ]; then
    # check if remote is ahead of local
    # https://stackoverflow.com/a/25109122/1469797
    if [ "$CLEAN_ENV" != "true" ] && [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
    sed 's/\// /g') | cut -f1) ]; then
         echo "Local branch up-to-date, keeping existing venv"
      else
        if [ "$CLEAN_ENV" = "true" ]; then
          echo "Forced wiping venv for clean packages install"
        else
          echo "Remote branch is ahead. Wiping venv for clean packages install"
        fi
        rm -rf ${SD02_DIR}/python-venv
        git pull -X ours
    fi
fi

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Create venv
if [ ! -d ${SD02_DIR}/python-venv ]; then
    cd ${SD02_DIR}
    python -m venv python-venv
    cd ${SD02_DIR}
    source python-venv/bin/activate
    pip install --upgrade pip
    pip install packaging
    pip install onnxruntime-gpu
    pip install insightface 
    pip install protobuf==3.20.3
    deactivate
fi

# Merge Models, vae, lora, and hypernetworks, and outputs
# Ignore move errors if they occur
sl_folder ${SD02_DIR}/forge/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/forge/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/forge/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/forge/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/forge embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/forge/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/forge/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/forge/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/forge/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/forge/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/forge/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/forge outputs ${BASE_DIR}/outputs 02-sd-webui

echo "Run Stable-Diffusion-WebUI-forge"
cd ${SD02_DIR}
source python-venv/bin/activate
export PATH="/config/02-sd-webui/forge/python-venv/lib/python3.11/site-packages/onnxruntime/capi:$PATH"
pip install --upgrade pip

CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD
