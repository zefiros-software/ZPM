#!/bin/bash
install_dir=~/.zpm_install/
shared_dir=~/.zpm/zpm/
cache_dir=~/.zpm/zpm-cache/

echo "Shared directory: ${shared_dir}"
echo "Cache directory: ${cache_dir}"

rm -rf $install_dir || true
rm -rf $shared_dir || true
rm -rf $cache_dir || true

mkdir -p $install_dir
cd $install_dir

rm -f premake5.tar.gz || true

wget -O premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-linux.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

mkdir -p $shared_dir || true
mkdir -p $cache_dir || true

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install-zpm
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install-zpm
fi

rm -rf $install_dir