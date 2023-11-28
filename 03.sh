#!/bin/bash
source /sl_folder.sh

export PATH="/opt/miniconda3/bin:$PATH"
export use_venv=0

mkdir -p "$SD03_DIR"
mkdir -p /outputs/03-InvokeAI

if [ ! -f "$SD03_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/03.txt" "$SD03_DIR/parameters.txt"
fi

if [ ! -d ${SD03_DIR}/env ]; then
    conda create -p ${SD03_DIR}/env -y
fi

source activate ${SD03_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 --solver=libmamba -y

cd ${SD03_DIR}

# Install if the folder is not present
if [ ! -d "${SD03_DIR}/invokeai" ]; then
    pip install "InvokeAI[xformers]" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu118
    invokeai-configure --yes --root ${SD03_DIR}/invokeai
fi

# Update if the folder is present
pip install --use-pep517 --upgrade InvokeAI
invokeai-configure --yes --root ${SD03_DIR}/invokeai --skip-sd-weights

# pip install ruamel.yaml==0.17.40 pillow==10.0.1 pypatchmatch

CMD="invokeai"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD03_DIR}/parameters.txt"
eval $CMD
