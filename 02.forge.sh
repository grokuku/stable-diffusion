#!/bin/bash
source /functions.sh


export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# Disable the webui's built-in Python venv creation
export venv_dir="-"

# Create the main directory for this UI
mkdir -p ${SD02_DIR}
mkdir -p "${SD02_DIR}/forge"

# Install or update the Stable-Diffusion-WebUI-Forge repository
if [ ! -d "${SD02_DIR}/forge/.git" ]; then
    echo "Cloning Stable-Diffusion-WebUI-Forge repository..."
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "${SD02_DIR}/forge"
    cd "${SD02_DIR}/forge"
else
    echo "Existing Stable-Diffusion-WebUI-Forge repository found. Synchronizing..."
    cd "${SD02_DIR}/forge"
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
if [ ! -f "$SD02_DIR/parameters.forge.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.forge.txt" "$SD02_DIR/parameters.forge.txt"
fi

# Install custom user requirements if specified
pip install --upgrade pip
if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Symlink shared models folders into the Forge directory
sl_folder ${SD02_DIR}/forge/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/forge/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/forge/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/forge/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/forge embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/forge/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/forge/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/forge/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/forge/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/forge/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/forge/models ControlNet ${BASE_DIR}/models controlnet

# Symlink the output folder
sl_folder ${SD02_DIR}/forge outputs ${BASE_DIR}/outputs 02-sd-webui

# Force the use of the Conda environment's Python executable
export python_cmd="$(which python)"

# Launch Stable-Diffusion-WebUI-Forge
echo "Run Stable-Diffusion-WebUI-forge"
cd ${SD02_DIR}/forge
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.forge.txt"
eval $CMD
sleep infinity