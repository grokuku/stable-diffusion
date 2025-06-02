#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD71_DIR=${BASE_DIR}/71-fluxgym

mkdir -p ${SD71_DIR}
mkdir -p /config/outputs/71-fluxgym # Conservé de l'original

if [ ! -f "$SD71_DIR/parameters.txt" ]; then # Conservé de l'original
  cp -v "${SD_INSTALL_DIR}/parameters/71.txt" "$SD71_DIR/parameters.txt"
fi

# MODIFICATION GIT POUR FLUXGYM PRINCIPAL
if [ ! -d "${SD71_DIR}/fluxgym/.git" ]; then
  echo "Cloning fluxgym repository..."
  # L'original fait : cd "${SD71_DIR}" && git clone ...
  git clone https://github.com/cocktailpeanut/fluxgym.git "${SD71_DIR}/fluxgym"
  cd "${SD71_DIR}/fluxgym" # S'assurer d'être dans le dossier du repo après clone
  # Le clone du sous-module sd-scripts se fait après le clone principal dans l'original
  echo "Cloning sd-scripts sub-repository for fluxgym..."
  git clone -b sd3 https://github.com/kohya-ss/sd-scripts # Pas de destination explicite, clone dans le CWD (fluxgym)
else
  echo "Existing fluxgym repository found. Synchronizing..."
  cd "${SD71_DIR}/fluxgym" # S'assurer d'être dans le dossier du repo
  check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
  # Après la synchro du principal, il faut s'occuper du sous-dossier sd-scripts
  if [ -d "sd-scripts/.git" ]; then # Vérifier si sd-scripts est bien un repo git
    echo "Synchronizing sd-scripts sub-repository..."
    cd sd-scripts
    check_remote "GIT_REF" # GIT_REF s'appliquera aussi ici.
                           # Si une ref spécifique pour sd-scripts est nécessaire, il faudrait une autre variable.
    cd .. # Retour au dossier fluxgym
  else
    echo "sd-scripts sub-repository not found or not a git repo, attempting to clone..."
    # Au cas où la synchro aurait supprimé le dossier ou s'il n'a jamais été cloné correctement
    rm -rf sd-scripts # Supprimer au cas où ce serait un dossier vide ou corrompu
    git clone -b sd3 https://github.com/kohya-ss/sd-scripts
  fi
fi
# FIN DE LA MODIFICATION GIT POUR FLUXGYM PRINCIPAL ET SD-SCRIPTS

# L'original avait "cd ${SD71_DIR}/fluxgym" puis "check_remote". Ceci est géré.

#clean conda env if needed (logique originale)
clean_env ${SD71_DIR}/env

#create conda env (logique originale)
if [ ! -d ${SD71_DIR}/env ]; then
    conda create -p ${SD71_DIR}/env -y
fi

source activate ${SD71_DIR}/env # Conservé de l'original
conda install -n base conda-libmamba-solver -y # Conservé de l'original
conda install -c conda-forge python=3.10 pip --solver=libmamba -y # Conservé de l'original


#install dependencies (logique originale)
pip install --upgrade pip
cd ${SD71_DIR}/fluxgym/sd-scripts
pip install -r requirements.txt
cd ${SD71_DIR}/fluxgym/
pip install -r requirements.txt
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

# install custom requirements (logique originale)
if [ -f ${SD71_DIR}/requirements.txt ]; then
    pip install -r ${SD71_DIR}/requirements.txt
fi

# Merge Models, vae, lora, hypernetworks, and outputs (logique originale)
sl_folder ${SD71_DIR}/fluxgym/models vae ${BASE_DIR}/models vae
sl_folder ${SD71_DIR}/fluxgym/models clip ${BASE_DIR}/models clip
sl_folder ${SD71_DIR}/fluxgym/models unet ${BASE_DIR}/models unet

sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym # Conservé de l'original

#launch fluxgym (logique originale)
export LD_LIBRARY_PATH=${SD71_DIR}/env/lib/python3.10/site-packages/nvidia/cuda_nvrtc/lib:$LD_LIBRARY_PATH
export GRADIO_SERVER_NAME="0.0.0.0"
export GRADIO_SERVER_PORT=9000
cd ${SD71_DIR}/fluxgym/
echo LAUNCHING fluxgym !
python app.py
sleep infinity