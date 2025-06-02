#!/bin/bash

source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD05_DIR=${BASE_DIR}/05-comfy-ui

echo "Install and run Comfy-UI"
mkdir -p ${SD05_DIR}
mkdir -p /config/outputs/05-comfy-ui # Conservé de l'original


if [ ! -f "$SD05_DIR/parameters.txt" ]; then # Conservé de l'original
    cp -v "${SD_INSTALL_DIR}/parameters/05.txt" "$SD05_DIR/parameters.txt"
fi

# MODIFICATION GIT POUR COMFYUI PRINCIPAL
if [ ! -d "${SD05_DIR}/ComfyUI/.git" ]; then
    echo "Cloning ComfyUI repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "${SD05_DIR}/ComfyUI"
    cd "${SD05_DIR}/ComfyUI" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing ComfyUI repository found. Synchronizing..."
    cd "${SD05_DIR}/ComfyUI" # S'assurer d'être dans le dossier du repo
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT POUR COMFYUI PRINCIPAL

# MODIFICATION GIT POUR COMFYUI-MANAGER
# S'assurer que le dossier custom_nodes existe (logique originale)
mkdir -p "${SD05_DIR}/ComfyUI/custom_nodes"
if [ ! -d "${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
    echo "Cloning ComfyUI-Manager repository..."
    # La logique originale clonait ComfyUI-Manager directement
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git "${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager"
    cd "${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing ComfyUI-Manager repository found. Synchronizing..."
    cd "${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager" # S'assurer d'être dans le dossier du repo
    # L'original faisait : git pull -X ours. Remplacé par check_remote.
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT POUR COMFYUI-MANAGER

# La ligne "cd ${SD05_DIR}/ComfyUI/custom_nodes/ComfyUI-Manager" et "git pull -X ours" de l'original
# pour ComfyUI-Manager est remplacée par la logique ci-dessus.

# L'original avait aussi "cd ${SD05_DIR}/ComfyUI" suivi de "check_remote" pour le dépôt principal.
# Ceci est maintenant géré dans la première section de modification Git.

#clean conda env (logique originale)
clean_env ${SD05_DIR}/env

#create conda env if needed (logique originale)
if [ ! -d ${SD05_DIR}/env ]; then
    conda create -p ${SD05_DIR}/env -y
fi

#activate env and install basic dependencies (logique originale)
source activate ${SD05_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.12 pip gxx libcurand --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

#Install custom nodes dependencies if a clean Venv has been done (logique originale)
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Install Custom Nodes Dependencies"
    install_requirements ${SD05_DIR}/ComfyUI/custom_nodes
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#clean old venv if it still exists (logique originale)
if [ -d ${SD05_DIR}/venv ]; then
    rm -rf ${SD05_DIR}/venv
fi

# Merge Models, vae, lora, hypernetworks, and outputs (logique originale)
sl_folder ${SD05_DIR}/ComfyUI/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD05_DIR}/ComfyUI/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD05_DIR}/ComfyUI/models loras ${BASE_DIR}/models lora
sl_folder ${SD05_DIR}/ComfyUI/models vae ${BASE_DIR}/models vae
sl_folder ${SD05_DIR}/ComfyUI/models vae_approx ${BASE_DIR}/models vae_approx
sl_folder ${SD05_DIR}/ComfyUI/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD05_DIR}/ComfyUI/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD05_DIR}/ComfyUI/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD05_DIR}/ComfyUI/models clip ${BASE_DIR}/models clip
sl_folder ${SD05_DIR}/ComfyUI/models controlnet ${BASE_DIR}/models controlnet
sl_folder ${SD05_DIR}/ComfyUI/models t5 ${BASE_DIR}/models t5
sl_folder ${SD05_DIR}/ComfyUI/models unet ${BASE_DIR}/models unet


#install requirements (logique originale)
cd ${SD05_DIR}/ComfyUI
pip install --upgrade pip
pip install -r requirements.txt

if [ -f ${SD05_DIR}/requirements.txt ]; then # Conservé de l'original
    pip install -r ${SD05_DIR}/requirements.txt
fi

pip install /wheels/*.whl # Conservé de l'original
pip install plyfile \
    tqdm \
    spconv-cu124 \
    llama-cpp-python \
    logger \
    sageattention # Conservé de l'original
pip install --upgrade diffusers[torch] # Conservé de l'original

#run webui (logique originale)
cd ${SD05_DIR}/ComfyUI
CMD="python3 main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD05_DIR}/parameters.txt"
eval $CMD
sleep infinity