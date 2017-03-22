#!/bin/bash
install_dir=~/.zpm_install/

root=$(pwd)
OS=$(uname)

rm -rf $install_dir || true

mkdir -p $install_dir
cd $install_dir

rm -f premake5.tar.gz || true

if [[ "$OS" == "Darwin" ]]; then
    curl -L -o miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

    premakeURL="https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-macosx.tar.gz"
else
    curl -L -o miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh

    premakeURL="https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-linux.tar.gz"
fi

curl -L -o premake5.tar.gz $premakeURL
tar xzf premake5.tar.gz
chmod a+x premake5

git clone https://github.com/Zefiros-Software/ZPM.git ./zpm --depth 1 -b features/refactor

ZPM_DIR=$(./premake5 show install --file=zpm/zpm.lua)
CONDA_DIR="$ZPM_DIR/conda/"
echo $CONDA_DIR
chmod a+x miniconda.sh
bash miniconda.sh -b -p $CONDA_DIR

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install zpm
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install zpm
fi

cd $root

rm -rf $install_dir

if [[ "$OS" == "Darwin" ]]; then
    source ~/.bash_profile
else
    source ~/.bashrc
fi