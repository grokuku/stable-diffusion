#!/bin/bash
source /sl_folder.sh

export PATH="/opt/miniconda3/bin:$PATH"

mkdir -p "${SD50_DIR}"
mkdir -p /outputs/50-Lama-cleaner

if [ ! -d ${SD50_DIR}/env ]; then
    conda create -p ${SD50_DIR}/env -y
fi

source activate ${SD50_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

if [ ! -f "$SD50_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/50.txt" "$SD50_DIR/parameters.txt"
fi

if [ ! -d ${SD50_DIR}/lama-cleaner ]; then
    cd "${SD50_DIR}" && git clone https://github.com/Sanster/lama-cleaner
fi

cd ${SD50_DIR}/lama-cleaner
git config --global --add safe.directory ${SD50_DIR}/lama_cleaner
git pull -X ours

# chown -R diffusion:users ${BASE_DIR}

# if [ ! -d ${SD50_DIR}/venv ]; then
#     su -w SD50_DIR - diffusion -c 'cd ${SD50_DIR} && python3 -m venv venv'
# fi

cd ${SD50_DIR}/lama-cleaner
pip install -r requirements.txt

CMD="python main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD50_DIR}/parameters.txt"

eval $CMD


