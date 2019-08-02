#!/usr/bin/env bash
wget -q -O $HOME/.m2/settings.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/settings.xml
wget -q -O $HOME/.m2/toolchains.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/toolchains.xml

if [[ $TRAVIS_PULL_REQUEST = true ]]; then

    # PR builds without configured SonarCloud connection intentionally do nothing.
    if [[ -n "$SONAR_ORGANIZATION" ]]; then
        mvn \
            -U \
            org.jacoco:jacoco-maven-plugin:0.7.9:prepare-agent \
            verify \
            org.codehaus.mojo:sonar-maven-plugin:3.3.0.603:sonar \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.organization=$SONAR_ORGANIZATION \
            -Dsonar.login=$SONAR_LOGIN_TOKEN
    fi

elif [[ $TRAVIS_BRANCH = master || $TRAVIS_BRANCH = develop || $TRAVIS_BRANCH = release/* || $TRAVIS_BRANCH = hotfix/* ]]; then

    # If we get here, the current build is a regular build of a long-living or release preparation branch, not a pull request.
    # Note: at some point, the if condition here had an additional '$TRAVIS_PULL_REQUEST = false' condition.

    openssl aes-256-cbc -in codesigning.asc.enc -out codesigning.asc -d -pass pass:$CODESIGNING_AES_PASSWORD
    gpg --batch --quiet --fast-import codesigning.asc

    if [[ $TRAVIS_BRANCH = develop && -n "$SONAR_ORGANIZATION" ]]; then
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
        mvn \
            -U \
            deploy \
            -DperformRelease=true \
            -P sign
    fi

else
    mvn \
        -U \
        verify \
        -DperformRelease=true
fi
