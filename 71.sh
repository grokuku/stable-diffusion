#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD71_DIR=${BASE_DIR}/71-fluxgym

mkdir -p ${SD71_DIR}
mkdir -p /config/outputs/71-fluxgym

# Copy default launch parameters if they don't exist
if [ ! -f "$SD71_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/71.txt" "$SD71_DIR/parameters.txt"
fi

# Install or update the main fluxgym repository
if [ ! -d "${SD71_DIR}/fluxgym/.git" ]; then
  echo "Cloning fluxgym repository..."
  git clone https://github.com/cocktailpeanut/fluxgym.git "${SD71_DIR}/fluxgym"
  cd "${SD71_DIR}/fluxgym"
  # Clone the required sd-scripts sub-repository after the main clone
  echo "Cloning sd-scripts sub-repository for fluxgym..."
  git clone -b sd3 https://github.com/kohya-ss/sd-scripts
else
  echo "Existing fluxgym repository found. Synchronizing..."
  cd "${SD71_DIR}/fluxgym"
  check_remote "GIT_REF"
  # After syncing the main repo, handle the sd-scripts sub-directory
  if [ -d "sd-scripts/.git" ]; then
    echo "Synchronizing sd-scripts sub-repository..."
    cd sd-scripts
    check_remote "GIT_REF" # Uses the same GIT_REF as the parent
    cd ..
  else
    echo "sd-scripts sub-repository not found or not a git repo, attempting to clone..."
    rm -rf sd-scripts # Clean up in case of a corrupted or empty directory
    git clone -b sd3 https://github.com/kohya-ss/sd-scripts
  fi
fi

# Clean the Conda environment if required
clean_env ${SD71_DIR}/env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD71_DIR}/env ]; then
    conda create -p ${SD71_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD71_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y

# Install Python requirements for both sd-scripts and fluxgym
pip install --upgrade pip
cd ${SD71_DIR}/fluxgym/sd-scripts
pip install -r requirements.txt
cd ${SD71_DIR}/fluxgym/
pip install -r requirements.txt
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

# Install custom user requirements if specified
if [ -f ${SD71_DIR}/requirements.txt ]; then
    pip install -r ${SD71_DIR}/requirements.txt
fi

# Symlink shared models folders into the fluxgym directory
sl_folder ${SD71_DIR}/fluxgym/models vae ${BASE_DIR}/models vae
sl_folder ${SD71_DIR}/fluxgym/models clip ${BASE_DIR}/models clip
sl_folder ${SD71_DIR}/fluxgym/models unet ${BASE_DIR}/models unet

# Symlink the output folder
sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym

# Launch fluxgym
export LD_LIBRARY_PATH=${SD71_DIR}/env/lib/python3.10/site-packages/nvidia/cuda_nvrtc/lib:$LD_LIBRARY_PATH
export GRADIO_SERVER_NAME="0.0.0.0"
export GRADIO_SERVER_PORT=9000
cd ${SD71_DIR}/fluxgym/
echo "LAUNCHING fluxgym !"
python app.py
sleep infinity