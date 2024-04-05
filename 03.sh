#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export use_venv=0
export SD03_DIR=${BASE_DIR}/03-invokeai
export INVOKEAI_ROOT=${BASE_DIR}/invokeai

mkdir -p "$SD03_DIR"
mkdir -p /config/outputs/03-InvokeAI

# copy default parameters if absent
if [ ! -f "$SD03_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/03.txt" "$SD03_DIR/parameters.txt"
fi

#clean conda env
clean_env ${SD03_DIR}/env

# create conda env if absent
if [ ! -d ${SD03_DIR}/env ]; then
    conda create -p ${SD03_DIR}/env -y
fi

# activate conda env and install basic tools
source activate ${SD03_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 --solver=libmamba -y
python3 -m pip install --upgrade pip

cd ${SD03_DIR}

# Install if the folder is not present
if [ ! -d "${SD03_DIR}/invokeai" ]; then
    pip install "InvokeAI" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu121
#    invokeai-configure --yes --root ${SD03_DIR}/invokeai
fi

# Update if the folder is present
pip install --use-pep517 --upgrade InvokeAI
#invokeai-configure --yes --root ${SD03_DIR}/invokeai --skip-sd-weights

# launch WebUI
CMD="invokeai-web"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD03_DIR}/parameters.txt"
eval $CMD
wait 99999