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
        
        // Generate appropriate CI/CD configuration
        switch (lCase(arguments.platform)) {
            case "github":
                generateGitHubActions(arguments.includeDeployment, arguments.dockerEnabled);
                break;
            case "gitlab":
                generateGitLabCI(arguments.includeDeployment, arguments.dockerEnabled);
                break;
            case "jenkins":
                generateJenkinsfile(arguments.includeDeployment, arguments.dockerEnabled);
                break;
        }
        
        print.line();
        print.boldGreenLine("#arguments.platform# CI/CD configuration generated successfully!");
        print.line();
    }
    
    /**
     * Generate GitHub Actions workflow configuration
     */
    private void function generateGitHubActions(
        required boolean includeDeployment,
        required boolean dockerEnabled
    ) {
        // Create .github/workflows directory if it doesn't exist
        local.workflowsDir = fileSystemUtil.resolvePath(".github/workflows");
        if (!directoryExists(local.workflowsDir)) {
            directoryCreate(local.workflowsDir, true);
        }
        
        // Create CI workflow
        local.ciWorkflowPath = local.workflowsDir & "/ci.yml";
        
        local.ciWorkflowContent = "name: Wheels CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest";
        
        if (arguments.dockerEnabled) {
            local.ciWorkflowContent &= "
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: cfwheels_test
          MYSQL_USER: cfwheels
          MYSQL_PASSWORD: cfwheels
        ports:
          - 3306:3306
        options: --health-cmd='mysqladmin ping' --health-interval=10s --health-timeout=5s --health-retries=3";
        }
        
        local.ciWorkflowContent &= "

    steps:
      - uses: actions/checkout@v3
      
      - name: Set up CommandBox
        uses: ortus-solutions/setup-commandbox@v2.0.1
        
      - name: Install dependencies
        run: box install
        
      - name: Set up Wheels
        run: |
          box server start
          box wheels reload";
        
        if (arguments.dockerEnabled) {
            local.ciWorkflowContent &= "
      
      - name: Run database migrations
        run: box wheels dbmigrate up";
        }
        
        local.ciWorkflowContent &= "
      
      - name: Run tests
        run: box wheels test";
        
        file action='write' file='#local.ciWorkflowPath#' mode='777' output='#local.ciWorkflowContent#';
        print.greenLine("Created GitHub Actions CI workflow");
        
        // If deployment is included, create additional workflow
        if (arguments.includeDeployment) {
            local.deployWorkflowPath = local.workflowsDir & "/deploy.yml";
            
            local.deployWorkflowContent = "name: Wheels Deploy

on:
  push:
    branches: [ main ]
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up CommandBox
        uses: ortus-solutions/setup-commandbox@v2.0.1
        
      - name: Install dependencies
        run: box install";
            
            if (arguments.dockerEnabled) {
                local.deployWorkflowContent &= "
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile.production
          push: true
          tags: |
            ${{ secrets.DOCKER_REGISTRY }}/cfwheels:latest
            ${{ secrets.DOCKER_REGISTRY }}/cfwheels:${{ github.sha }}
            
      - name: Deploy to production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /path/to/deployment
            docker-compose pull
            docker-compose up -d";
            } else {
                local.deployWorkflowContent &= "
      
      - name: Deploy to production
        uses: SamKirkland/FTP-Deploy-Action@v4.3.4
        with:
          server: ${{ secrets.FTP_SERVER }}
          username: ${{ secrets.FTP_USERNAME }}
          password: ${{ secrets.FTP_PASSWORD }}
          local-dir: ./
          server-dir: /path/to/deployment/";
            }
            
            file action='write' file='#local.deployWorkflowPath#' mode='777' output='#local.deployWorkflowContent#';
            print.greenLine("Created GitHub Actions deployment workflow");
        }
    }
    
    /**
     * Generate GitLab CI configuration
     */
    private void function generateGitLabCI(
        required boolean includeDeployment,
        required boolean dockerEnabled
    ) {
        local.gitlabCIPath = fileSystemUtil.resolvePath(".gitlab-ci.yml");
        
        local.gitlabCIContent = "stages:
  - test
  - build";
          
        if (arguments.includeDeployment) {
            local.gitlabCIContent &= "
  - deploy";
        }
        
        local.gitlabCIContent &= "

variables:
  DOCKER_DRIVER: overlay2";
        
        if (arguments.dockerEnabled) {
            local.gitlabCIContent &= "
  DOCKER_TLS_CERTDIR: \"\"
  DOCKER_HOST: tcp://docker:2375/";
        }
        
        local.gitlabCIContent &= "

test:
  stage: test
  image: ortussolutions/commandbox:latest";
        
        if (arguments.dockerEnabled) {
            local.gitlabCIContent &= "
  services:
    - name: mysql:8.0
      alias: mysql
      variables:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: cfwheels_test
        MYSQL_USER: cfwheels
        MYSQL_PASSWORD: cfwheels";
        }
        
        local.gitlabCIContent &= "
  script:
    - box install
    - box server start
    - box wheels reload";
        
        if (arguments.dockerEnabled) {
            local.gitlabCIContent &= "
    - box wheels dbmigrate up";
        }
        
        local.gitlabCIContent &= "
    - box wheels test
  cache:
    paths:
      - .CommandBox/";
        
        if (arguments.dockerEnabled) {
            local.gitlabCIContent &= "

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -t $CI_REGISTRY_IMAGE:latest -f Dockerfile.production .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main";
        }
        
        if (arguments.includeDeployment) {
            local.gitlabCIContent &= "

deploy:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo '$SSH_PRIVATE_KEY' | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST 'cd /path/to/deployment && docker-compose pull && docker-compose up -d'
  environment:
    name: production
    url: https://example.com
  only:
    - main";
        }
        
        file action='write' file='#local.gitlabCIPath#' mode='777' output='#local.gitlabCIContent#';
        print.greenLine("Created GitLab CI configuration");
    }
    
    /**
     * Generate Jenkinsfile
     */
    private void function generateJenkinsfile(
        required boolean includeDeployment,
        required boolean dockerEnabled
    ) {
        local.jenkinsfilePath = fileSystemUtil.resolvePath("Jenkinsfile");
        
        local.jenkinsfileContent = "pipeline {
    agent {
        label 'master'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'box install'
            }
        }";
        
        if (arguments.dockerEnabled) {
            local.jenkinsfileContent &= "
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cfwheels-app:${env.BUILD_NUMBER} -t cfwheels-app:latest .'
            }
        }";
        }
        
        local.jenkinsfileContent &= "
        
        stage('Start Server') {
            steps {
                sh 'box server start'
                sh 'box wheels reload'
            }
        }";
        
        if (arguments.dockerEnabled) {
            local.jenkinsfileContent &= "
            
        stage('Run Migrations') {
            steps {
                sh 'box wheels dbmigrate up'
            }
        }";
        }
        
        local.jenkinsfileContent &= "
        
        stage('Run Tests') {
            steps {
                sh 'box wheels test'
            }
        }";
        
        if (arguments.includeDeployment) {
            local.jenkinsfileContent &= "
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {";
            
            if (arguments.dockerEnabled) {
                local.jenkinsfileContent &= "
                sh 'docker tag cfwheels-app:latest ${DOCKER_REGISTRY}/cfwheels-app:latest'
                sh 'docker push ${DOCKER_REGISTRY}/cfwheels-app:latest'
                
                sshagent(['production-server']) {
                    sh 'ssh user@production-server ''cd /path/to/deployment && docker-compose pull && docker-compose up -d'''
                }";
            } else {
                local.jenkinsfileContent &= "
                sshagent(['production-server']) {
                    sh 'rsync -avz --delete ./ user@production-server:/path/to/deployment/'
                    sh 'ssh user@production-server ''cd /path/to/deployment && box server restart'''
                }";
            }
            
            local.jenkinsfileContent &= "
            }
        }";
        }
        
        local.jenkinsfileContent &= "
    }
    
    post {
        always {
            sh 'box server stop'
        }
        success {
            echo 'Build successful!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}";
        
        file action='write' file='#local.jenkinsfilePath#' mode='777' output='#local.jenkinsfileContent#';
        print.greenLine("Created Jenkinsfile");
    }
}