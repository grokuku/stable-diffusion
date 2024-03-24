#!/bin/bash

source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD20_DIR=${BASE_DIR}/20-kubin

mkdir -p "${SD20_DIR}"
mkdir -p /config/outputs/20-kubin

if [ ! -d ${SD20_DIR}/env ]; then
    conda create -p ${SD20_DIR}/env -y
fi

source activate ${SD20_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y


if [ ! -f "$SD20_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/20.txt" "$SD20_DIR/parameters.txt"
fi

if [ ! -d ${SD20_DIR}/kuby ]; then
    cd "${SD20_DIR}" && git clone https://github.com/seruva19/kubin
fi

cd ${SD20_DIR}/kubin
git config --global --add safe.directory ${SD20_DIR}/kubin
git pull -X ours

# chown -R diffusion:users ${BASE_DIR}

if [ ! -d ${SD20_DIR}/venv ]; then
    python3 -m venv venv
fi


cd ${SD20_DIR}
source venv/bin/activate
cd ${SD20_DIR}/kubin
pip install -r requirements.txt
CMD="python3 src/kubin.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD20_DIR}/parameters.txt"; eval $CMD
