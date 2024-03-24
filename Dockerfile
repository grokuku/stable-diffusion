FROM lsiobase/ubuntu:jammy as base

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
#    SD01_DIR=${BASE_DIR}/01-easy-diffusion \
    SD02_DIR=${BASE_DIR}/02-sd-webui \
    SD03_DIR=${BASE_DIR}/03-invokeai \
    SD04_DIR=${BASE_DIR}/04-SD-Next \
    SD05_DIR=${BASE_DIR}/05-comfy-ui \
    SD06_DIR=${BASE_DIR}/06-Fooocus \
    SD07_DIR=${BASE_DIR}/07-StableSwarm \
    SD08_DIR=${BASE_DIR}/08-voltaML \
    SD20_DIR=${BASE_DIR}/20-kubin \
    SD50_DIR=${BASE_DIR}/50-IOPaint \
    SD51_DIR=${BASE_DIR}/51-facefusion \
    SD70_DIR=${BASE_DIR}/70-kohya \
    XDG_CACHE_HOME=/config/temp

RUN apt-get update -y -q=2 && \
    apt-get install -y -q=2 curl \
    wget \
    mc \
    bc \
    nano \
    rsync \
    libgl1-mesa-glx \
    libtcmalloc-minimal4 \
    libcufft10 \
    cmake \
    build-essential \
    python3-opencv \
    libopencv-dev \
    dotnet-sdk-8.0 \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

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
    chown -R abc:abc ${SD_INSTALL_DIR}


EXPOSE 9000/tcp
