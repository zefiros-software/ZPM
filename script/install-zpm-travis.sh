#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    sudo apt-get update
    sudo add-apt-repository ppa:git-core/ppa -y
    sudo apt-get install git -y
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo rm -f /usr/local/bin/git-lfs || true
    sudo rm -f /usr/bin/git-lfs || true
    sudo apt-get install git-lfs -y
    /usr/bin/git-lfs install

    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
    brew update;
    brew unlink git
    brew install git
    brew install git-lfs;
    git-lfs install
fi
