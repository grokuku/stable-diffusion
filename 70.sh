#!/bin/bash
source /sl_folder.sh

export PATH="/opt/miniconda3/bin:$PATH"

mkdir -p ${SD70_DIR}
mkdir -p /outputs/70-kohya

if [ ! -d ${SD70_DIR}/env ]; then
    conda create -p ${SD70_DIR}/env -y
fi

source activate ${SD70_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y

# Create venv
if [ ! -d ${SD70_DIR}/venv ]; then
    cd ${SD70_DIR}
    python -m venv venv
    cd ${SD70_DIR}
fi

if [ ! -f "$SD70_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/70.txt" "$SD70_DIR/parameters.txt"
fi

if [ ! -d ${SD70_DIR}/kohya_ss ]; then
  cd "${SD70_DIR}" && git clone https://github.com/bmaltais/kohya_ss
fi

    cd ${SD70_DIR}/kohya_ss
    git config --global --add safe.directory ${SD70_DIR}/kohya_ss
    git pull -X ours

#    if [ ! -d ${SD70_DIR}/venv ]; then
#      su -w SD70_DIR - diffusion -c 'cd ${SD70_DIR} && python3 -m venv venv'
#    fi

cd ${SD70_DIR}
source venv/bin/activate
pip install --upgrade pip
cd ${SD70_DIR}/kohya_ss
pip install -r requirements.txt
cd ${SD70_DIR}/kohya_ss
CMD="bash gui.sh"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD70_DIR}/parameters.txt"; eval $CMD