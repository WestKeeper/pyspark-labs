# Defining base image
ARG VERSION=latest
ARG SOURCE_IMAGE_NAME=jupyter/pyspark-notebook:${VERSION}
FROM ${SOURCE_IMAGE_NAME} as base

LABEL maintainer "SemeniutaAV"

# To get rid of permission error while installation
USER root

# Install third party requirements
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    software-properties-common \
    pkg-config \
    tzdata \
    git \
    cmake \
    wget \
    curl \
    vim \
    sudo

# Create a user to map from docker host
ARG USER_ID
ARG GROUP_ID
ARG USER_NAME
RUN if id ${USER_NAME} >/dev/null 2>&1; then userdel -f -r ${USER_NAME}; fi \
    && if getent group ${USER_NAME}; then groupdel ${USER_NAME}; fi \
    && groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -l -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash -m ${USER_NAME} \
    && usermod -aG sudo ${USER_NAME}

# Enable sudo without password
RUN echo ${USER_NAME}'     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure datetime and time zone
RUN dpkg-reconfigure -f noninteractive tzdata

# Python environment and arguments
ENV LANG C.UTF-8
ARG PYTHON=python3.9
ARG PIP='python3.9 -m pip'

# Installing Python3.9
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update && apt-get install -y \
    ${PYTHON} \
    ${PYTHON}-dev \
    ${PYTHON}-venv \
    python3-pip \
    python3-distutils \
    python3-setuptools
RUN ${PIP} install --no-cache-dir --upgrade pip setuptools wheel pipdeptree

# Install development required pip packages
COPY ./requirements.txt ./
RUN ${PIP} install --no-cache-dir -r requirements.txt \
    && rm requirements.txt

# Specify working dir for a project
ARG WORKING_DIR=/usr/src/app
WORKDIR ${WORKING_DIR}

# Customize command prompt
RUN echo 'PS1="SemeniutaAV>:\w\$ "' >> /etc/bash.bashrc

# Setting up user environment
USER ${USER_NAME}
ENV LANG C.UTF-8
