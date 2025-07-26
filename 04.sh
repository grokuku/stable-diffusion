#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD04_DIR=${BASE_DIR}/04-SD-Next

echo "Install and run SD-Next"

mkdir -p ${SD04_DIR}

# Install or update the SD-Next repository
if [ ! -d "${SD04_DIR}/webui/.git" ]; then
    echo "Cloning SD-Next (automatic) repository..."
    git clone https://github.com/vladmandic/automatic "${SD04_DIR}/webui"
    cd "${SD04_DIR}/webui"
else
    echo "Existing SD-Next repository found. Synchronizing..."
    cd "${SD04_DIR}/webui"
    check_remote "GIT_REF"
fi

# Clean Conda and Python virtual environments if required
clean_env ${SD04_DIR}/env
clean_env ${SD04_DIR}/webui/venv

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD04_DIR}/env ]; then
    conda create -p ${SD04_DIR}/env -y
fi

# Activate the Conda environment and install base packages
source activate ${SD04_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

# Create the Python venv for SD-Next if it doesn't exist
if [ ! -d ${SD04_DIR}/webui/venv ]; then
    echo "Creating Python venv for SD-Next..."
    cd ${SD04_DIR}/webui
    python -m venv venv
fi

# Install custom user requirements into the Python venv
cd ${SD04_DIR}/webui
source venv/bin/activate
pip install --upgrade pip
if [ -f ${SD04_DIR}/requirements.txt ]; then
    pip install -r ${SD04_DIR}/requirements.txt
fi
deactivate

# Copy default launch parameters if they don't exist
if [ ! -f "$SD04_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/04.txt" "$SD04_DIR/parameters.txt"
fi

# Symlink shared models folders into the webui directory
sl_folder ${SD04_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD04_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD04_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD04_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD04_DIR}/webui/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD04_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD04_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD04_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD04_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD04_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

# Symlink the output folder
sl_folder ${SD04_DIR}/webui outputs ${BASE_DIR}/outputs 04-SD-Next

cd ${SD04_DIR}/webui/

# Launch SD-Next WebUI
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD04_DIR}/parameters.txt"
eval $CMD
sleep infinity