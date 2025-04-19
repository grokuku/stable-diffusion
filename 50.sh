#!/bin/bash
# Description: This script installs and runs IOPaint.
# Functionalities:
#   - Sets up the environment for IOPaint.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages, including IOPaint.
#   - Runs IOPaint.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Pip is used to install IOPaint and its dependencies.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD50_DIR=${BASE_DIR}/50-IOPaint

mkdir -p "${SD50_DIR}/IOPaint"
mkdir -p /config/outputs/50-IOPaint

if [ ! -d ${SD50_DIR}/env ]; then
    conda create -p ${SD50_DIR}/env -y
fi

source activate ${SD50_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

if [ ! -f "$SD50_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/50.txt" "$SD50_DIR/parameters.txt"
fi

cd ${SD50_DIR}/IOPaint

pip3 install --upgrade "iopaint==${UI_BRANCH:-latest}"

# install custom requirements
pip install --upgrade pip

if [ -f ${SD50_DIR}/requirements.txt ]; then
    pip install -r ${SD50_DIR}/requirements.txt
fi

CMD="iopaint start"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD50_DIR}/parameters.txt"

eval $CMD
sleep infinity
