#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD07_DIR=${BASE_DIR}/07-SwarmUI

mkdir -p ${SD07_DIR}
mkdir -p /config/outputs/07-SwarmUI

# Remove old venv if it still exists (legacy)
if [ -d ${SD07_DIR}/venv ]; then
    rm -rf ${SD07_DIR}/venv
fi

# Copy default launch parameters if they don't exist
if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

# Install or update the SwarmUI repository
if [ ! -d "${SD07_DIR}/SwarmUI/.git" ]; then
    echo "Cloning SwarmUI repository..."
    git clone https://github.com/mcmonkeyprojects/SwarmUI.git "${SD07_DIR}/SwarmUI"
    cd "${SD07_DIR}/SwarmUI"
else
    echo "Existing SwarmUI repository found. Synchronizing..."
    cd "${SD07_DIR}/SwarmUI"
    check_remote "GIT_REF"
fi

# Clean the Conda environment if required
clean_env ${SD07_DIR}/env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD07_DIR}/env ]; then
    conda create -p ${SD07_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD07_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

# Symlink shared models folders into the SwarmUI directory
mkdir -p ${SD07_DIR}/SwarmUI/Models
sl_folder ${SD07_DIR}/SwarmUI/Models Stable-Diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/SwarmUI/Models Lora ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/SwarmUI/Models VAE ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/SwarmUI/Models Embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/SwarmUI/Models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD07_DIR}/SwarmUI/Models controlnet ${BASE_DIR}/models controlnet

# Symlink the output folder
sl_folder ${SD07_DIR}/SwarmUI Output ${BASE_DIR}/outputs 07-SwarmUI

# Install custom user requirements if specified
pip install --upgrade pip
if [ -f ${SD07_DIR}/requirements.txt ]; then
    pip install -r ${SD07_DIR}/requirements.txt
fi

# Launch SwarmUI
cd ${SD07_DIR}/SwarmUI
CMD="./launch-linux.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
eval $CMD
sleep infinity