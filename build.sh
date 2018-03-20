#!/usr/bin/env bash
wget -q -O $HOME/.m2/settings.xml https://github.com/mizool/travis-ci-maven-gitflow/blob/feature/create-initial-files-and-documentation/settings.xml
wget -q -O $HOME/.m2/toolchains.xml https://github.com/mizool/travis-ci-maven-gitflow/blob/feature/create-initial-files-and-documentation/toolchains.xml

if [[ ( $TRAVIS_BRANCH = 'master' || $TRAVIS_BRANCH = 'develop' ) && $TRAVIS_PULL_REQUEST = 'false' ]]; then
    openssl aes-256-cbc -in codesigning.asc.enc -out codesigning.asc -d -pass pass:$CODESIGNING_AES_PASSWORD
    gpg --batch --quiet --fast-import codesigning.asc
    mvn deploy -DperformRelease=true -P sign
else
    mvn verify -DperformRelease=true
fi