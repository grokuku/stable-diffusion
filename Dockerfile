# FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS builder # ---- DÉBUT DE LA SECTION À SUPPRIMER ----
# # Description: This Dockerfile defines the steps to build a Docker image for running Stable Diffusion WebUIs.
# # ... (tous les commentaires et commandes de la phase builder) ...
# RUN cd TRELLIS/extensions/vox2seq && \
#     python3 setup.py bdist_wheel && \
#     cp dist/*.whl /build/
# # RUN cd  # Cette ligne était vide, peut être supprimée de toute façon
# ---- FIN DE LA SECTION À SUPPRIMER ----

# L'image finale commence ici.
# Nous allons utiliser une image de base qui contient déjà CUDA runtime pour simplifier.
# nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04 est une bonne base si kasmvnc ne l'a pas.
# Alternativement, si kasmvnc est prioritaire et que vous devez ajouter CUDA:
# FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy AS base_kasm
# FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04
# COPY --from=base_kasm / /
# Cette approche est plus complexe à gérer pour les entrypoints de kasmvnc.
# Solution plus simple: S'assurer que kasmvnc a les libs ou les ajouter.

FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy
# Description: This Dockerfile defines the steps to create the final Docker image...

# Copier les scripts et la configuration de s6-overlay de l'image kasmvnc
# COPY docker/root/ / # Cette ligne est dans votre Dockerfile original, elle est correcte.

# Installer les dépendances de base et CUDA toolkit runtime si nécessaire
# L'image kasmvnc est basée sur Ubuntu Jammy.
# Vérifions si on peut ajouter CUDA plus proprement.

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_VISIBLE_DEVICES all

# Ajout du PPA NVIDIA et installation du toolkit CUDA runtime
# Cela assure que les libs sont compatibles avec l'OS de base de kasmvnc
RUN apt-get update -q && \
    apt-get install -y -q=2 --no-install-recommends software-properties-common gnupg curl && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb && \
    dpkg -i /tmp/cuda-keyring.deb && \
    rm /tmp/cuda-keyring.deb && \
    apt-get update -q && \
    # Installer seulement les composants runtime nécessaires pour CUDA 12.4
    apt-get install -y -q=2 --no-install-recommends \
        cuda- πιο-x86-64-12-4 \
        cuda-libraries-12-4 \
        cuda-nvrtc-12-4 \
        # Ajoutez d'autres paquets cuda-*-12-4 si nécessaire (ex: libcublas, libcufft)
        # Souvent, cuda-toolkit-12-4 installe trop de choses pour une image runtime.
        # Alternative plus simple mais plus grosse: apt-get -y install cuda-toolkit-12-4
    # Dépendances de votre application
    apt-get install -y -q=2 --no-install-recommends \
        wget mc bc nano rsync libgl1-mesa-glx libtcmalloc-minimal4 \
        libxft2 xvfb ffmpeg portaudio19-dev dotnet-sdk-8.0 git \
        python3.11 python3.11-venv python3-pip python3.11-dev && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
    update-alternatives --set python /usr/bin/python3.11 && \
    python3 -m pip install --upgrade pip && \
    # Nettoyage
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copier les fichiers de l'application et les configurations s6-overlay
COPY docker/root/ /

# Variables d'environnement de l'application
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config
ENV SD_INSTALL_DIR=/opt/sd-install
ENV XDG_CACHE_HOME=/config/temp
ENV UI_BRANCH=master
# CC, CXX, TORCH_CUDA_ARCH_LIST ne sont plus nécessaires ici car on ne compile plus de C++/CUDA.

RUN mkdir -p ${BASE_DIR}/temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs
ADD parameters/* ${SD_INSTALL_DIR}/parameters/
# RUN mkdir -p /root/defaults # Est-ce que kasmvnc l'utilise ? S'il est dans docker/root/ c'est OK.

# Copier les wheels précompilées DEPUIS LE DÉPÔT (où build-wheels.yml les a mises)
RUN mkdir -p /wheels
COPY precompiled_wheels/*.whl /wheels/

COPY --chown=abc:abc *.sh /
RUN chmod +x /*.sh # Rendre tous les .sh à la racine exécutables

# Configuration de l'utilisateur abc et Miniconda
ENV HOME=/home/abc
RUN mkdir -p /home/abc && \
    chown -R abc:abc /home/abc && \
    # Installer Miniconda pour l'utilisateur abc
    cd /tmp && \
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    # Exécuter le script d'installation en tant qu'utilisateur abc
    # Note: s6-overlay pourrait gérer la création de l'utilisateur abc plus tard.
    # Si l'utilisateur abc n'existe pas encore ici, chown après.
    # Pour l'instant, installons-le dans un chemin neutre puis chown.
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    # S'assurer que les permissions sont bonnes pour /opt/miniconda3 si abc doit y écrire
    # Ou que l'environnement de base est accessible en lecture pour abc
    chown -R abc:users /opt/miniconda3 && \ # ou abc:abc
    # Faire en sorte que conda soit utilisable par abc (sera fait dans les scripts .sh via `source activate`)
    # chown -R abc:abc /root # Peut-être plus nécessaire si Miniconda n'est pas dans /root
    chown -R abc:users ${SD_INSTALL_DIR} && \ # ou abc:abc
    chown -R abc:users ${BASE_DIR} # ou abc:abc - Géré par s6-overlay init-chown aussi

# L'initialisation de Conda pour le shell (conda init) est mieux gérée au niveau des scripts
# qui activent les environnements, ou via le profil de l'utilisateur s'il a un shell interactif.

# Les variables XDG_CONFIG_HOME sont pour l'utilisateur abc, ce qui est bien.
# S'assurer que l'utilisateur abc est bien celui qui exécute les services via s6-overlay.
# Votre `svc-app/run` utilise `s6-setuidgid abc /entry.sh`, ce qui est correct.

EXPOSE 9000/tcp
EXPOSE 3000/tcp

# L'entrypoint et CMD sont hérités de linuxserver/baseimage-kasmvnc et gérés par s6-overlay