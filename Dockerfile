######## Ubuntu 16.04 ########
######## CUDA 9.0 + OpenGL (glvnd 1.1) ########

######## OpenGL(glvnd 1.1) runtime 1st half ########
######## glvnd/runtime/Dockerfile 1st half ########
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
ARG LIBGLVND_VERSION=v1.1.0
WORKDIR /opt/libglvnd
RUN git clone --branch="${LIBGLVND_VERSION}" https://github.com/NVIDIA/libglvnd.git . && \
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

######## OpenGL(glvnd 1.1) devel 1st half ########
######## glvnd/devel/Dockerfile 1st half ########
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

######## cuda 9.0 devel ########
######## cudnn 7.4.1.5 ########
######## 9.0/devel/cudnn7/Dockerfile ########
# ARG repository=nvidia/cuda
# FROM ${repository}:9.0-devel-ubuntu16.04
FROM nvidia/cuda:9.0-devel-ubuntu16.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"
ENV CUDNN_VERSION 7.4.1.5
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

######## OpenGL(glvnd 1.1) base ########
######## base/Dockerfile ########
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

######## OpenGL(glvnd 1.1) runtime 2st half ########
######## glvnd/runtime/Dockerfile 2st half ########
COPY --from=glvnd /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu
COPY --from=glvnd /usr/local/lib/i386-linux-gnu /usr/local/lib/i386-linux-gnu
COPY 10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json
RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig
ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

######## OpenGL(glvnd 1.1) devel 2nd half ########
######## glvnd/devel/Dockerfile 2nd half ########
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
ARG anaconda_dir="/usr/local/bin/anaconda3"
ARG anaconda_file="Anaconda3-5.2.0-Linux-x86_64.sh"
RUN apt-get update && \
    apt-get install -y wget \
    	    	       bzip2 \
		       libglib2.0-0 \
		       libxext6 \
		       libsm6 \
		       libxrender1 \
       		       libgl1-mesa-dev && \
    wget http://repo.continuum.io/archive/${anaconda_file} && \
    bash ${anaconda_file} -b -p ${anaconda_dir} && \
    rm ${anaconda_file}
ENV PATH ${anaconda_dir}/bin:$PATH

# pyopengl
RUN apt-get update && \
    apt-get install -y freeglut3-dev \
 		       gcc && \
    pip install --upgrade pip && \
    pip install PyOpenGL \
    		PyOpenGL_accelerate

# dlib
RUN apt-get update && \
    apt-get install -y cmake && \
    pip install dlib

ENV QT_X11_NO_MITSHM 1

# eigen
ARG eigen_version="3.3.7"
RUN apt-get update && \
    apt-get install -y wget && \
    wget http://bitbucket.org/eigen/eigen/get/${eigen_version}.tar.gz && \
    tar xvfz ${eigen_version}.tar.gz -C /usr/local/include && \
    mv /usr/local/include/eigen* /usr/local/include/eigen && \    
    rm ${eigen_version}.tar.gz

# build-essential, cmake
RUN apt-get update && \
    apt-get install -y build-essential \
    	    	       cmake

# opencv
ARG opencv_version="4.0.1"
RUN apt-get update && \
    apt-get install -y pkg-config \
		       libtbb2 \
		       libtbb-dev \
		       libjasper-dev \
		       libdc1394-22-dev \
		       libjpeg-dev \
     	     	       libpng-dev \
		       libtiff-dev \
		       libavcodec-dev \
		       libavformat-dev \
		       libswscale-dev \
		       libv4l-dev \
		       libxvidcore-dev \
		       libx264-dev \
		       libgtk-3-dev \
		       libatlas-base-dev \
		       gfortran \
		       doxygen \
    	    	       doxygen-gui \
		       graphviz \
		       libopenblas-dev \
		       liblapacke-dev		       
RUN mkdir opencv_tmp && \
    cd opencv_tmp && \
    git clone https://github.com/opencv/opencv.git && \
    git clone https://github.com/opencv/opencv_contrib.git && \
    cd opencv_contrib && \
    git checkout ${opencv_version} && \
    cd ../opencv && \
    git checkout ${opencv_version} && \    
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    	  -D CMAKE_INSTALL_PREFIX=${anaconda_dir} \
	  -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
	  -D OPENCV_ENABLE_NONFREE=ON \	  
	  -D BUILD_DOCS=ON \
 	  -D BUILD_EXAMPLES=ON \
	  -D BUILD_opencv_python3=ON \
	  -D BUILD_opencv_python2=OFF \	  
	  -D PYTHON_DEFAULT_EXECUTABLE=${anaconda_dir}/bin/python \
    	  -D PYTHON3_EXECUTABLE=${anaconda_dir}/bin/python \
    	  -D PYTHON3_LIBRARIES=${anaconda_dir}/lib/libpython3.6m.so \
    	  -D PYTHON3_NUMPY_INCLUDE_DIRS=${anaconda_dir}/lib/python3.6/site-packages/numpy/core/include \
	  -D PYTHON3_PACKAGES_PATH=${anaconda_dir}/lib/python3.6/site-packages \
    	  -D WITH_EIGEN=ON \
	  -D EIGEN_INCLUDE_PATH=/usr/local/include/eigen \
	  -D WITH_OPENGL=ON \
	  -D WITH_TBB=ON \
	  -D WITH_OPENMP=ON \
	  -D WITH_OPENCL=ON \
	  -D WITH_OPENCL_SVM=ON \
	  -D WITH_LAPACK=ON \	  
	  -D WITH_CUDA=ON \
	  -D WITH_CUFFT=ON \
	  -D WITH_CUBLAS=ON \
	  -D WITH_NVCUVID=ON \
	  .. && \
    make -j7 && \
    make install && \
    ldconfig -v && \
    ln -s ${anaconda_dir}/python/cv2/python-3.6/cv2.cpython-36m-x86_64-linux-gnu.so ${anaconda_dir}/lib/python3.6/site-packages/cv2.so
ENV NO_AT_BRIDGE 1

# pytorch
RUN pip install http://download.pytorch.org/whl/cu90/torch-1.0.0-cp36-cp36m-linux_x86_64.whl && \
    pip install torchvision && \
    pip install torchsummary

# tensorflow
RUN pip install tensorflow-gpu

# keras
RUN pip install keras

# gensim, word2vec
RUN pip install gensim

# pycharm
ARG pycharm_version="community-2018.3.5"
RUN wget https://download.jetbrains.com/python/pycharm-${pycharm_version}.tar.gz && \
    tar xvfz pycharm-${pycharm_version}.tar.gz --directory /opt && \
    rm pycharm-${pycharm_version}.tar.gz && \
    apt-get update && \
    apt-get install -y libxtst6 \
    	    	       fonts-takao && \
    python3 /opt/pycharm-${pycharm_version}/helpers/pydev/setup_cython.py build_ext --inplace
ENV PATH $PATH:/opt/pycharm-${pycharm_version}/bin

# x window
ARG uid
ARG gid
ARG user
ARG group
RUN apt-get update && \
    apt-get install -y sudo && \
    groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${gid} -r ${user} -G sudo,video && \
    echo ${user}:${user} | chpasswd

# CMD /bin/bash
CMD pycharm.sh
