FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"

RUN apt-get update -q && \
    apt-get install -y -q=2 curl \
    software-properties-common \
    wget \
    gnupg \
    mc \
    bc \
    nano \
    rsync \
    libgl1-mesa-glx \
    libtcmalloc-minimal4 \
    libcufft10 \
    libxft2 \
    xvfb \
    cmake \
    build-essential \
    ffmpeg \
    gcc-12 \
    g++-12 \
    dotnet-sdk-8.0 \
    git && \
    apt purge gcc-11 g++-11 -y && \
    apt-get purge python3 -y && \
# CUDA toolkit installation
    cd /tmp/ && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-4 && \
# CLEAN
    apt autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

RUN mkdir -p /root/defaults

COPY --from=builder /build/*.whl /wheels/

COPY --chown=abc:abc *.sh ./
RUN chmod +x /entry.sh

ENV XDG_CONFIG_HOME=/home/abc
ENV HOME=/home/abc
RUN mkdir /home/abc && \
    chown -R abc:abc /home/abc

RUN cd /tmp && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    chown -R abc:abc /root && \
    chown -R abc:abc ${SD_INSTALL_DIR} && \
    chown -R abc:abc /home/abc

EXPOSE 9000/tcp
EXPOSE 3000/tcp
