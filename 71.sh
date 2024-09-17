#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD71_DIR=${BASE_DIR}/71-fluxgym

mkdir -p ${SD71_DIR}
mkdir -p /config/outputs/71-fluxgym

if [ ! -f "$SD71_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/71.txt" "$SD71_DIR/parameters.txt"
fi

if [ ! -d ${SD71_DIR}/fluxgym ]; then
  cd "${SD71_DIR}" && git clone https://github.com/cocktailpeanut/fluxgym
  cd fluxgym
  git clone -b sd3 https://github.com/kohya-ss/sd-scripts
fi

# check if remote is ahead of local
cd ${SD71_DIR}/fluxgym
check_remote

#clean conda env if needed
clean_env ${SD71_DIR}/env

#create conda env
if [ ! -d ${SD71_DIR}/env ]; then
    conda create -p ${SD71_DIR}/env -y
fi

source activate ${SD71_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y


#install dependencies
pip install --upgrade pip
cd ${SD71_DIR}/fluxgym/sd-scripts
pip install -r requirements.txt
cd ${SD71_DIR}/fluxgym/
pip install -r requirements.txt
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

# install custom requirements
if [ -f ${SD71_DIR}/requirements.txt ]; then
    pip install -r ${SD71_DIR}/requirements.txt
fi

# Merge Models, vae, lora, hypernetworks, and outputs
sl_folder ${SD71_DIR}/fluxgym/models vae ${BASE_DIR}/models vae
sl_folder ${SD71_DIR}/fluxgym/models clip ${BASE_DIR}/models clip
sl_folder ${SD71_DIR}/fluxgym/models unet ${BASE_DIR}/models unet

sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym


#launch fluxgym
cd ${SD71_DIR}/fluxgym/
echo LAUNCHING fluxgym !
export GRADIO_SERVER_NAME="0.0.0.0"
export GRADIO_SERVER_PORT=9000
#CMD="python app.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD71_DIR}/parameters.txt"; eval $CMD
python app.py
wait 99999