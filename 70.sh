#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD70_DIR=${BASE_DIR}/70-kohya

mkdir -p ${SD70_DIR}
mkdir -p /config/outputs/70-kohya

if [ ! -f "$SD70_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/70.txt" "$SD70_DIR/parameters.txt"
fi

if [ ! -d ${SD70_DIR}/kohya_ss ]; then
  cd "${SD70_DIR}" && git clone https://github.com/bmaltais/kohya_ss
fi

# check if remote is ahead of local
check_remote

#clean conda env if needed
clean_env ${SD70_DIR}/env

#create conda env
if [ ! -d ${SD70_DIR}/env ]; then
    conda create -p ${SD70_DIR}/env -y
fi

source activate ${SD70_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y

#install dependencies
pip install --upgrade pip
cd ${SD70_DIR}/kohya_ss
python ./setup/setup_linux.py
cd ${SD70_DIR}/kohya_ss

#launch Kohya
echo LAUNCHING KOHYA_SS !
CMD="python kohya_gui.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD70_DIR}/parameters.txt"; eval $CMD



wait 99999