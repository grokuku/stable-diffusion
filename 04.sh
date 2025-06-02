#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD04_DIR=${BASE_DIR}/04-SD-Next
export use_venv=1 # Conservé de l'original, même si non utilisé explicitement dans le script

echo "Install and run SD-Next"

mkdir -p ${SD04_DIR}

# MODIFICATION GIT CI-DESSOUS
if [ ! -d "${SD04_DIR}/webui/.git" ]; then
    echo "Cloning SD-Next (automatic) repository..."
    git clone https://github.com/vladmandic/automatic "${SD04_DIR}/webui"
    cd "${SD04_DIR}/webui" # S'assurer d'être dans le dossier du repo après clone
else
    echo "Existing SD-Next repository found. Synchronizing..."
    cd "${SD04_DIR}/webui" # S'assurer d'être dans le dossier du repo
    check_remote "GIT_REF" # Utilisation de la variable commune GIT_REF
fi
# FIN DE LA MODIFICATION GIT

#clean virtual env (logique originale)
clean_env ${SD04_DIR}/env
clean_env ${SD04_DIR}/webui/venv

#create conda env if needed (logique originale)
if [ ! -d ${SD04_DIR}/env ]; then
    conda create -p ${SD04_DIR}/env -y
fi

#activate and install basic tools (logique originale)
source activate ${SD04_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx --solver=libmamba -y

# Create venv (logique originale)
if [ ! -d ${SD04_DIR}/webui/venv ]; then
    echo "create venv"
    cd ${SD04_DIR}/webui
    python -m venv venv
fi

# install custom requirements (logique originale)
    cd ${SD04_DIR}/webui
    source venv/bin/activate
    pip install --upgrade pip

    if [ -f ${SD04_DIR}/requirements.txt ]; then
        pip install -r ${SD04_DIR}/requirements.txt
    fi

#    pip install coloredlogs flatbuffers numpy packaging protobuf==3.20.3 sympy (logique originale commentée)
#    pip install onnxruntime-gpu --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/ (logique originale commentée)
#    pip install insightface (logique originale commentée)
#    pip install basicsr (logique originale commentée)
#    pip install sqlalchemy (logique originale commentée)
    deactivate

#copy default parameters if absent (logique originale)
if [ ! -f "$SD04_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/04.txt" "$SD04_DIR/parameters.txt"
fi

# Merge Models, vae, lora, hypernetworks, and outputs (logique originale)
sl_folder ${SD04_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD04_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD04_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD04_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD04_DIR}/webui/models embeddings ${BASE_DIR}/models embeddings # Votre original avait 'models embeddings'
sl_folder ${SD04_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD04_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD04_DIR}/webui/models GFPGAN ${BASE_DIR}/models gfpgan
sl_folder ${SD04_DIR}/webui/models LDSR ${BASE_DIR}/models ldsr
sl_folder ${SD04_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet

sl_folder ${SD04_DIR}/webui outputs ${BASE_DIR}/outputs 04-SD-Next

cd ${SD04_DIR}/webui/

#Launch WebUI (logique originale)
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD04_DIR}/parameters.txt"
eval $CMD
sleep infinity