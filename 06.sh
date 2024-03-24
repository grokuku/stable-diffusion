#!/bin/bash
source /sl_folder.sh

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
# https://stackoverflow.com/a/25109122/1469797
cd ${SD06_DIR}/Fooocus
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
#    git reset --hard HEAD
    git pull -X ours
fi

#clean conda env if needed
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${SD06_DIR}/env
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

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

#Launch webUI
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD06_DIR}/parameters.txt"
eval $CMD
