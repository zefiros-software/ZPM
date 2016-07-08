#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt-get update
    sudo apt-get install git -y
    sudo apt-get install git-lfs -y
    git-lfs install
    git-lfs version
    git lfs version
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
    brew update;
    brew install git-lfs;
    git-lfs install
fi