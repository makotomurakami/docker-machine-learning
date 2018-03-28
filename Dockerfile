# cuda
FROM nvidia/cuda:9.0-runtime-ubuntu16.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

# cudnn
ENV CUDNN_VERSION 7.0.5.15
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda9.0 && \
    rm -rf /var/lib/apt/lists/*

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
RUN wget https://download.jetbrains.com/python/pycharm-community-2017.3.4.tar.gz && \
    tar xvfz pycharm-community-2017.3.4.tar.gz --directory /opt && \
    rm pycharm-community-2017.3.4.tar.gz && \
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
CMD /opt/pycharm-community-2017.3.4/bin/pycharm.sh