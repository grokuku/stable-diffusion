#!/bin/bash
source /functions.sh


export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR} # Assure que le dossier de base existe

# MODIFICATION GIT CI-DESSOUS
# Le script original clone dans SD02_DIR/forge
mkdir -p "${SD02_DIR}/forge" # S'assure que le sous-dossier pour forge existe

if [ ! -d "${SD02_DIR}/forge/.git" ]; then
    echo "Cloning Stable-Diffusion-WebUI-Forge repository..."
    # Le script original clone dans ${SD02_DIR}/forge
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "${SD02_DIR}/forge"
    cd "${SD02_DIR}/forge" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing Stable-Diffusion-WebUI-Forge repository found. Synchronizing..."
    cd "${SD02_DIR}/forge" # S'assurer d'être dans le dossier du repo
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

#clean conda env (logique originale)
clean_env ${SD02_DIR}/conda-env # Note: Le script original utilise le même nom d'env que 02.sh

# Create Conda virtual env (logique originale)
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

#activate conda env + install base tools (logique originale)
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

if [ ! -f "$SD02_DIR/parameters.forge.txt" ]; then # Logique originale
    cp -v "/opt/sd-install/parameters/02.forge.txt" "$SD02_DIR/parameters.forge.txt"
fi

#install custom requirements (logique originale)
pip install --upgrade pip

if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Merge Models, vae, lora, and hypernetworks, and outputs (logique originale)
# Ignore move errors if they occur
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

sl_folder ${SD02_DIR}/forge outputs ${BASE_DIR}/outputs 02-sd-webui # Logique originale pour le dossier de sortie

#Force using correct version of Python (logique originale)
export python_cmd="$(which python)"

# Run webUI (logique originale)
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