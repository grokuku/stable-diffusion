#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD70_DIR=${BASE_DIR}/70-kohya

mkdir -p ${SD70_DIR}
mkdir -p /config/outputs/70-kohya

if [ ! -f "$SD70_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/70.txt" "$SD70_DIR/parameters.txt"
fi

# MODIFICATION GIT UNIQUEMENT CI-DESSOUS
if [ ! -d "${SD70_DIR}/kohya_ss/.git" ]; then # Vérification sur .git pour plus de robustesse
  echo "Cloning Kohya_ss repository..."
  cd "${SD70_DIR}" && git clone https://github.com/bmaltais/kohya_ss "${SD70_DIR}/kohya_ss" # Destination explicite
  cd "${SD70_DIR}/kohya_ss" # S'assurer d'être dans le dossier du repo
else
  echo "Existing Kohya_ss repository found. Synchronizing..."
  cd "${SD70_DIR}/kohya_ss" # S'assurer d'être dans le dossier du repo
  check_remote "KOHYA_GIT_REF" # Appel à check_remote avec la variable pour la ref Git
fi
# FIN DE LA MODIFICATION GIT

#clean conda env if needed (logique originale)
clean_env ${SD70_DIR}/env

#create conda env (logique originale)
if [ ! -d ${SD70_DIR}/env ]; then
    conda create -p ${SD70_DIR}/env -y
fi

source activate ${SD70_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y

#install dependencies (logique originale)
pip install --upgrade pip
cd ${SD70_DIR}/kohya_ss
python ./setup/setup_linux.py # Conservé tel quel depuis votre script original
cd ${SD70_DIR}/kohya_ss

# install custom requirements (logique originale)
if [ -f ${SD70_DIR}/requirements.txt ]; then
    pip install -r ${SD70_DIR}/requirements.txt
fi

#launch Kohya (logique originale)
echo LAUNCHING KOHYA_SS !
CMD="python kohya_gui.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD70_DIR}/parameters.txt"; eval $CMD

sleep infinity