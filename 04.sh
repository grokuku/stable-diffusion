#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD04_DIR=${BASE_DIR}/04-SD-Next
export use_venv=1

echo "Install and run SD-Next"

mkdir -p ${SD04_DIR}

#clone main repository
if [ ! -d ${SD04_DIR}/webui ]; then
    git clone https://github.com/vladmandic/automatic ${SD04_DIR}/webui
fi

cd ${SD04_DIR}/webui

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
  export active_clean=1
  git pull -X ours
fi

#clean virtual env
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${SD04_DIR}/env
    rm -rf ${SD04_DIR}/webui/venv
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#create conda env if needed
if [ ! -d ${SD04_DIR}/env ]; then
    conda create -p ${SD04_DIR}/env -y
fi

#activate and install basic tools
source activate ${SD04_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

# Create venv
if [ ! -d ${SD04_DIR}/webui/venv ]; then
    echo "create venv"
    cd ${SD04_DIR}/webui
    python -m venv venv
fi

# install dependencies
    cd ${SD04_DIR}/webui
    source venv/bin/activate
    pip install --upgrade pip
    pip install coloredlogs flatbuffers numpy packaging protobuf==3.20.3 sympy
    pip install packaging
    pip install onnxruntime-gpu --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/
    pip install insightface
    pip install basicsr
    pip install xformers --index-url https://download.pytorch.org/whl/cu121
    pip install onnxruntime-gpu
    pip install insightface
    pip install protobuf==3.20.3
    pip install sqlalchemy
    deactivate

#copy default parameters if absent
if [ ! -f "$SD04_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/04.txt" "$SD04_DIR/parameters.txt"
fi

# Merge Models, vae, lora, hypernetworks, and outputs
sl_folder ${SD04_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD04_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD04_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD04_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD04_DIR}/webui/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD04_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD04_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD04_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD04_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD04_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD04_DIR}/webui outputs ${BASE_DIR}/outputs 04-SD-Next

cd ${SD04_DIR}/webui/

#Launch WebUI
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD04_DIR}/parameters.txt"
eval $CMD
