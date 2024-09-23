#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD72_DIR=${BASE_DIR}/72-OneTrainer

#Switch NGINX to PORT 9000
sudo cp /opt/sd-install/parameters/nginx.txt /etc/nginx/sites-enabled/default
sudo nginx -s reload

mkdir -p ${SD72_DIR}
mkdir -p /config/outputs/72-OneTrainer

if [ ! -f "$SD72_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/72.txt" "$SD72_DIR/parameters.txt"
fi

if [ ! -d ${SD72_DIR}/OneTrainer ]; then
  cd "${SD72_DIR}" && git clone https://github.com/Nerogar/OneTrainer
  fi

# check if remote is ahead of local
cd ${SD72_DIR}/OneTrainer
check_remote

#clean conda env if needed
clean_env ${SD72_DIR}/env

#create conda env
if [ ! -d ${SD72_DIR}/env ]; then
    conda create -p ${SD72_DIR}/env -y
fi

source activate ${SD72_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y


#install dependencies
pip install --upgrade pip
cd ${SD72_DIR}/OneTrainer/
pip install -r requirements.txt

# install custom requirements
if [ -f ${SD72_DIR}/requirements.txt ]; then
    pip install -r ${SD72_DIR}/requirements.txt
fi

# Merge Models, vae, lora, hypernetworks, and outputs
#sl_folder ${SD71_DIR}/fluxgym/models vae ${BASE_DIR}/models vae
#sl_folder ${SD71_DIR}/fluxgym/models clip ${BASE_DIR}/models clip
#sl_folder ${SD71_DIR}/fluxgym/models unet ${BASE_DIR}/models unet

#sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym


#launch OneTrainer
cd ${SD72_DIR}/OneTrainer/
echo LAUNCHING OneTrainer !
bash start-ui.sh
wait 99999