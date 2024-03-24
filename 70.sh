#!/bin/bash
source /sl_folder.sh

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
# https://stackoverflow.com/a/25109122/1469797
cd ${SD70_DIR}/kohya_ss
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
    rm -rf ${SD70_DIR}/env
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

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



