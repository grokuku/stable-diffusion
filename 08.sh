#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD08_DIR=${BASE_DIR}/08-voltaML

mkdir -p ${SD08_DIR}
mkdir -p /config/outputs/08-voltaML

if [ ! -d ${SD08_DIR}/env ]; then
    conda create -p ${SD08_DIR}/env -y
fi

source activate ${SD08_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip=22.3.1 gcc gxx --solver=libmamba -y
conda install pytorch torchvision torchaudio -c pytorch --solver=libmamba -y



if [ ! -f "$SD08_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/08.txt" "$SD08_DIR/parameters.txt"
fi

if [ ! -d "${SD08_DIR}/voltaML-fast-stable-diffusion" ]; then
    cd "${SD08_DIR}" && git clone https://github.com/VoltaML/voltaML-fast-stable-diffusion
fi

cd ${SD08_DIR}/voltaML-fast-stable-diffusion
git pull -X ours

if [ ! -d ${SD08_DIR}/voltaML-fast-stable-diffusion/venv ]; then
    cd ${SD08_DIR}/voltaML-fast-stable-diffusion
    python -m venv venv
fi

cd ${SD08_DIR}/voltaML-fast-stable-diffusion
source venv/bin/activate
#pip install --upgrade pip
pip install onnxruntime-gpu

for fichier in ${SD08_DIR}/voltaML-fast-stable-diffusion/requirements/*.txt; do
    echo "installation of requirements"
    pip install -r $fichier
done

sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data models ${BASE_DIR}/models stable-diffusion
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data lora ${BASE_DIR}/models lora
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data vae ${BASE_DIR}/models vae
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data textual-inversion ${BASE_DIR}/models embeddings
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data upscaler ${BASE_DIR}/models upscale
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data outputs /config/outputs 08-voltaML

# cd ${SD08_DIR}
# conda install -c conda-forge pytorch torchvis --solver=libmamba -y
# pip install -v -U git+https://github.com/chengzeyi/stable-fast.git@main#egg=stable-fast
# su -w SD08_DIR - diffusion -c 'cd ${SD08_DIR} && source venv/bin/activate && pip install torch==2.1.0+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 '
# su -w SD08_DIR - diffusion -c 'cd ${SD08_DIR} && source venv/bin/activate && pip install diffusers xformers ninja '
# su -w SD08_DIR - diffusion -c 'cd ${SD08_DIR} && source venv/bin/activate && pip install -v -U git+https://github.com/chengzeyi/stable-fast.git@main#egg=stable-fast  '

# Boucle pour parcourir tous les fichiers requirements.txt
cd ${SD08_DIR}/voltaML-fast-stable-diffusion
# source venv/bin/activate
CMD="python3 main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD08_DIR}/parameters.txt"
eval $CMD
