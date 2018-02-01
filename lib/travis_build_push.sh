#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    REPO=`git config remote.origin.url`
    SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

    git config user.name "Travis CI"
    git config user.email "$COMMIT_AUTHOR_EMAIL"

    echo "Adding OSX files."
    git checkout develop
    git branch -D osx
    git checkout -B osx
	cp build/*plugin lib/plugin/
    git add -f build/*osx*plugin
    git add -f lib/plugin/*osx*plugin

    echo "Committing OSX files."
    git commit -m "[Travis] Add plugin output for OSX build"

    openssl aes-256-cbc -K $encrypted_e1735dcdef59_key -iv $encrypted_e1735dcdef59_iv -in lib/id_rsa_travis.enc -out lib/id_rsa_travis -d
    chmod 600 lib/id_rsa_travis
    eval `ssh-agent -s`
    ssh-add lib/id_rsa_travis

    echo "Pushing OSX files."
    git push -f ${SSH_REPO} osx

    rm -f lib/id_rsa_travis

    echo "Done"
fi
