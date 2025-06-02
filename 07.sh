#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD07_DIR=${BASE_DIR}/07-SwarmUI

mkdir -p ${SD07_DIR}
mkdir -p /config/outputs/07-SwarmUI # Conservé de l'original

#remove old venv if still exists (logique originale)
if [ -d ${SD07_DIR}/venv ]; then
    rm -rf ${SD07_DIR}/venv
fi

#copy default parameters if missing (logique originale)
if [ ! -f "$SD07_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/07.txt" "$SD07_DIR/parameters.txt"
fi

# MODIFICATION GIT CI-DESSOUS
if [ ! -d "${SD07_DIR}/SwarmUI/.git" ]; then
    echo "Cloning SwarmUI repository..."
    # L'original fait : cd "${SD07_DIR}" && git clone ...
    git clone https://github.com/mcmonkeyprojects/SwarmUI.git "${SD07_DIR}/SwarmUI"
    cd "${SD07_DIR}/SwarmUI" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing SwarmUI repository found. Synchronizing..."
    cd "${SD07_DIR}/SwarmUI" # S'assurer d'être dans le dossier du repo
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

# La section "cd ${SD07_DIR}/SwarmUI" et "check_remote" de l'original est maintenant gérée par la logique ci-dessus.

#clean conda env if needed (logique originale)
clean_env ${SD07_DIR}/env

#create env if missing (logique originale)
if [ ! -d ${SD07_DIR}/env ]; then
    conda create -p ${SD07_DIR}/env -y
fi

#activate env and install packages (logique originale)
source activate ${SD07_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

#move models to common folder and create symlinks (logique originale)
mkdir -p ${SD07_DIR}/SwarmUI/Models

sl_folder ${SD07_DIR}/SwarmUI/Models Stable-Diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD07_DIR}/SwarmUI/Models Lora ${BASE_DIR}/models lora
sl_folder ${SD07_DIR}/SwarmUI/Models VAE ${BASE_DIR}/models vae
sl_folder ${SD07_DIR}/SwarmUI/Models Embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD07_DIR}/SwarmUI/Models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD07_DIR}/SwarmUI/Models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD07_DIR}/SwarmUI Output ${BASE_DIR}/outputs 07-SwarmUI # Conservé de l'original

# install dependencies (logique originale)
pip install --upgrade pip

if [ -f ${SD07_DIR}/requirements.txt ]; then # Conservé de l'original
    pip install -r ${SD07_DIR}/requirements.txt
fi

#launch SwarmUI (logique originale)
cd ${SD07_DIR}/SwarmUI
CMD="./launch-linux.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD07_DIR}/parameters.txt"
eval $CMD
sleep infinity