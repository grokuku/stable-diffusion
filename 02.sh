#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export active_clean=0

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c git python=3.11 pip --solver=libmamba -y

if [ ! -d ${SD02_DIR}/webui ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ${SD02_DIR}/webui
fi

cd ${SD02_DIR}/webui

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
    source activate ${SD02_DIR}/conda-env
    echo "Done!"
    echo -e "-------------------------------------\n"
fi
conda install -c conda-forge git python=3.11 pip gcc gxx libcurand --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

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
sl_folder ${SD02_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/webui outputs ${BASE_DIR}/outputs 02-sd-webui

echo "Run Stable-Diffusion-WebUI"
cd ${SD02_DIR}/webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD
