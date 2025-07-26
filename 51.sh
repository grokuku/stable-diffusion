#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD51_DIR=${BASE_DIR}/51-facefusion

mkdir -p ${SD51_DIR}
mkdir -p /config/outputs/51-facefusion

# Install or update the FaceFusion repository
if [ ! -d "${SD51_DIR}/facefusion/.git" ]; then
  echo "Cloning FaceFusion repository..."
  git clone https://github.com/facefusion/facefusion.git "${SD51_DIR}/facefusion"
  cd "${SD51_DIR}/facefusion"
else
  echo "Existing FaceFusion repository found. Synchronizing..."
  cd "${SD51_DIR}/facefusion"
  check_remote "GIT_REF"
fi

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD51_DIR}/env ]; then
    conda create -p ${SD51_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD51_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx ffmpeg --solver=libmamba -y

# Copy default launch parameters if they don't exist
if [ ! -f "$SD51_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/51.txt" "$SD51_DIR/parameters.txt"
fi

# Install FaceFusion's Python requirements
cd ${SD51_DIR}/facefusion 
pip install -r requirements.txt
python3 install.py --onnxruntime cuda
 
# Deactivate and reactivate to ensure environment is clean
conda deactivate
source activate ${SD51_DIR}/env
 
# Install custom user requirements if specified
pip install --upgrade pip
if [ -f ${SD51_DIR}/requirements.txt ]; then
  pip install -r ${SD51_DIR}/requirements.txt
fi
  
# Launch FaceFusion
export GRADIO_SERVER_NAME=0.0.0.0 
export GRADIO_SERVER_PORT=9000 
CMD="python3 facefusion.py run"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD51_DIR}/parameters.txt"; eval $CMD

sleep infinity