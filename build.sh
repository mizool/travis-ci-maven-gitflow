#!/usr/bin/env bash
wget -q -O $HOME/.m2/settings.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/settings.xml
wget -q -O $HOME/.m2/toolchains.xml https://raw.githubusercontent.com/mizool/travis-ci-maven-gitflow/master/toolchains.xml

if [[ ( $TRAVIS_BRANCH = master || $TRAVIS_BRANCH = develop || $TRAVIS_BRANCH = release/* || $TRAVIS_BRANCH = hotfix/*) && $TRAVIS_PULL_REQUEST = false ]]; then
    openssl aes-256-cbc -in codesigning.asc.enc -out codesigning.asc -d -pass pass:$CODESIGNING_AES_PASSWORD
    gpg --batch --quiet --fast-import codesigning.asc

    if [[ $TRAVIS_BRANCH = develop && -n "$SONAR_ORGANIZATION" ]]; then
        # Sonar fails if a source folder is missing. This is a workaround for the additional sql source folder.
        find -name "pom.xml" -type f -execdir mkdir -p src/main/sql \;
        mvn \
            -U \
            org.jacoco:jacoco-maven-plugin:0.8.5:prepare-agent \
            deploy \
            org.codehaus.mojo:sonar-maven-plugin:3.7.0.1746:sonar \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.organization=$SONAR_ORGANIZATION \
            -Dsonar.login=$SONAR_LOGIN_TOKEN \
            -Dsonar.sources=pom.xml,src/main/java,src/main/sql \
            -DperformRelease=true \
            -P sign
    else
        mvn -U deploy -DperformRelease=true -P sign
    fi
else
    if [[ -n "$SONAR_ORGANIZATION" ]]; then
        # Sonar fails if a source folder is missing. This is a workaround for the additional sql source folder.
        find -name "pom.xml" -type f -execdir mkdir -p src/main/sql \;
        mvn \
            -U \
            org.jacoco:jacoco-maven-plugin:0.8.5:prepare-agent \
            verify \
            org.codehaus.mojo:sonar-maven-plugin:3.7.0.1746:sonar \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.organization=$SONAR_ORGANIZATION \
            -Dsonar.login=$SONAR_LOGIN_TOKEN \
            -Dsonar.sources=pom.xml,src/main/java,src/main/sql \
            -DperformRelease=true
    else
        mvn -U verify -DperformRelease=true
    fi
fi