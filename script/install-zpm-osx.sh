#!/bin/bash
install_dir=~/.zpm_install/
shared_dir=~/.zpm/zpm/
cache_dir=~/.zpm/zpm-cache/
local_install=true

while getopts "g" opt; do
    case "$opt" in
    g)        
        shared_dir=/usr/local/zpm/
        cache_dir=/var/tmp/zpm-cache/
        local_install=false
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

mkdir $install_dir
cd $install_dir

rm -f premake5.tar.gz || true
rm -f premake5 || true

wget https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-macosx.tar.gz -O premake5.tar.gz

tar xvzf premake5.tar.gz
chmod a+x premake5
git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

${SUD} mkdir $shared_dir || true
${SUD} mkdir $shared_dir || true

${SUD} chmod -R 775 $shared_dir
${SUD} chmod -R 775 $shared_dir

if [ -z "$GH_TOKEN" ]; then
    ./premake5 --file=zpm/zpm.lua install-zpm;
else
    ./premake5 --github-token=$GH_TOKEN --file=zpm/zpm.lua install-zpm;
fi

${SUD} chmod -R 775 $shared_dir
${SUD} chmod -R 775 $shared_dir

rm -rf $install_dir
