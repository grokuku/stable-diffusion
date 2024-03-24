#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

if [ ! -d ${SD02_DIR}/forge ]; then
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git ${SD02_DIR}/forge
fi

cd ${SD02_DIR}/forge

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

#clean conda env
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    conda deactivate
    conda remove -p ${SD02_DIR}/conda-env --all -y
    conda create -p ${SD02_DIR}/conda-env -y
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#activate conda env + install base tools
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.forge.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.forge.txt" "$SD02_DIR/parameters.forge.txt"
fi

#install dependencies 
pip install --upgrade pip
pip install coloredlogs flatbuffers numpy packaging protobuf==3.20.3 sympy
pip install packaging
pip install onnxruntime-gpu --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/
pip install insightface
pip install basicsr
pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 --index-url https://download.pytorch.org/whl/cu121
pip install xformers --index-url https://download.pytorch.org/whl/cu121

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

sl_folder ${SD02_DIR}/forge output ${BASE_DIR}/outputs 02-sd-webui

# Run webUI
echo "Run Stable-Diffusion-WebUI-forge"
cd ${SD02_DIR}/forge
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.forge.txt"
eval $CMD
