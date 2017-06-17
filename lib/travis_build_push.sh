#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    echo "Pushing OSX files."
    git branch -D osx
    git checkout -B osx
    git add -f build/*osx*plugin
    git commit -m "Add plugin output for OSX build"
    git push https://$(OSX_TOKEN)@github.com/mcaceresb/stata-gtools osx
fi
