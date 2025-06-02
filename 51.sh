#!/bin/bash
cp /dummy.sh /usr/bin/openbox-session # Conservé de l'original
chmod +x /usr/bin/openbox-session # Conservé de l'original
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD51_DIR=${BASE_DIR}/51-facefusion

mkdir -p ${SD51_DIR}
mkdir -p /config/outputs/51-facefusion # Conservé de l'original


# MODIFICATION GIT CI-DESSOUS
if [ ! -d "${SD51_DIR}/facefusion/.git" ]; then
  echo "Cloning FaceFusion repository..."
  # L'original fait : cd "${SD51_DIR}" && git clone ...
  git clone https://github.com/facefusion/facefusion.git "${SD51_DIR}/facefusion"
  cd "${SD51_DIR}/facefusion" # S'assurer d'être dans le dossier du repo après clone
else
  echo "Existing FaceFusion repository found. Synchronizing..."
  cd "${SD51_DIR}/facefusion" # S'assurer d'être dans le dossier du repo
  check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

# La section "git config --global --add safe.directory" et "git pull -X ours" de l'original
# est maintenant gérée par la logique ci-dessus et par sync_repo si nécessaire.
# Le 'git pull -X ours' est spécifiquement remplacé par le reset --hard de sync_repo.
# 'git config --global --add safe.directory' n'est plus explicitement ici, car il est global.
# S'il est nécessaire par dépôt, il faudrait l'ajouter DANS sync_repo ou avant son appel.
# Pour l'instant, on suit la logique de ne modifier que le clone/pull.

# Create conda env if it doesn't exist (structure originale un peu différente, adaptée)
if [ ! -d ${SD51_DIR}/env ]; then # Conservé de l'original
    conda create -p ${SD51_DIR}/env -y
fi

source activate ${SD51_DIR}/env # Conservé de l'original
conda install -n base conda-libmamba-solver -y # Conservé de l'original
conda install -c conda-forge git python=3.11 pip gxx ffmpeg --solver=libmamba -y # Conservé de l'original

# Copy parameters if absent (logique originale)
if [ ! -f "$SD51_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/51.txt" "$SD51_DIR/parameters.txt"
fi

# Install FaceFusion requirements (logique originale)
cd ${SD51_DIR}/facefusion 
pip install -r requirements.txt
python3 install.py --onnxruntime cuda
 
conda deactivate # Conservé de l'original
source activate ${SD51_DIR}/env # Conservé de l'original
 
# install custom requirements (logique originale)
pip install --upgrade pip

if [ -f ${SD51_DIR}/requirements.txt ]; then
  pip install -r ${SD51_DIR}/requirements.txt
fi
  
# Lancement (logique originale)
export GRADIO_SERVER_NAME=0.0.0.0 
export GRADIO_SERVER_PORT=9000 
CMD="python3 facefusion.py run"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD51_DIR}/parameters.txt"; eval $CMD

sleep infinity