#!/bin/bash

install_dir=~/zpm-install
shared_dir=/usr/local/zpm/
cache_dir=/var/tmp/zpm-cache/

while getopts "p:" opt; do
    case "$opt" in
    p)
        shared_dir=$OPTARG"/zpm/"
        shared_dir=$OPTARG"/zpm-cache/"
    ;;
    esac
done

sudo rm -rf ~/zpm-install || true
sudo rm -rf /usr/local/zpm/ || true
sudo rm -rf /var/tmp/zpm-cache/ || true

mkdir ~/zpm-install
cd ~/zpm-install

rm premake5.tar.gz || true
rm premake5 || true

wget -O premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-linux.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

sudo mkdir /usr/local/zpm/ || true
sudo mkdir /var/tmp/zpm-cache/ || true

sudo chmod -R 777 /usr/local/zpm/
sudo setfacl -d -m u::rwX,g::rwX,o::- /usr/local/zpm/

sudo chmod -R 777 /var/tmp/zpm-cache/
sudo setfacl -d -m u::rwX,g::rwX,o::- /var/tmp/zpm-cache/

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install-zpm;
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install-zpm;
fi

sudo chmod -R 777 /usr/local/zpm/
sudo setfacl -d -m u::rwX,g::rwX,o::- /usr/local/zpm/

sudo chmod -R 777 /var/tmp/zpm-cache/
sudo setfacl -d -m u::rwX,g::rwX,o::- /var/tmp/zpm-cache/

rm -rf ~/zpm-install