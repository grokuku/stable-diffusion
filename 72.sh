#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD72_DIR=${BASE_DIR}/72-OneTrainer

# Switch NGINX to PORT 9000 (logique originale)
sudo cp /opt/sd-install/parameters/nginx.txt /etc/nginx/sites-enabled/default
sudo nginx -s reload

mkdir -p ${SD72_DIR}
mkdir -p /config/outputs/72-OneTrainer # Conservé de l'original

if [ ! -f "$SD72_DIR/parameters.txt" ]; then # Conservé de l'original
  cp -v "${SD_INSTALL_DIR}/parameters/72.txt" "$SD72_DIR/parameters.txt"
fi

# MODIFICATION GIT CI-DESSOUS
if [ ! -d "${SD72_DIR}/OneTrainer/.git" ]; then
  echo "Cloning OneTrainer repository..."
  # L'original fait : cd "${SD72_DIR}" && git clone ...
  git clone https://github.com/Nerogar/OneTrainer.git "${SD72_DIR}/OneTrainer"
  cd "${SD72_DIR}/OneTrainer" # S'assurer d'être dans le dossier du repo après clone
else
  echo "Existing OneTrainer repository found. Synchronizing..."
  cd "${SD72_DIR}/OneTrainer" # S'assurer d'être dans le dossier du repo
  check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

# La section "cd ${SD72_DIR}/OneTrainer" et "check_remote" de l'original est maintenant gérée par la logique ci-dessus.

#clean conda env if needed (logique originale)
# Note: l'original spécifiait le chemin complet de l'env conda DANS le dossier OneTrainer
clean_env ${SD72_DIR}/OneTrainer/conda_env

#create conda env (logique originale)
if [ ! -d ${SD72_DIR}/OneTrainer/conda_env ]; then
    conda create -p ${SD72_DIR}/OneTrainer/conda_env -y
fi

source activate ${SD72_DIR}/OneTrainer/conda_env # Conservé de l'original
conda install -n base conda-libmamba-solver -y # Conservé de l'original
conda install -c conda-forge python=3.10 pip --solver=libmamba -y # Conservé de l'original


#install dependencies (logique originale)
pip install --upgrade pip
cd ${SD72_DIR}/OneTrainer/
pip install -r requirements.txt

# install custom requirements (logique originale)
if [ -f ${SD72_DIR}/requirements.txt ]; then
    pip install -r ${SD72_DIR}/requirements.txt
fi

# Merge Models, vae, lora, hypernetworks, and outputs (logique originale commentée)
#sl_folder ${SD71_DIR}/fluxgym/models vae ${BASE_DIR}/models vae
#sl_folder ${SD71_DIR}/fluxgym/models clip ${BASE_DIR}/models clip
#sl_folder ${SD71_DIR}/fluxgym/models unet ${BASE_DIR}/models unet

#sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym


#launch OneTrainer (logique originale)
conda deactivate # Conservé de l'original
cd ${SD72_DIR}/OneTrainer/ # Conservé de l'original
echo LAUNCHING OneTrainer ! # Conservé de l'original
#bash start-ui.sh (logique originale commentée)
xterm -hold -e "${SD72_DIR}/OneTrainer/start-ui.sh" # Conservé de l'original
ECHO ************************************* # Conservé de l'original (devrait être echo)
ECHO **** READY TO LAUNCH ONE TRAINER **** # Conservé de l'original (devrait être echo)
ECHO ************************************* # Conservé de l'original (devrait être echo)
sleep infinity