#!/bin/bash

cd lib/spookyhash/build
wget https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-linux.tar.gz
tar zxvf premake-5.0.0.alpha4-linux.tar.gz
./premake5 gmake
make clean
ALL_CFLAGS+=-fPIC make
cd -
make clean && make

export REPO="$(pwd | sed s,^/home/travis/builds/,,g)"
ssh -o StrictHostKeyChecking=no
if [ "$TRAVIS_BRANCH" == "travis" ]; then
    git branch -D osx
    git checkout -B osx
    git add -f build/*osx*plugin
    git commit -m "Add plugin output for OSX build"
    git push https://$(OSX_TOKEN)@github.com/${REPO} osx
fi
