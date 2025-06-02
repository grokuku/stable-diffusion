#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD06_DIR=${BASE_DIR}/06-Fooocus

mkdir -p ${SD06_DIR}
mkdir -p $BASE_DIR/outputs/06-Fooocus # Conservé de l'original

#remove old venv if still present (logique originale)
if [ -d ${SD06_DIR}/venv ]; then
    rm -rf ${SD06_DIR}/venv
fi

#copy parameters if absent (logique originale)
if [ ! -f "$SD06_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/06.txt" "$SD06_DIR/parameters.txt"
fi

# MODIFICATION GIT CI-DESSOUS
if [ ! -d "${SD06_DIR}/Fooocus/.git" ]; then
    echo "Cloning Fooocus repository..."
    # L'original fait : cd "${SD06_DIR}" && git clone ...
    # ce qui est équivalent à git clone ... "${SD06_DIR}/Fooocus" si Fooocus est le nom du repo.
    git clone https://github.com/lllyasviel/Fooocus.git "${SD06_DIR}/Fooocus"
    cd "${SD06_DIR}/Fooocus" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing Fooocus repository found. Synchronizing..."
    cd "${SD06_DIR}/Fooocus" # S'assurer d'être dans le dossier du repo
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

# La section "cd ${SD06_DIR}/Fooocus" et "check_remote" de l'original est maintenant gérée par la logique ci-dessus.

#clean conda env if needed (logique originale)
clean_env ${SD06_DIR}/env

#create env if missing (logique originale)
if [ ! -d ${SD06_DIR}/env ]; then
    conda create -p ${SD06_DIR}/env -y
fi

#activate env and install packages (logique originale)
source activate ${SD06_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y # Version Python de l'original
conda install -c nvidia cuda-cudart --solver=libmamba -y

sl_folder ${SD06_DIR}/Fooocus/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${SD06_DIR}/Fooocus/models loras ${BASE_DIR}/models lora
sl_folder ${SD06_DIR}/Fooocus/models vae ${BASE_DIR}/models vae
sl_folder ${SD06_DIR}/Fooocus/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD06_DIR}/Fooocus/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD06_DIR}/Fooocus/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${SD06_DIR}/Fooocus/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${SD06_DIR}/Fooocus/models controlnet ${BASE_DIR}/models controlnet

sl_folder ${SD06_DIR}/Fooocus outputs ${BASE_DIR}/outputs 06-Fooocus # Conservé de l'original

#install requirements (logique originale)
cd ${SD06_DIR}/Fooocus
pip install -r requirements_versions.txt
if [ -f ${SD06_DIR}/requirements.txt ]; then # Conservé de l'original
    pip install -r ${SD06_DIR}/requirements.txt
fi

#Launch webUI (logique originale)
CMD="python launch.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD06_DIR}/parameters.txt"
eval $CMD
sleep infinity