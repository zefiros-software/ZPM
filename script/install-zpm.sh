#!/bin/bash
sudo rm -rf ~/zpm-install || true
sudo rm -rf /usr/local/zpm/ || true
sudo rm -rf /var/tmp/zpm-cache/ || true

mkdir ~/zpm-install
cd ~/zpm-install

rm premake5.tar.gz || true
rm premake5 || true

wget -O premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha9/premake-5.0.0-alpha9-linux.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

sudo mkdir /usr/local/zpm/ || true
sudo mkdir /var/tmp/zpm-cache/ || true

sudo chmod -R 777 /usr/local/zpm/
sudo setfacl -d -m u::rwX,g::rwX,o::- /usr/local/zpm/

sudo chmod -R 777 /var/tmp/zpm-cache/
sudo setfacl -d -m u::rwX,g::rwX,o::- /var/tmp/zpm-cache/

./premake5 --file=zpm/zpm.lua install-zpm

sudo chmod -R 777 /usr/local/zpm/
sudo setfacl -d -m u::rwX,g::rwX,o::- /usr/local/zpm/

sudo chmod -R 777 /var/tmp/zpm-cache/
sudo setfacl -d -m u::rwX,g::rwX,o::- /var/tmp/zpm-cache/

rm -rf ~/zpm-install