/**
 * Generate CI/CD configuration files for popular platforms
 *
 * {code:bash}
 * wheels ci:init github
 * wheels ci:init gitlab
 * wheels ci:init jenkins
 * {code}
 */
component extends="../base" {

    /**
     * @platform CI/CD platform to generate configuration for (github, gitlab, jenkins)
     * @includeDeployment Include deployment configuration
     * @dockerEnabled Enable Docker-based workflows
     */
    function run(
        required string platform,
        boolean includeDeployment=true,
        boolean dockerEnabled=true
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels CI/CD Configuration Generator");
        print.line();

        // Validate platform selection
        local.supportedPlatforms = ["github", "gitlab", "jenkins"];
        if (!arrayContains(local.supportedPlatforms, lCase(arguments.platform))) {
            error("Unsupported platform: #arguments.platform#. Please choose from: #arrayToList(local.supportedPlatforms)#");
        }

        // Create CI/CD configuration based on platform
        switch(lCase(arguments.platform)) {
            case "github":
                createGitHubActions(arguments.includeDeployment, arguments.dockerEnabled);
                break;
            case "gitlab":
                createGitLabCI(arguments.includeDeployment, arguments.dockerEnabled);
                break;
            case "jenkins":
                createJenkinsfile(arguments.includeDeployment, arguments.dockerEnabled);
                break;
        }

        print.line();
        print.greenLine("CI/CD configuration generated successfully!");
        print.line();
    }

    private function createGitHubActions(boolean includeDeployment, boolean dockerEnabled) {
        local.workflowsDir = fileSystemUtil.resolvePath(".github/workflows");
        if (!directoryExists(local.workflowsDir)) {
            directoryCreate(local.workflowsDir, true);
        }

        local.ciContent = 'name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        cfengine: [lucee5, adobe2023]

    steps:
    - uses: actions/checkout@v3

    - name: Setup CommandBox
      uses: elpete/setup-commandbox@v1.0.0

    - name: Install dependencies
      run: box install

    - name: Start server
      run: |
        box server start cfengine=${{ matrix.cfengine }}
        sleep 30

    - name: Run tests
      run: box testbox run

    - name: Stop server
      if: always()
      run: box server stop';

        if (arguments.dockerEnabled) {
            local.ciContent &= '

  docker:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build Docker image
      run: docker build -t wheels-app .

    - name: Run Docker tests
      run: docker run --rm wheels-app box testbox run';
        }

        if (arguments.includeDeployment) {
            local.ciContent &= '

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == ''refs/heads/main''

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to production
      run: |
        echo "Add your deployment steps here"
        ## Example: Deploy to AWS, Azure, etc.';
        }

        file action='write' file='#local.workflowsDir#/ci.yml' mode='777' output='#trim(local.ciContent)#';
        print.greenLine("Created GitHub Actions workflow at .github/workflows/ci.yml");
    }

    private function createGitLabCI(boolean includeDeployment, boolean dockerEnabled) {
        local.ciContent = 'stages:
  - test
  - build
  - deploy

variables:
  COMMANDBOX_VERSION: "5.9.0"

before_script:
  - apt-get update -qq && apt-get install -y -qq curl unzip
  - curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -
  - echo "deb https://downloads.ortussolutions.com/debs/noarch /" | tee -a /etc/apt/sources.list.d/commandbox.list
  - apt-get update -qq && apt-get install -y -qq commandbox
  - box install

test:lucee:
  stage: test
  script:
    - box server start cfengine=lucee5
    - sleep 30
    - box testbox run
    - box server stop

test:adobe:
  stage: test
  script:
    - box server start cfengine=adobe2023
    - sleep 30
    - box testbox run
    - box server stop';

        if (arguments.dockerEnabled) {
            local.ciContent &= '

build:docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA .
    - docker tag $CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA $CI_PROJECT_NAME:latest';
        }

        if (arguments.includeDeployment) {
            local.ciContent &= '

deploy:production:
  stage: deploy
  only:
    - main
  script:
    - echo "Add your deployment steps here"
    ## Example: Deploy to production server';
        }

        file action='write' file='#fileSystemUtil.resolvePath(".gitlab-ci.yml")#' mode='777' output='#trim(local.ciContent)#';
        print.greenLine("Created GitLab CI configuration at .gitlab-ci.yml");
    }

    private function createJenkinsfile(boolean includeDeployment, boolean dockerEnabled) {
        local.jenkinsContent = 'pipeline {
    agent any

    environment {
        COMMANDBOX_HOME = "${WORKSPACE}/.CommandBox"
    }

    stages {
        stage(''Setup'') {
            steps {
                sh ''curl -fsSl https://downloads.ortussolutions.com/debs/gpg | apt-key add -''
                sh ''echo "deb https://downloads.ortussolutions.com/debs/noarch /" | tee -a /etc/apt/sources.list.d/commandbox.list''
                sh ''apt-get update && apt-get install -y commandbox''
                sh ''box install''
            }
        }

        stage(''Test Lucee'') {
            steps {
                sh ''box server start cfengine=lucee5''
                sh ''sleep 30''
                sh ''box testbox run''
                sh ''box server stop''
            }
        }

        stage(''Test Adobe'') {
            steps {
                sh ''box server start cfengine=adobe2023''
                sh ''sleep 30''
                sh ''box testbox run''
                sh ''box server stop''
            }
        }';

        if (arguments.dockerEnabled) {
            local.jenkinsContent &= '

        stage(''Docker Build'') {
            steps {
                sh ''docker build -t wheels-app:${BUILD_NUMBER} .''
                sh ''docker tag wheels-app:${BUILD_NUMBER} wheels-app:latest''
            }
        }';
        }

        if (arguments.includeDeployment) {
            local.jenkinsContent &= '

        stage(''Deploy'') {
            when {
                branch ''main''
            }
            steps {
                echo ''Add your deployment steps here''
                // Example: Deploy to production
            }
        }';
        }

        local.jenkinsContent &= '
    }

    post {
        always {
            cleanWs()
        }
    }
}';

        file action='write' file='#fileSystemUtil.resolvePath("Jenkinsfile")#' mode='777' output='#trim(local.jenkinsContent)#';
        print.greenLine("Created Jenkins pipeline configuration at Jenkinsfile");
    }
}
