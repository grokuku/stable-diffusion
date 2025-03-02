#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

log_message "INFO" "Starting Automatic1111 installation and setup"

# Disable the use of a python venv
export venv_dir="-"

mkdir -p ${SD02_DIR}
show_system_info

# Install and update Automatic1111
if ! manage_git_repo "Automatic1111" \
    "https://github.com/AUTOMATIC1111/stable-diffusion-webui" \
    "${SD02_DIR}/stable-diffusion-webui"; then
    log_message "CRITICAL" "Failed to manage Automatic1111 repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD02_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD02_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD02_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# Install custom requirements
log_message "INFO" "Installing Python requirements"
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD02_DIR}/stable-diffusion-webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/stable-diffusion-webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/stable-diffusion-webui embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/stable-diffusion-webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/stable-diffusion-webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/stable-diffusion-webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD02_DIR}/stable-diffusion-webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD02_DIR}/stable-diffusion-webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD02_DIR}/stable-diffusion-webui outputs ${BASE_DIR}/outputs 02-sd-webui

# Force using correct version of Python
export python_cmd="$(which python)"

# Run WebUI
log_message "INFO" "Launching Automatic1111 WebUI"
cd ${SD02_DIR}/stable-diffusion-webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity