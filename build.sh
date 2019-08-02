#!/usr/bin/env bash

echo [CI BUILD] TRAVIS_PULL_REQUEST=$TRAVIS_PULL_REQUEST
echo [CI BUILD] TRAVIS_BRANCH=$TRAVIS_BRANCH

wget -q -O $HOME/.m2/settings.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/settings.xml
wget -q -O $HOME/.m2/toolchains.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/toolchains.xml

if [[ $TRAVIS_PULL_REQUEST -ge 1 ]]; then
    echo [CI BUILD] Pull request \#$TRAVIS_PULL_REQUEST

    # PR builds without configured SonarCloud connection intentionally do nothing.
    if [[ -n "$SONAR_ORGANIZATION" ]]; then
        echo [CI BUILD] Starting SonarCloud analysis ...
        mvn \
            -U \
            org.jacoco:jacoco-maven-plugin:0.7.9:prepare-agent \
            verify \
            org.codehaus.mojo:sonar-maven-plugin:3.3.0.603:sonar \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.organization=$SONAR_ORGANIZATION \
            -Dsonar.login=$SONAR_LOGIN_TOKEN
    else
        echo [CI BUILD] SonarCloud not activated, nothing to do.
    fi

elif [[ $TRAVIS_BRANCH = master || $TRAVIS_BRANCH = develop || $TRAVIS_BRANCH = release/* || $TRAVIS_BRANCH = hotfix/* ]]; then

    # If we get here, the current build is a regular build of a long-living or release preparation branch, not a pull request.
    # Note that if TRAVIS_PULL_REQUEST is an integer (instead of false), TRAVIS_BRANCH refers to the target branch of the PR.

    echo [CI BUILD] Long-living or release preparation branch

    openssl aes-256-cbc -in codesigning.asc.enc -out codesigning.asc -d -pass pass:$CODESIGNING_AES_PASSWORD
    gpg --batch --quiet --fast-import codesigning.asc

    if [[ $TRAVIS_BRANCH = develop && -n "$SONAR_ORGANIZATION" ]]; then
        echo [CI BUILD] Analysing with SonarCloud & deploying ...
        mvn \
            -U \
            org.jacoco:jacoco-maven-plugin:0.7.9:prepare-agent \
            deploy \
            org.codehaus.mojo:sonar-maven-plugin:3.3.0.603:sonar \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.organization=$SONAR_ORGANIZATION \
            -Dsonar.login=$SONAR_LOGIN_TOKEN \
            -DperformRelease=true \
            -P sign
    else
        echo [CI BUILD] Deploying
        mvn \
            -U \
            deploy \
            -DperformRelease=true \
            -P sign
    fi

else

    echo [CI BUILD] Arbitrary branch; skipping deployment.
    mvn \
        -U \
        verify \
        -DperformRelease=true

fi
