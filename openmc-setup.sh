#!/bin/bash

# Copyright (c) 2023; Saad Islam AMEI All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#    *   Redistributions of source code must retain the above copyright notice,
#        this list of conditions and the following disclaimer.
#    *   Redistributions in binary form must reproduce the above
#        copyright notice, this list of conditions and the following
#        disclaimer in the documentation and/or other materials provided
#        with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# This script installs the latest develop of OpenMC and sets up the official ENDFB/VIII.0 HDF5
# libs. The compiled binary will have multithreading (OMP) enabled for a single host with one or
# more sockets. For a multihost/cluster binary, please contact DU-ARDS.
#
# Additionally, the OpenMC python API, Jupyter notebook and python math packages will be installed.
#
# Note that the cross-section tables are limited to the following six material temperatures:
# 250 K, 293.6 K, 600 K, 900 K, 1200 K, and 2500 K. For additional cross-section table at different
# temperature points (for example, neutronics-TH coupled analysis or neuclear thermal rocket
# design), please contact DU-ARDS.
#
# For instruction visit the release,
# https://github.com/du-ards/openmc-setup
#
#
# Todo: exception handling (symlink already exists )
#
echo
echo "*** DU-ARDS OpenMC setup script ***"
echo
dir=$PWD
dirPath="openmc"
# Make the path to library directory absolute
dirPath=$PWD/$dirPath
if [ -d $dirPath ] 
then
    # this step is necessary when restarting from a failed attempt
    echo 
    echo "Error: directory exists" 
    cd $dirPath
    chmod ugo+w .
    chattr -i -a .
    sudo rm -rf *
    cd ..
    rm -r openmc
#        exit 1
else
    echo
    echo "*** Dir check complete ***"
fi
echo "*** Distro info ***"
cat /etc/*-release
echo
echo "*** Intalling dependencies ***"
echo
sudo apt-get update && sudo apt-get upgrade -y 
sudo apt-get install g++ cmake libhdf5-dev libpng-dev libomp-dev libomp5 mpich libmpich-dev git -y
echo "*** Cloning into openmc-dev ***"
cd $dir
git clone https://github.com/openmc-dev/openmc.git
cd openmc
git checkout develop
mkdir build && cd build
cmake -DOPENMC_USE_OPENMP=on ..
make
echo "*** Compilation done! ****"
echo
echo "*** Creating symbolic link ***"
sudo ln -s $dir/openmc/build/bin/openmc /usr/bin/openmc
cd ..
echo
echo "*** Installing the Python API and dependencies ***"
sudo apt install python3-pip python3-dev
sudo -H pip3 install --upgrade pip
sudo pip install numpy vtk jupyter
sudo pip install .
cd $dir
echo "*** API installation complete ***"
echo
echo "*** Downloading cross-section libraries ***"
wget https://anl.box.com/shared/static/9igk353zpy8fn9ttvtrqgzvw1vtejoz6.xz
echo
echo "*** Extracting ***"
tar xf 9igk353zpy8fn9ttvtrqgzvw1vtejoz6.xz
echo 
echo "*** Setting up environment variables ***"
echo "export OPENMC_CROSS_SECTIONS='$dir/endfb-viii.0-hdf5/cross_sections.xml'" >> $HOME/.bashrc
source $HOME/.bashrc
cd $dir
echo "OpenMC setup done!"
echo "Please try the following: "
echo "openmc --version"
