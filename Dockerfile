# Build libglvnd
FROM ubuntu:16.04 as glvnd
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        automake \
        autoconf \
        libtool \
        pkg-config \
        python \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/libglvnd
RUN git clone --branch=v1.0.0 https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gcc-multilib \
        libxext-dev:i386 \
        libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*
# 32-bit libraries
RUN make distclean && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/i386-linux-gnu --host=i386-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/i386-linux-gnu -type f -name 'lib*.la' -delete

# Download the official headers from github.com/KhronosGroup
FROM ubuntu:16.04 as khronos
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        git && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/KhronosGroup/OpenGL-Registry.git && cd OpenGL-Registry && \
    git checkout 681c365c012ac9d3bcadd67de10af4730eb460e0 && \
    cp -r api/GL /usr/local/include
RUN git clone https://github.com/KhronosGroup/EGL-Registry.git && cd EGL-Registry && \
    git checkout 0fa0d37da846998aa838ed2b784a340c28dadff3 && \
    cp -r api/EGL api/KHR /usr/local/include
RUN git clone --branch=mesa-17.3.3 --depth=1 https://anongit.freedesktop.org/git/mesa/mesa.git && cd mesa && \
    cp include/GL/gl.h include/GL/gl_mangle.h /usr/local/include/GL/


# cuda
FROM nvidia/cuda:9.0-devel-ubuntu16.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

# cudnn
ENV CUDNN_VERSION 7.0.5.15
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 && \
    rm -rf /var/lib/apt/lists/*

# opengl base
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386 && \
    rm -rf /var/lib/apt/lists/*
# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
        ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
        ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics,compat32,utility
# Required for non-glvnd setups.
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# opengl runtime
COPY --from=glvnd /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu
COPY --from=glvnd /usr/local/lib/i386-linux-gnu /usr/local/lib/i386-linux-gnu
COPY 10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json
RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig
ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# opengl devel
RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        libxau-dev libxau-dev:i386 \
        libxdmcp-dev libxdmcp-dev:i386 \
        libxcb1-dev libxcb1-dev:i386 \
        libxext-dev libxext-dev:i386 \
        libx11-dev libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*
COPY --from=khronos /usr/local/include /usr/local/include
COPY usr /usr


# common 
RUN apt-get update && \
    apt-get install -y apt-utils \
    	    	       git

# japanese
RUN apt-get update && \
    apt-get install -y language-pack-ja-base \
    	    	       language-pack-ja
ENV LANG ja_JP.UTF-8

# emacs
RUN apt-get update && \
    apt-get install -y emacs24-nox \
		       emacs24-el \
		       emacs-mozc \
		       emacs-mozc-bin \
      		       xclip
# anaconda
RUN apt-get update && \
    apt-get install -y wget \
    	    	       bzip2 \
		       libglib2.0-0 \
		       libxext6 \
		       libsm6 \
		       libxrender1 \
       		       libgl1-mesa-dev && \
    wget http://repo.continuum.io/archive/Anaconda3-5.1.0-Linux-x86_64.sh && \
    bash Anaconda3-5.1.0-Linux-x86_64.sh -b -p /usr/local/bin/anaconda3 && \
    rm Anaconda3-5.1.0-Linux-x86_64.sh

ENV PATH $PATH:/usr/local/bin/anaconda3/bin

# pyopengl and opencv
RUN apt-get update && \
    apt-get install -y freeglut3-dev \
 		       gcc && \
    /usr/local/bin/anaconda3/bin/pip install --upgrade pip && \
    /usr/local/bin/anaconda3/bin/pip install PyOpenGL \
    				     	     PyOpenGL_accelerate \
					     opencv-python
ENV QT_X11_NO_MITSHM 1

# tensorflow
RUN /usr/local/bin/anaconda3/bin/pip install --ignore-installed --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.6.0-cp36-cp36m-linux_x86_64.whl

# keras
RUN /usr/local/bin/anaconda3/bin/pip install keras

# pytorch
RUN /usr/local/bin/anaconda3/bin/pip install http://download.pytorch.org/whl/cu90/torch-0.3.1-cp36-cp36m-linux_x86_64.whl 
RUN /usr/local/bin/anaconda3/bin/pip install torchvision

# pycharm
RUN wget https://download.jetbrains.com/python/pycharm-community-2018.1.tar.gz && \
    tar xvfz pycharm-community-2018.1.tar.gz --directory /opt && \
    rm pycharm-community-2018.1.tar.gz && \
    apt-get update && \
    apt-get install -y libxtst6 \
    	    	       fonts-takao
# printer
# RUN wget http://download.brother.com/welcome/dlf101123/brgenml1lpr-3.1.0-1.i386.deb
#     wget http://download.brother.com/welcome/dlf101125/brgenml1cupswrapper-3.1.0-1.i386.deb
# RUN dpkg -i --force-all brgenml1lpr-3.1.0-1.i386.deb
# RUN dpkg -i --force-all brgenml1cupswrapper-3.1.0-1.i386.deb
# RUN apt-get install -y cups
# RUN rm brgenml1lpr-3.1.0-1.i386.deb
#    rm brgenml1cupswrapper-3.1.0-1.i386.deb

# x window
ARG uid
ARG gid
ARG user
ARG group
RUN apt-get update && \
    apt-get install -y sudo && \
    groupadd -g ${gid} ${group} && \
#    useradd -u ${uid} -g ${gid} -r ${user}
    useradd -u ${uid} -g ${gid} -r ${user} -G sudo && \
    echo ${user}:${user} | chpasswd
    
# CMD /bin/bash
CMD /opt/pycharm-community-2018.1/bin/pycharm.sh