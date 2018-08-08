#!/bin/bash

mkdir -p ${HOME}/code
mkdir -p ${HOME}/local

GADGETRON_HOME=${HOME}/local
ISMRMRD_HOME=${HOME}/local

#ISMRMRD
cd ${HOME}/code
git clone https://github.com/ismrmrd/ismrmrd.git
cd ismrmrd
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=~/local -DCMAKE_PREFIX_PATH=~/local ../
make -j $(nproc)
make install

#GADGETRON
cd ${HOME}/code
git clone https://github.com/gadgetron/gadgetron
cd gadgetron
mkdir build
cd build 
cmake -DBUILD_WITH_PYTHON3=ON -DCMAKE_INSTALL_PREFIX=~/local -DCMAKE_PREFIX_PATH=~/local ../
make -j $(nproc)
make install
cp ${GADGETRON_HOME}/share/gadgetron/config/gadgetron.xml.example ${GADGETRON_HOME}/share/gadgetron/config/gadgetron.xml

#ISMRMRD PYTHON API
cd ${HOME}/code
git clone https://github.com/ismrmrd/ismrmrd-python.git
cd ismrmrd-python
python3 setup.py install --user

#ISMRMRD PYTHON TOOLS
cd ${HOME}/code
git clone https://github.com/ismrmrd/ismrmrd-python-tools.git
cd ismrmrd-python-tools
python3 setup.py install --user

#SIEMENS_TO_ISMRMRD
cd ${HOME}/code
git clone https://github.com/ismrmrd/siemens_to_ismrmrd.git
cd siemens_to_ismrmrd
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${HOME}/local -DCMAKE_PREFIX_PATH=${HOME}/local ../
make -j $(nproc) 
make install

#PHILIPS_TO_ISMRMRD
cd ${HOME}/code
git clone https://github.com/ismrmrd/philips_to_ismrmrd.git
cd philips_to_ismrmrd
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${HOME}/local -DCMAKE_PREFIX_PATH=${HOME}/local ../
make -j $(nproc)
make install

#Setup environment
echo "" >> ${HOME}/.bashrc 
echo 'export GADGETRON_HOME=${HOME}/local' >> ${HOME}/.bashrc
echo 'export LD_LIBRARY_PATH=${GADGETRON_HOME}/lib:${LD_LIBRARY_PATH}' >> ${HOME}/.bashrc
echo 'export PATH=${GADGETRON_HOME}/bin:${PATH}' >> ${HOME}/.bashrc
