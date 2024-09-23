#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD06_DIR=${BASE_DIR}/06-Fooocus

mkdir -p ${SD06_DIR}
mkdir -p $BASE_DIR/outputs/06-Fooocus

#remove old venv if still present
if [ -d ${SD06_DIR}/venv ]; then
    rm -rf ${SD06_DIR}/venv
fi

#copy parameters if absent
if [ ! -f "$SD06_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/06.txt" "$SD06_DIR/parameters.txt"
fi

#clone Fooocus repository if new install
if [ ! -d ${SD06_DIR}/Fooocus ]; then
    cd "${SD06_DIR}" && git clone https://github.com/lllyasviel/Fooocus.git
fi

# check if remote is ahead of local
cd ${SD06_DIR}/Fooocus
check_remote

#clean conda env if needed
clean_env ${SD06_DIR}/env

#create env if missing
if [ ! -d ${SD06_DIR}/env ]; then
    conda create -p ${SD06_DIR}/env -y
fi

#activate env and install packages
source activate ${SD06_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

sl_folder ${SD06_DIR}/Fooocus/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD06_DIR}/Fooocus/models loras ${BASE_DIR}/models lora
sl_folder ${SD06_DIR}/Fooocus/models vae ${BASE_DIR}/models vae
sl_folder ${SD06_DIR}/Fooocus/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD06_DIR}/Fooocus/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD06_DIR}/Fooocus/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD06_DIR}/Fooocus/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD06_DIR}/Fooocus/models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD06_DIR}/Fooocus outputs ${BASE_DIR}/outputs 06-Fooocus

#install requirements
cd ${SD06_DIR}/Fooocus
pip install -r requirements_versions.txt
if [ -f ${SD06_DIR}/requirements.txt ]; then
    pip install -r ${SD06_DIR}/requirements.txt
fi

#Launch webUI
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD06_DIR}/parameters.txt"
eval $CMD
sleep infinity