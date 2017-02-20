#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    sudo apt-get update
    sudo add-apt-repository ppa:git-core/ppa -y
    sudo apt-get install git -y
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/features/refactor/script/install-zpm.sh | bash
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    brew update
    brew unlink git
    brew install git
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/features/refactor/script/install-zpm-osx.sh | bash
fi
