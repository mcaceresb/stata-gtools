#!/bin/bash

export REPO="$(pwd | sed s,^/home/travis/builds/,,g)"
if [ "$TRAVIS_BRANCH" == "travis" ]; then
    echo "Pushing OSX files."
    git branch -D osx
    git checkout -B osx
    git add -f build/*osx*plugin
    git commit -m "Add plugin output for OSX build"
    git push https://$(OSX_TOKEN)@github.com/${REPO} osx
fi
