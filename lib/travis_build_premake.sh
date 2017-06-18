#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    wget https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-macosx.tar.gz
    tar zxvf premake-5.0.0.alpha4-macosx.tar.gz
else
    wget https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-linux.tar.gz
    tar zxvf premake-5.0.0.alpha4-linux.tar.gz
fi
