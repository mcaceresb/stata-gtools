#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    wget https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-macosx.tar.gz
    tar zxvf premake-5.0.0.alpha11-linux.tar.gz
else
    wget https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha11-linux.tar.gz
    tar zxvf premake-5.0.0.alpha11-linux.tar.gz
fi
