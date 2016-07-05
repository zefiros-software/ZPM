#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then 
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 
fi
f [[ "$TRAVIS_OS_NAME" == "osx" ]]; then 
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
fi
    