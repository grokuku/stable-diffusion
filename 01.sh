#!/bin/bash
source /sl_folder.sh

SD01_DIR="${BASE_DIR}/01-easy-diffusion"

mkdir -p ${SD01_DIR}/{models,version,plugins/ui,scripts}
cd ${SD01_DIR}

if [ ! -f ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js ]; then
    mkdir -p ${SD01_DIR}/plugins/ui/
    curl -L https://raw.githubusercontent.com/patriceac/Easy-Diffusion-Plugins/main/plugin-manager.plugin.js --output ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js
fi

# Merge Models, vae, lora, hypernetworks, etc.
sl_folder ${SD01_DIR}/models stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD01_DIR}/models hypernetwork ${BASE_DIR}/models hypernetwork
sl_folder ${SD01_DIR}/models lora ${BASE_DIR}/models lora
sl_folder ${SD01_DIR}/models vae ${BASE_DIR}/models vae
sl_folder ${SD01_DIR}/models controlnet ${BASE_DIR}/models controlnet
sl_folder ${SD01_DIR}/models realesrgan ${BASE_DIR}/models upscale
sl_folder ${SD01_DIR}/models codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD01_DIR}/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD01_DIR}/models gfpgan ${BASE_DIR}/models gfpgan

sl_folder /home/diffusion "Stable Diffusion UI" /config/outputs 01-Easy-Diffusion

if [ ! -f "$SD01_DIR/scripts/config.json" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/01.txt" "$SD01_DIR/scripts/config.json"
fi

if [ ! -f "$SD01_DIR/start.sh" ]; then
    curl -L https://github.com/easydiffusion/easydiffusion/releases/download/v2.5.41a/Easy-Diffusion-Linux.zip --output edui.zip
    unzip edui.zip
    cp -rf easy-diffusion/* .
    rm -rf easy-diffusion
    rm -f edui.zip
fi

#chown -R diffusion:users ${BASE_DIR}

cd $SD01_DIR
bash start.sh
