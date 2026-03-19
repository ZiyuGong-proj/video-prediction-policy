FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10
ARG CALVIN_REPO=https://github.com/mees/calvin.git
ARG CALVIN_REF=main
ARG INSTALL_XFORMERS=0

ENV TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    CALVIN_ROOT=/opt/calvin \
    VPP_ROOT=/workspace/video-prediction-policy \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
    PYOPENGL_PLATFORM=egl \
    MUJOCO_GL=egl \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;9.0+PTX"

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    libegl1 \
    libffi-dev \
    libgeos-dev \
    libgl1 \
    libgl1-mesa-dev \
    libglib2.0-0 \
    libglvnd0 \
    libglx0 \
    libglew-dev \
    libglib2.0-dev \
    libglfw3 \
    libglfw3-dev \
    libjpeg-dev \
    libopenexr-dev \
    libosmesa6 \
    libosmesa6-dev \
    libsm6 \
    libssl-dev \
    libtbb-dev \
    libx11-6 \
    libxext6 \
    libxrender1 \
    pkg-config \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    software-properties-common \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    python -m venv ${VIRTUAL_ENV} && \
    pip install --upgrade pip wheel "setuptools<58"

RUN git clone --recurse-submodules ${CALVIN_REPO} ${CALVIN_ROOT} && \
    cd ${CALVIN_ROOT} && \
    git checkout ${CALVIN_REF} && \
    git submodule update --init --recursive

WORKDIR ${VPP_ROOT}
COPY requirements.txt /tmp/vpp-requirements.txt

RUN pip install --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 && \
    pip install --extra-index-url https://download.pytorch.org/whl/cu118 -r /tmp/vpp-requirements.txt && \
    pip install \
      cython \
      h5py \
      mediapy \
      peft \
      pyhash==0.9.3

RUN if [[ "${INSTALL_XFORMERS}" == "1" ]]; then \
      pip install xformers; \
    fi

RUN cd ${CALVIN_ROOT} && sh install.sh

COPY . ${VPP_ROOT}

ENV PYTHONPATH=${VPP_ROOT}:${CALVIN_ROOT}:${CALVIN_ROOT}/calvin_models:${PYTHONPATH}

WORKDIR ${VPP_ROOT}
CMD ["/bin/bash"]
