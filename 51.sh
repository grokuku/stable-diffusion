#!/bin/bash
# Description: This script installs and runs FaceFusion.
# Functionalities:
#   - Sets up the environment for FaceFusion.
#   - Clones the FaceFusion repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages, including FaceFusion.
#   - Runs FaceFusion.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Pip is used to install FaceFusion and its dependencies.
cp /dummy.sh /usr/bin/openbox-session
chmod +x /usr/bin/openbox-session
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD51_DIR=${BASE_DIR}/51-facefusion

mkdir -p ${SD51_DIR}
mkdir -p /config/outputs/51-facefusion

show_system_info

if [ ! -d ${SD51_DIR}/env ]; then
    conda create -p ${SD51_DIR}/env -y
fi

source activate ${SD51_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx ffmpeg --solver=libmamba -y


    if [ ! -f "$SD51_DIR/parameters.txt" ]; then
      cp -v "${SD_INSTALL_DIR}/parameters/51.txt" "$SD51_DIR/parameters.txt"
    fi

    # Install and update FaceFusion
    log_message "INFO" "Managing FaceFusion repository"
    if ! manage_git_repo "FaceFusion" \
        "https://github.com/facefusion/facefusion" \
        "${SD51_DIR}/facefusion"; then
        log_message "CRITICAL" "Failed to manage FaceFusion repository. Exiting."
        exit 1
    fi
 
 cd ${SD51_DIR}/facefusion 
 pip install -r requirements.txt
 python3 install.py --onnxruntime cuda
 
 conda deactivate
 source activate ${SD51_DIR}/env
 
 # install custom requirements
  pip install --upgrade pip

  if [ -f ${SD51_DIR}/requirements.txt ]; then
    pip install -r ${SD51_DIR}/requirements.txt
  fi

  
 export GRADIO_SERVER_NAME=0.0.0.0 
 export GRADIO_SERVER_PORT=9000 
 CMD="python3 facefusion.py run"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD51_DIR}/parameters.txt"; eval $CMD

sleep infinity
