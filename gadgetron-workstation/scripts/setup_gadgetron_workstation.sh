#!/bin/bash

apt-get update

apt-get install --no-install-recommends --no-install-suggests --yes \ 
software-properties-common apt-utils wget build-essential \ 
cython emacs python-dev python-pip python3-dev python3-pip \ 
libhdf5-serial-dev cmake git-core libboost-all-dev libfftw3-dev \ 
h5utils jq hdf5-tools liblapack-dev libopenblas-base libopenblas-dev \ 
libxml2-dev libfreetype6-dev pkg-config libxslt-dev libarmadillo-dev \ 
libace-dev gcc-multilib libgtest-dev python3-dev liblapack-dev liblapacke-dev \
libplplot-dev libdcmtk-dev cmake-curses-gui neofetch net-tools cpio \
x2goserver ubuntu-mate-core


pip install --upgrade pip
pip install -U pip setuptools
apt-get install --no-install-recommends --no-install-suggests --yes python3-psutil python3-pyxb python3-lxml python3-numpy
apt-get install --no-install-recommends --no-install-suggests --yes python3-pil
apt-get install --no-install-recommends --no-install-suggests --yes python3-scipy
apt-get install --no-install-recommends --no-install-suggests --yes python3-configargparse
pip install Cython tk-tools matplotlib scikit-image opencv_python pydicom scikit-learn
pip uninstall -y h5py
apt-get install -y python3-h5py
pip install --upgrade tensorflow
pip install http://download.pytorch.org/whl/cpu/torch-0.4.0-cp36-cp36m-linux_x86_64.whl 
pip install torchvision 
pip install tensorboardx visdom

mkdir -p
cd /opt && \
git clone https://github.com/hansenms/ZFP.git && \
cd ZFP && \
mkdir lib && \
make && \
make shared && \
make -j $(nproc) install

cd /opt && \
wget https://github.com/mrirecon/bart/archive/v0.4.03.tar.gz && \
tar -xzf v0.4.03.tar.gz && \
cd bart-0.4.03 && \
make -j $(nproc) && \
ln -s /opt/bart-v0.4.03/bart /usr/local/bin/bart

apt-get install --yes libgoogle-glog-dev libeigen3-dev libsuitesparse-dev

cd /opt && \
wget http://ceres-solver.org/ceres-solver-1.14.0.tar.gz && \
tar zxf ceres-solver-1.14.0.tar.gz && \
mkdir ceres-bin && \
cd ceres-bin && \
cmake ../ceres-solver-1.14.0 && \
make -j16 && \
make install
