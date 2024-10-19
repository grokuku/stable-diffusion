#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

# clone repository
if [ ! -d ${SD02_DIR}/webui ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git ${SD02_DIR}/webui
fi


# check if remote is ahead of local
cd ${SD02_DIR}/webui
check_remote

#clean conda env
clean_env ${SD02_DIR}/conda-env

# create conda env if needed
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

# activate conda env and install base tools
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip gcc gxx libcurand --solver=libmamba -y

#copy default parameters if absent
if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# install custom requirements
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
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
sl_folder ${SD02_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/webui outputs ${BASE_DIR}/outputs 02-sd-webui

# run webUI
echo "Run Stable-Diffusion-WebUI"
cd ${SD02_DIR}/webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD
sleep infinity