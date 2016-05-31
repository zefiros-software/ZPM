sudo rm -rf ~/zpm-install || true
sudo rm -rf /usr/local/zpm/ || true
sudo rm -rf /var/tmp/zpm_cache/ || true

mkdir ~/zpm-install
cd ~/zpm-install

rm premake5.tar.gz || true
rm premake5 || true

wget -O premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha8/premake-5.0.0-alpha8-linux.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://zefiros.eu/stash/scm/zpm/zpm.git

sudo mkdir /usr/local/zpm/ || true
sudo chmod -R 777 /usr/local/zpm/

sudo mkdir /var/tmp/zpm_cache/ || true
sudo chmod -R 777 /var/tmp/zpm_cache/

premake5 --file=zpm/zpm.lua install-zpm

rm -rf ~/zpm-install