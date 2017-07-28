#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    sudo add-apt-repository ppa:git-core/ppa -y
    sudo apt-get install git -y
    wget -q -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/features/refactor/script/install-zpm.sh | bash
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    brew unlink git
    brew install git
    wget -q -O  - https://raw.githubusercontent.com/Zefiros-Software/ZPM/features/refactor/script/install-zpm-osx.sh | bash
fi
