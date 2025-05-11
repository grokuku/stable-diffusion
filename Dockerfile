# Dockerfile (Image Finale)
FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Copier les configurations s6-overlay etc.
COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config
ENV SD_INSTALL_DIR=/opt/sd-install
ENV XDG_CACHE_HOME=/config/temp
# CC et CXX peuvent être nécessaires si les utilisateurs compilent des extensions
# pour des UIs dans leurs scripts, donc on les garde.
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
# TORCH_CUDA_ARCH_LIST peut aussi être utile pour les compilations utilisateur.
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"
# UI_BRANCH est déjà défini dans le Dockerfile que tu avais.
ENV UI_BRANCH=master


# Installation des dépendances système pour l'image finale
# Inclut Python, Git, compilateurs, et le CUDA Toolkit complet
RUN apt-get update -q && \
    apt-get install -y -q=2 \
    curl \
    software-properties-common \
    wget \
    gnupg \
    mc \
    bc \
    nano \
    rsync \
    libgl1-mesa-glx \
    libtcmalloc-minimal4 \
    # libcufft10 # Fait partie du toolkit CUDA
    libxft2 \
    xvfb \
    cmake \
    build-essential \
    ffmpeg \
    gcc-12 \
    g++-12 \
    # dotnet-sdk-8.0 # Le gardes-tu pour une raison spécifique ? Sinon, peut être enlevé.
    git \
    portaudio19-dev && \
    # Si python3 est déjà python3.11 sur jammy, pas besoin de purge.
    # apt purge gcc-11 g++-11 -y && \
    # apt-get purge python3 -y && \ 
    # Installer Python 3.11 spécifiquement si la version système n'est pas la bonne
    # (Mais Miniconda va gérer son propre Python, donc peut-être pas critique ici si on n'utilise pas le Python système pour les UIs)
    # Pour l'instant, on laisse apt gérer Python, Miniconda prendra le dessus dans les scripts.
    # CUDA toolkit installation (gardé pour les utilisateurs)
    cd /tmp/ && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    # Attention: cela installe sur ubuntu2204. Si kasmvnc:ubuntujammy est 22.04, c'est ok.
    apt-get -y install cuda-toolkit-12-4 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p ${BASE_DIR}/temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs /root/defaults

# Copier les paramètres des UIs
ADD parameters/* ${SD_INSTALL_DIR}/parameters/

# Copier les wheels précompilées (qui auront été placées dans le contexte de build par le workflow)
# Le workflow build-wheels les commite dans precompiled_wheels/, et le checkout les récupère.
RUN mkdir -p /wheels/
COPY precompiled_wheels/*.whl /wheels/
# Les scripts XX.sh pourront alors faire `pip install /wheels/*.whl`

# Copier les scripts de lancement et les rendre exécutables
COPY --chown=abc:abc *.sh ./
RUN chmod +x /entry.sh # et les autres .sh si nécessaire, bien que les scripts XX.sh soient sourcés.

# Configuration de l'utilisateur 'abc' et de Miniconda
ENV XDG_CONFIG_HOME=/home/abc
ENV HOME=/home/abc
RUN mkdir -p /home/abc && \
    chown -R abc:abc /home/abc

# Installer Miniconda pour l'utilisateur 'abc'
# Il est important que Miniconda soit installé après la création de /home/abc et avec les bonnes permissions
# ou que les scripts XX.sh l'installent dans un sous-dossier de $BASE_DIR/$UI_NAME/
# Si tu veux une seule install de Miniconda, il faut la faire en tant que root ou abc dans un lieu partagé.
# Pour l'instant, je garde l'installation de Miniconda que tu avais :
RUN cd /tmp && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \ # Installer dans /opt pour tous
    rm Miniconda3-latest-Linux-x86_64.sh && \
    # Donner les droits à abc si besoin, ou ajouter /opt/miniconda3/bin au PATH global
    # chown -R abc:abc /opt/miniconda3 
    # Les scripts individuels ajouteront /opt/miniconda3/bin à leur PATH.
    chown -R abc:abc ${SD_INSTALL_DIR} # /opt/sd-install
    # chown -R abc:abc /home/abc # Déjà fait

# S'assurer que les scripts dans /opt/sd-install sont utilisables par abc
RUN find ${SD_INSTALL_DIR} -type d -exec chmod 775 {} \; && \
    find ${SD_INSTALL_DIR} -type f -exec chmod 664 {} \;

# S'assurer que /home/abc/miniconda3 est bien celui utilisé par les scripts XX.sh si tu l'installes là
# Tes scripts XX.sh utilisent export PATH="/home/abc/miniconda3/bin:$PATH"
# Donc l'installation de Miniconda doit se faire dans /home/abc/miniconda3 pour l'utilisateur abc.
# Modifions l'install de Miniconda pour qu'elle soit faite PAR abc DANS son home.
# Cela nécessite que l'utilisateur abc existe et ait les droits.
# Plus simple : installer Miniconda dans /opt/miniconda3 et chaque script UI l'utilise.
# La ligne `chown -R abc:abc /root` était étrange, supprimée.

# EXPOSE les ports
EXPOSE 9000/tcp
EXPOSE 3000/tcp

# L'ENTRYPOINT et CMD par défaut viendront de l'image de base kasmvnc,
# ou seront gérés par s6-overlay via /etc/s6-overlay/s6-rc.d/svc-app/run
# qui exécute s6-setuidgid abc /entry.sh