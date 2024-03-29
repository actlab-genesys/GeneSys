#!/bin/sh

## Setting up aws directory
git clone https://github.com/aws/aws-fpga
cd aws-fpga/
source hdk_setup.sh
source sdk_setup.sh
source vitis_setup.sh

## Setting up Platform Location
sudo cp -r /home/centos/aws-fpga/Vitis/aws_platform/xilinx_aws-vu9p-f1_shell-v04261818_201920_3 /opt/Xilinx/Vitis/2021.2/platforms/

## Setting up GeneSys Directory
cd /home/centos/aws-fpga/hdk/cl/developer_designs/
git clone --recurse-submodules https://github.com/actlab-genesys/GeneSys.git

## Establishing conda environment
cd /home/centos/
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash

sudo yum install jsoncpp-devel
sudo  yum groupinstall "X Window System"

source ~/.bashrc
conda env create -f genesys.yml
conda activate genesys

## Compiler setup
cd /home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/compiler/
pip install -e .


cd /home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/