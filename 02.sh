#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# Disable the webui's built-in Python venv creation
export venv_dir="-"

# Create the main directory for this UI
mkdir -p ${SD02_DIR}

# Install or update the Stable-Diffusion-WebUI (AUTOMATIC1111) repository
if [ ! -d "${SD02_DIR}/webui/.git" ]; then
    echo "Cloning Stable-Diffusion-WebUI repository..."
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "${SD02_DIR}/webui"
    cd "${SD02_DIR}/webui"
else
    echo "Existing Stable-Diffusion-WebUI repository found. Synchronizing..."
    cd "${SD02_DIR}/webui"
    check_remote "GIT_REF"
fi

# Clean the Conda environment if required
clean_env ${SD02_DIR}/conda-env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate the environment and install base packages
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

# Copy default launch parameters if they don't exist
if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Install custom user requirements if specified
pip install --upgrade pip
if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Symlink shared models folders into the webui directory
sl_folder ${SD02_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

# Symlink the output folder
sl_folder ${SD02_DIR}/webui outputs ${BASE_DIR}/outputs 02-sd-webui

# Force the use of the Conda environment's Python executable
export python_cmd="$(which python)"

# Launch Stable-Diffusion-WebUI
echo "Run Stable-Diffusion-WebUI"
cd ${SD02_DIR}/webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD
sleep infinity