#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD51_DIR=${BASE_DIR}/51-facefusion

mkdir -p ${SD51_DIR}
mkdir -p /config/outputs/51-facefusion


if [ ! -d ${SD51_DIR}/env ]; then
    conda create -p ${SD51_DIR}/env -y
fi

source activate ${SD51_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx ffmpeg --solver=libmamba -y


    if [ ! -f "$SD51_DIR/parameters.txt" ]; then
      cp -v "${SD_INSTALL_DIR}/parameters/51.txt" "$SD51_DIR/parameters.txt"
    fi

    if [ ! -d ${SD51_DIR}/facefusion ]; then
      cd "${SD51_DIR}" && git clone https://github.com/facefusion/facefusion
    fi

    cd ${SD51_DIR}/facefusion
    git config --global --add safe.directory ${SD51_DIR}/facefusion
    git pull -X ours

 
 cd ${SD51_DIR}/facefusion 
 pip install -r requirements.txt 
 export GRADIO_SERVER_NAME=0.0.0.0 
 export GRADIO_SERVER_PORT=9000 
 CMD="python3 run.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD51_DIR}/parameters.txt"; eval $CMD


