#!/bin/bash
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm.sh | bash; 

    apt-get source git
	cd git_vXXX
	./configure --prefix=$HOME
	make
	make install

	mkdir -p $HOME/bin
	wget https://github.com/git-lfs/git-lfs/releases/download/v1.5.6/git-lfs-linux-amd64-1.5.6.tar.gz
	tar xvfz git-lfs-linux-amd64-1.5.6.tar.gz
	mv git-lfs-linux-amd64-1.5.6/git-lfs $HOME/bin/git-lfs
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    wget -O - https://raw.githubusercontent.com/Zefiros-Software/ZPM/master/script/install-zpm-osx.sh | bash; 
    brew update;
    brew unlink git
    brew install git
    brew install git-lfs;
    git-lfs install
fi
