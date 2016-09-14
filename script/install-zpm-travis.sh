#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 
    sudo apt-get update
    sudo add-apt-repository ppa:git-core/ppa
    sudo apt-get install git -y
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo rm /usr/local/bin/git-lfs || true
    sudo rm /usr/bin/git-lfs || true
    sudo apt-get install git-lfs -y
    /usr/bin/git-lfs install
    sudo apt-get install g++-multilib -y
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
    brew update;
    brew install git
    brew install git-lfs;
    git-lfs install
fi