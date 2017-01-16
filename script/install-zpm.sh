#!/bin/bash
install_dir=~/.zpm_install/
shared_dir=/usr/local/zpm/
cache_dir=/var/tmp/zpm-cache/
local_install=false

while getopts "u" opt; do
    case "$opt" in
    u)
        shared_dir=~/.zpm/zpm/
        cache_dir=~/.zpm/zpm-cache/
        local_install=true
    ;;
    esac
done

SUD=""
if [ "$local_install" == false ]; then
  SUD="sudo"
fi

echo "Shared directory:"
echo $shared_dir
echo "Cache directory:"
echo $cache_dir

rm -rf $install_dir || true
rm -rf $shared_dir || true
rm -rf $cache_dir || true

mkdir -p $install_dir
cd $install_dir

rm premake5.tar.gz || true
rm premake5 || true

wget -O premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-linux.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

${SUD} mkdir -p $shared_dir || true
${SUD} mkdir -p $cache_dir || true

${SUD} chmod -R 777 $shared_dir
${SUD} setfacl -d -m u::rwX,g::rwX,o::- $shared_dir

${SUD} chmod -R 777 $cache_dir
${SUD} setfacl -d -m u::rwX,g::rwX,o::- $cache_dir

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install-zpm;
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install-zpm;
fi

${SUD} chmod -R 777 $shared_dir
${SUD} setfacl -d -m u::rwX,g::rwX,o::- $shared_dir

${SUD} chmod -R 777 $cache_dir
${SUD} setfacl -d -m u::rwX,g::rwX,o::- $cache_dir

rm -rf $install_dir