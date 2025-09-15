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
     * @platform CI/CD platform to generate configuration for (github, gitlab, jenkins, travis, circle)
     * @template Use a specific template (basic, full)
     * @branch Default branch name
     * @engines CFML engines to test (lucee5, lucee6, adobe2018, adobe2021, adobe2023)
     * @databases Databases to test against (h2, mysql, postgresql, sqlserver)
     * @force Overwrite existing CI configuration
     */
    function run(
        required string platform="github",
        string template="basic",
        string branch="main",
        string engines="lucee5,adobe2023",
        string databases="h2",
        boolean force=false
    ) {
        // Reconstruct arguments for handling --prefixed options
        arguments = reconstructArgs(arguments);
        
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels CI/CD Configuration Generator");
        print.line();

        // Validate platform selection
        local.supportedPlatforms = ["github", "gitlab", "jenkins", "travis", "circle"];
        if (!arrayContains(local.supportedPlatforms, lCase(arguments.platform))) {
            error("Unsupported platform: #arguments.platform#. Please choose from: #arrayToList(local.supportedPlatforms)#");
        }
        
        // Validate template selection
        local.supportedTemplates = ["basic", "full"];
        if (!arrayContains(local.supportedTemplates, lCase(arguments.template))) {
            error("Unsupported template: #arguments.template#. Please choose from: #arrayToList(local.supportedTemplates)#");
        }
        
        // Validate engines
        local.supportedEngines = ["lucee5", "lucee6", "adobe2018", "adobe2021", "adobe2023"];
        local.requestedEngines = listToArray(arguments.engines);
        for (local.engine in local.requestedEngines) {
            if (!arrayContains(local.supportedEngines, lCase(trim(local.engine)))) {
                error("Unsupported engine: #local.engine#. Please choose from: #arrayToList(local.supportedEngines)#");
            }
        }
        
        // Validate databases
        local.supportedDatabases = ["h2", "mysql", "postgresql", "sqlserver"];
        local.requestedDatabases = listToArray(arguments.databases);
        for (local.database in local.requestedDatabases) {
            if (!arrayContains(local.supportedDatabases, lCase(trim(local.database)))) {
                error("Unsupported database: #local.database#. Please choose from: #arrayToList(local.supportedDatabases)#");
            }
        }

        // Create CI/CD configuration based on platform
        switch(lCase(arguments.platform)) {
            case "github":
                createGitHubActions(arguments);
                break;
            case "gitlab":
                createGitLabCI(arguments);
                break;
            case "jenkins":
                createJenkinsfile(arguments);
                break;
            case "travis":
                createTravisCI(arguments);
                break;
            case "circle":
                createCircleCI(arguments);
                break;
        }

        print.line();
        print.greenLine("CI/CD configuration generated successfully!");
        print.line();
    }

    private function createGitHubActions(required struct args) {
        local.workflowsDir = fileSystemUtil.resolvePath(".github/workflows");
        local.ciFile = local.workflowsDir & "/ci.yml";
        
        // Check if file exists and force is not set
        if (fileExists(local.ciFile) && !args.force) {
            error("GitHub Actions configuration already exists at .github/workflows/ci.yml. Use --force to overwrite.");
        }
        
        if (!directoryExists(local.workflowsDir)) {
            directoryCreate(local.workflowsDir, true);
        }

        // Parse engines and databases
        local.engines = listToArray(args.engines);
        local.databases = listToArray(args.databases);
        local.branchName = args.branch;
        
        // Build engines array for matrix
        local.enginesArray = "[";
        for (local.i = 1; local.i <= arrayLen(local.engines); local.i++) {
            local.enginesArray &= trim(local.engines[local.i]);
            if (local.i < arrayLen(local.engines)) {
                local.enginesArray &= ", ";
            }
        }
        local.enginesArray &= "]";
        
        // Build databases array for matrix
        local.databasesArray = "[";
        for (local.i = 1; local.i <= arrayLen(local.databases); local.i++) {
            local.databasesArray &= trim(local.databases[local.i]);
            if (local.i < arrayLen(local.databases)) {
                local.databasesArray &= ", ";
            }
        }
        local.databasesArray &= "]";

        local.ciContent = 'name: CI

on:
  push:
    branches: [ #local.branchName#, develop ]
  pull_request:
    branches: [ #local.branchName#, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        cfengine: #local.enginesArray#';
        
        // Add database matrix if not just H2
        if (arrayLen(local.databases) > 1 || local.databases[1] != "h2") {
            local.ciContent &= '
        database: #local.databasesArray#';
        }
        
        local.ciContent &= '

    steps:
    - uses: actions/checkout@v4

    - name: Setup CommandBox
      uses: ortus-solutions/setup-commandbox@v2

    - name: Install dependencies
      run: box install';
      
        // Add database setup if not just H2
        if (arrayLen(local.databases) > 1 || local.databases[1] != "h2") {
            local.ciContent &= '

    - name: Setup Database
      run: |
        ## Database setup based on matrix.database
        if [ "${{ matrix.database }}" = "mysql" ]; then
          docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=password -p 3306:3306 mysql:8.0
          sleep 30
        elif [ "${{ matrix.database }}" = "postgresql" ]; then
          docker run -d --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15
          sleep 30
        fi';
        }

        local.ciContent &= '

    - name: Start server
      run: |
        box server start cfengine=${{ matrix.cfengine }}
        sleep 30

    - name: Run tests
      run: box testbox run

    - name: Stop server
      if: always()
      run: box server stop';

        // Template-based additions
        if (args.template == "full") {
            local.ciContent &= '

  docker:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Build Docker image
      run: docker build -t wheels-app .

    - name: Run Docker tests
      run: docker run --rm wheels-app box testbox run

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == ''refs/heads/#args.branch#''

    steps:
    - uses: actions/checkout@v4

    - name: Deploy to production
      run: |
        echo "Add your deployment steps here"
        ## Example: Deploy to AWS, Azure, etc.';
        }

        file action='write' file='#local.ciFile#' mode='777' output='#trim(local.ciContent)#';
        print.greenLine("Created GitHub Actions workflow at .github/workflows/ci.yml");
    }

    private function createGitLabCI(required struct args) {
        local.ciFile = fileSystemUtil.resolvePath(".gitlab-ci.yml");
        
        // Check if file exists and force is not set
        if (fileExists(local.ciFile) && !args.force) {
            error("GitLab CI configuration already exists at .gitlab-ci.yml. Use --force to overwrite.");
        }
        
        // Parse engines and databases
        local.engines = listToArray(args.engines);
        local.databases = listToArray(args.databases);
        
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
  - box install';
  
        // Generate test jobs for each engine
        for (local.engine in local.engines) {
            local.engineName = trim(local.engine);
            local.ciContent &= '

test:#lCase(local.engineName)#:
  stage: test
  script:
    - box server start cfengine=#local.engineName#
    - sleep 30
    - box testbox run
    - box server stop';
        }

        if (args.template == "full") {
            local.ciContent &= '

build:docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA .
    - docker tag $CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA $CI_PROJECT_NAME:latest

deploy:production:
  stage: deploy
  only:
    - #args.branch#
  script:
    - echo "Add your deployment steps here"
    ## Example: Deploy to production server';
        }

        file action='write' file='#local.ciFile#' mode='777' output='#trim(local.ciContent)#';
        print.greenLine("Created GitLab CI configuration at .gitlab-ci.yml");
    }

    private function createJenkinsfile(required struct args) {
        local.jenkinsFile = fileSystemUtil.resolvePath("Jenkinsfile");
        
        // Check if file exists and force is not set
        if (fileExists(local.jenkinsFile) && !args.force) {
            error("Jenkins configuration already exists at Jenkinsfile. Use --force to overwrite.");
        }
        
        // Parse engines
        local.engines = listToArray(args.engines);
        
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
        }';
        
        // Generate test stages for each engine
        for (local.engine in local.engines) {
            local.engineName = trim(local.engine);
            local.jenkinsStageName = "Test " & uCase(left(local.engineName, 1)) & lCase(right(local.engineName, len(local.engineName)-1));
            local.jenkinsContent &= '

        stage(''#local.jenkinsStageName#'') {
            steps {
                sh ''box server start cfengine=#local.engineName#''
                sh ''sleep 30''
                sh ''box testbox run''
                sh ''box server stop''
            }
        }';
        }

        if (args.template == "full") {
            local.jenkinsContent &= '

        stage(''Docker Build'') {
            steps {
                sh ''docker build -t wheels-app:${BUILD_NUMBER} .''
                sh ''docker tag wheels-app:${BUILD_NUMBER} wheels-app:latest''
            }
        }

        stage(''Deploy'') {
            when {
                branch ''#args.branch#''
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

        file action='write' file='#local.jenkinsFile#' mode='777' output='#trim(local.jenkinsContent)#';
        print.greenLine("Created Jenkins pipeline configuration at Jenkinsfile");
    }

    private function createTravisCI(required struct args) {
        local.travisFile = fileSystemUtil.resolvePath(".travis.yml");
        
        // Check if file exists and force is not set
        if (fileExists(local.travisFile) && !args.force) {
            error("Travis CI configuration already exists at .travis.yml. Use --force to overwrite.");
        }
        
        // Parse engines
        local.engines = listToArray(args.engines);
        
        local.travisContent = 'language: java
sudo: required
services:
  - docker

branches:
  only:
    - #args.branch#
    - develop

before_install:
  - curl -fsSl https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
  - echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
  - sudo apt-get update && sudo apt-get install -y commandbox

env:';

        // Add engine matrix
        for (local.engine in local.engines) {
            local.engineName = trim(local.engine);
            local.travisContent &= '
  - CFENGINE=#local.engineName#';
        }

        local.travisContent &= '

script:
  - box install
  - box server start cfengine=$CFENGINE
  - sleep 30
  - box testbox run
  - box server stop';

        if (args.template == "full") {
            local.travisContent &= '

deploy:
  provider: script
  script: echo "Add your deployment steps here"
  on:
    branch: #args.branch#';
        }

        file action='write' file='#local.travisFile#' mode='777' output='#trim(local.travisContent)#';
        print.greenLine("Created Travis CI configuration at .travis.yml");
    }

    private function createCircleCI(required struct args) {
        local.circleCIDir = fileSystemUtil.resolvePath(".circleci");
        local.configFile = local.circleCIDir & "/config.yml";
        
        // Check if file exists and force is not set
        if (fileExists(local.configFile) && !args.force) {
            error("CircleCI configuration already exists at .circleci/config.yml. Use --force to overwrite.");
        }
        
        if (!directoryExists(local.circleCIDir)) {
            directoryCreate(local.circleCIDir, true);
        }
        
        // Parse engines
        local.engines = listToArray(args.engines);
        
        local.circleContent = 'version: 2.1

orbs:
  commandbox: commandbox/commandbox@1.0.0

workflows:
  test:
    jobs:';

        // Add test jobs for each engine
        for (local.engine in local.engines) {
            local.engineName = trim(local.engine);
            local.circleContent &= '
      - test-#lCase(local.engineName)#';
        }

        local.circleContent &= '

jobs:';

        // Generate job definitions for each engine
        for (local.engine in local.engines) {
            local.engineName = trim(local.engine);
            local.circleContent &= '
  test-#lCase(local.engineName)#:
    docker:
      - image: cimg/openjdk:11.0
    steps:
      - checkout
      - commandbox/install
      - run:
          name: Install dependencies
          command: box install
      - run:
          name: Start server
          command: |
            box server start cfengine=#local.engineName#
            sleep 30
      - run:
          name: Run tests
          command: box testbox run
      - run:
          name: Stop server
          command: box server stop
          when: always';
        }

        if (args.template == "full") {
            local.circleContent &= '

  deploy:
    docker:
      - image: cimg/openjdk:11.0
    steps:
      - checkout
      - run:
          name: Deploy
          command: |
            echo "Add your deployment steps here"
            ## Example: Deploy to production';
        }

        file action='write' file='#local.configFile#' mode='777' output='#trim(local.circleContent)#';
        print.greenLine("Created CircleCI configuration at .circleci/config.yml");
    }
}
