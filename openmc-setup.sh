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
# design), please contact DU-ARDS for support.
#
# For instruction visit the release,
# https://github.com/du-ards/openmc-setup
#
#
# Todo: exception handling 
#    symlink already exists; done 
#    cmake server down; done 
#    xs repo suffix; done 
#    git privilege issue on win 22h2 wsl2; workaround for now: install on ~ directory  
#    set -e global exit on any error disabled;
# 
echo 
echo "*** DU-ARDS OpenMC setup script ***"
echo "Script version 0.0.2"
echo "Git SHA1: 67b0b484ebb74c2cb77253035733d6c840bec8aa"
echo "Copyright (c) 2023; Saad Islam AMEI All rights reserved."
echo "GNU/GPL license at <https://github.com/du-ards/openmc-setup/blob/main/LICENSE>"
dir=$PWD
dirPath="openmc"
# Make the path to library directory absolute
dirPath=$PWD/$dirPath
if [ -d $dirPath ] 
then
    # this step is necessary when restarting from a failed attempt
    echo 
    echo "*** Directory exists; cleaning... *** " 
    echo
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
    echo
fi
echo "*** Distro info ***"
echo
cat /etc/*-release
echo 
while true; do
    read -p "Do you wish to continue with the setup? [Y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo
echo "*** Intalling dependencies ***"
echo
sudo apt-get update && sudo apt-get upgrade -y 
sudo apt-get install g++ cmake libhdf5-dev libpng-dev libomp-dev libomp5 mpich libmpich-dev git -y
echo
echo "*** Cloning into openmc-dev ***"
echo
cd $dir # just pwd 
# mkdir openmc
git clone https://github.com/openmc-dev/openmc.git
if [ $? -eq 0 ]
then
echo 
echo "*** Cloning into openmc-dev successful ***"
echo 
else
echo "OpenMC cloning failed! This is probably due to one of the following reasons: "
echo "1. Internet connection issue"
echo "2. Git couldn't resolve file ownership privileges on the local machine; this is a recurring issue on a Win11 WSL machine when attempting cloning on an /mnt drive. Either fix git ownership privileges or try installing on your ~ directory."
echo 
echo "*** Setup failed! ***"
echo 
exit 1
fi
cd openmc
git checkout develop
mkdir build && cd build
cmake -DOPENMC_USE_OPENMP=on ..
if [ $? -eq 0 ]
then
echo 
echo "*** Cmake configuration successful ***"
echo 
else
echo "Cmake configuration failed! This is probably due to one of the following reasons: "
echo "1. Unresolved dependencies"
echo 
echo "*** Setup failed! ***"
echo 
exit 1
fi
make
if [ $? -eq 0 ]
then
echo 
echo "*** Compilation successful  ***"
echo 
else
echo "Compilation failed! This is probably due to one of the following reasons: "
echo "1. Cmake profiling error"
echo "2. Unresolved dependencies"
echo "3. Incompatible compiler"
echo 
echo "*** Setup failed! ***"
echo 
exit 1
fi
echo "*** Creating symbolic link ***"
sudo ln -s $dir/openmc/build/bin/openmc /usr/bin/openmc
if [ $? -eq 0 ]
then
echo 
echo "*** Symbolic link creation successful ***"
echo 
else
echo 
echo "Symbolic link creation failed! This is probably due to one of the following reasons: "
echo "1. Symbolic link already exists with the same name in /usr/bin"
echo
echo "*** Setup failed! ***"
echo 
exit 1
fi
cd ..
echo
echo "*** Installing the Python API and dependencies ***"
sudo apt install python3-pip python3-dev
sudo -H pip3 install --upgrade pip
sudo pip install numpy vtk jupyter
sudo pip install .
cd $dir
echo
echo "*** API installation complete ***"
echo
echo "*** Downloading cross-section libraries ***"
wget https://anl.box.com/shared/static/uhbxlrx7hvxqw27psymfbhi7bx7s6u6a.xz
if [ $? -eq 0 ]
then
echo 
echo "*** Library download successful ***"
echo 
else
echo 
echo "Dowload failed! This is probably due to one of the following reasons: "
echo "1. Link is not valid"
echo "2. Internet issue"
echo
echo "*** Setup failed! ***"
echo 
exit 1
fi
echo
echo "*** Extracting ***"
echo
tar xf uhbxlrx7hvxqw27psymfbhi7bx7s6u6a.xz
rm uhbxlrx7hvxqw27psymfbhi7bx7s6u6a.xz
echo 
echo "*** Setting up environment variables ***"
echo
echo "export OPENMC_CROSS_SECTIONS='$dir/endfb-viii.0-hdf5/cross_sections.xml'" >> $HOME/.bashrc
source $HOME/.bashrc
cd $dir
echo
echo "*** OpenMC setup done! ***"
echo 
echo "*** Exiting DU-ARDS OpenMC setup script ***"
echo
echo "Please try the following two commands: "
echo
echo "1. echo \$OPENMC_CROSS_SECTIONS"
echo "2. openmc --version"

