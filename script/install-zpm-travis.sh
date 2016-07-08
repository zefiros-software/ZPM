#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 
    sudo apt-get install git-lfs=1.2.1
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
    brew install git-lfs
fi