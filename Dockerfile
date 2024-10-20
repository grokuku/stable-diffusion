#FROM lsiobase/ubuntu:jammy as base
FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy as base

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp

    RUN apt-get update -y -q=2 && \
    apt-get install -y -q=2 curl \
    software-properties-common \
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
    ffmpeg \
#    dotnet-sdk-8.0 \
#    firefox \
    git \
    lsof && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN add-apt-repository -y ppa:mozillateam/ppa && apt-get update
RUN echo 'Package: firefox* \nPin: release o=LP-PPA-mozillateam \nPin-Priority: 1001' > /etc/apt/preferences.d/mozillateamppa
RUN apt-get update
RUN apt-get install -y firefox
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
RUN chmod +x ./dotnet-install.sh
RUN ./dotnet-install.sh  --channel 8.0

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

#RUN groupmod -g 1000 abc
#RUN  usermod -u 1000 abc
RUN mkdir -p /root/defaults
RUN echo "firefox" > root/defaults/autostart
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
