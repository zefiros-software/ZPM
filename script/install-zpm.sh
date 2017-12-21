#!/bin/bash
install_dir=~/.zpm_install/

root=$(pwd)
OS=$(uname)

rm -rf $install_dir || true

mkdir -p $install_dir
cd $install_dir

# compile premake5
git clone https://github.com/Zefiros-Software/premake-core.git
cd premake-core


if [[ "$OS" == "Darwin" ]]; then
    make -f Bootstrap.mak osx
else    
    make -f Bootstrap.mak linux
fi

make -C build/bootstrap -j config=debug
cd ../
mv premake-core/bin/release/premake5 premake5

# continue installation
chmod a+x premake5

git clone https://github.com/Zefiros-Software/ZPM.git ./zpm --depth 1 --quiet -b features/refactor

ZPM_DIR=$(./premake5 show install --file=zpm/zpm.lua | xargs) 

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install zpm
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install zpm
fi

cd $root

rm -rf $install_dir

source ~/.profile
