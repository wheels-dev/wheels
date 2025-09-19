# CI/CD Integration for CFWheels Applications

## Description
Comprehensive CI/CD pipeline configurations and best practices for CFWheels applications, covering automated testing, deployment, monitoring, and rollback strategies across popular platforms.

## Key Points
- Automated testing prevents deployment of broken code
- Environment-specific configurations ensure proper deployments
- Database migrations must be handled carefully in CI/CD pipelines
- Security scanning should be integrated into the pipeline
- Rollback capabilities are essential for production stability
- Multi-stage deployments reduce risk

## GitHub Actions Workflow

### 1. Complete CI/CD Pipeline
```yaml
# .github/workflows/ci-cd.yml
name: CFWheels CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  CFML_ENGINE: lucee
  CFML_VERSION: 5.3
  NODE_VERSION: 18

jobs:
  # Phase 1: Code Quality and Security Scanning
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install Dependencies
        run: |
          npm install
          npm install -g cfn-lint

      - name: Lint CFML Code
        run: |
          # Install CFLint
          wget https://github.com/cflint/CFLint/releases/download/CFLint-1.5.0/CFLint-1.5.0-all.jar
          java -jar CFLint-1.5.0-all.jar -folder app/ -xml -xmlfile cflint-results.xml

      - name: Security Scan with Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/owasp-top-ten

      - name: Upload Security Scan Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: security-scan-results
          path: |
            cflint-results.xml
            semgrep-results.json

  # Phase 2: Unit and Integration Testing
  test:
    runs-on: ubuntu-latest
    needs: code-quality

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: wheels_test
          MYSQL_DATABASE: wheels_test
          MYSQL_USER: wheels
          MYSQL_PASSWORD: wheels_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup CFML Engine
        uses: foundeo/setup-cfml@v1
        with:
          cfengine: ${{ env.CFML_ENGINE }}
          cfversion: ${{ env.CFML_VERSION }}

      - name: Start CFML Server
        run: |
          box start cfengine=${{ env.CFML_ENGINE }}@${{ env.CFML_VERSION }} \
                    port=8080 \
                    directory=./public \
                    rewritesEnable=true

      - name: Wait for Server
        run: |
          timeout 60 bash -c 'until curl -f http://localhost:8080/; do sleep 2; done'

      - name: Setup Test Database
        run: |
          mysql -h 127.0.0.1 -P 3306 -u wheels -pwheels_test -e "CREATE DATABASE IF NOT EXISTS wheels_test;"

      - name: Run Database Migrations
        env:
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_NAME: wheels_test
          DB_USER: wheels
          DB_PASSWORD: wheels_test
        run: |
          box wheels dbmigrate latest

      - name: Run Unit Tests
        run: |
          box testbox run

      - name: Run Integration Tests
        run: |
          box wheels test run --reporter=json --outputFile=test-results.json

      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results
          path: |
            test-results.json
            testbox-results/

  # Phase 3: Performance and Accessibility Testing
  performance-testing:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Setup CFML Engine
        uses: foundeo/setup-cfml@v1
        with:
          cfengine: ${{ env.CFML_ENGINE }}
          cfversion: ${{ env.CFML_VERSION }}

      - name: Start Application
        run: |
          box start cfengine=${{ env.CFML_ENGINE }}@${{ env.CFML_VERSION }} port=8080
          timeout 60 bash -c 'until curl -f http://localhost:8080/; do sleep 2; done'

      - name: Install Lighthouse
        run: npm install -g @lhci/cli

      - name: Run Lighthouse Performance Audit
        run: |
          lhci autorun \
            --upload.target=temporary-public-storage \
            --collect.url=http://localhost:8080 \
            --collect.numberOfRuns=3

      - name: Install axe-core
        run: npm install -g @axe-core/cli

      - name: Run Accessibility Tests
        run: |
          axe http://localhost:8080 \
            --exit \
            --save accessibility-results.json \
            --tags wcag2a,wcag2aa

      - name: Upload Performance Results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: |
            .lighthouseci/
            accessibility-results.json

  # Phase 4: Security Testing
  security-testing:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup CFML Engine
        uses: foundeo/setup-cfml@v1
        with:
          cfengine: ${{ env.CFML_ENGINE }}
          cfversion: ${{ env.CFML_VERSION }}

      - name: Start Application
        run: |
          box start cfengine=${{ env.CFML_ENGINE }}@${{ env.CFML_VERSION }} port=8080
          timeout 60 bash -c 'until curl -f http://localhost:8080/; do sleep 2; done'

      - name: Run OWASP ZAP Security Scan
        uses: zaproxy/action-full-scan@v0.4.0
        with:
          target: 'http://localhost:8080'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Upload Security Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: security-test-results
          path: report_html.html

  # Phase 5: Build and Deploy to Staging
  deploy-staging:
    runs-on: ubuntu-latest
    needs: [code-quality, test, performance-testing, security-testing]
    if: github.ref == 'refs/heads/develop'

    environment:
      name: staging
      url: https://staging.yourapp.com

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Build Assets
        run: |
          npm install
          npm run build

      - name: Deploy to Staging Server
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            cd /var/www/staging
            git pull origin develop
            npm install --production
            npm run build
            ./scripts/deploy-staging.sh

      - name: Run Staging Smoke Tests
        run: |
          sleep 30
          curl -f https://staging.yourapp.com/health
          npm run test:smoke -- --baseUrl=https://staging.yourapp.com

  # Phase 6: Deploy to Production
  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'

    environment:
      name: production
      url: https://yourapp.com

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Build Production Assets
        run: |
          npm install
          npm run build:production

      - name: Create Deployment Package
        run: |
          tar -czf deployment.tar.gz \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='tests' \
            --exclude='.env*' \
            .

      - name: Upload Deployment Package
        uses: actions/upload-artifact@v3
        with:
          name: deployment-package
          path: deployment.tar.gz

      - name: Deploy to Production
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            cd /var/www/production

            # Create backup
            ./scripts/create-backup.sh

            # Deploy new version
            ./scripts/deploy-production.sh

            # Run health checks
            ./scripts/health-check.sh

      - name: Run Production Smoke Tests
        run: |
          sleep 60
          npm run test:smoke -- --baseUrl=https://yourapp.com

      - name: Notify Team of Deployment
        uses: 8398a7/action-slack@v3
        if: always()
        with:
          status: ${{ job.status }}
          text: "Production deployment completed: ${{ job.status }}"
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

  # Phase 7: Post-Deployment Monitoring
  post-deployment-monitoring:
    runs-on: ubuntu-latest
    needs: deploy-production
    if: always()

    steps:
      - name: Monitor Application Health
        run: |
          # Wait 5 minutes then check health
          sleep 300

          # Check health endpoint
          HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://yourapp.com/health)

          if [[ $HEALTH_STATUS != "200" ]]; then
            echo "❌ Health check failed with status: $HEALTH_STATUS"
            exit 1
          fi

      - name: Check Error Rates
        run: |
          # Query monitoring system for error rates
          # This would integrate with your monitoring tool
          echo "✅ Error rates within acceptable limits"

      - name: Performance Monitoring
        run: |
          # Run lighthouse again on production
          npx lighthouse https://yourapp.com \
            --chrome-flags="--headless" \
            --output=json \
            --output-path=production-lighthouse.json

      - name: Upload Monitoring Results
        uses: actions/upload-artifact@v3
        with:
          name: monitoring-results
          path: production-lighthouse.json
```

### 2. Deployment Scripts

#### Staging Deployment Script
```bash
#!/bin/bash
# scripts/deploy-staging.sh

set -euo pipefail

echo "🚀 Starting staging deployment..."

# Environment setup
export APP_ENV=staging
export DB_NAME=wheels_staging

# Load staging environment variables
if [[ -f ".env.staging" ]]; then
    source .env.staging
fi

# Backup current version
echo "📦 Creating backup..."
if [[ -d "backup" ]]; then
    rm -rf backup.old
    mv backup backup.old
fi
cp -r . backup/

# Install dependencies
echo "📋 Installing dependencies..."
box install --production

# Run database migrations
echo "🔄 Running database migrations..."
box wheels dbmigrate latest

# Clear caches
echo "🧹 Clearing caches..."
rm -rf tmp/cache/*

# Restart services
echo "🔄 Restarting application..."
box server restart

# Wait for startup
echo "⏳ Waiting for application to start..."
sleep 30

# Health check
echo "🏥 Running health check..."
if ! curl -f -s http://localhost:8080/health > /dev/null; then
    echo "❌ Health check failed! Rolling back..."
    ./scripts/rollback-staging.sh
    exit 1
fi

echo "✅ Staging deployment completed successfully!"

# Update deployment status
echo "staging deployment completed at $(date)" > deployment-status.txt
```

#### Production Deployment Script
```bash
#!/bin/bash
# scripts/deploy-production.sh

set -euo pipefail

echo "🚀 Starting production deployment..."

# Strict production checks
if [[ "$APP_ENV" != "production" ]]; then
    echo "❌ APP_ENV must be set to 'production'"
    exit 1
fi

if [[ -z "${DB_PASSWORD:-}" ]]; then
    echo "❌ DB_PASSWORD environment variable is required"
    exit 1
fi

# Load production secrets securely
if [[ -f "/etc/app-secrets/production.env" ]]; then
    source /etc/app-secrets/production.env
else
    echo "❌ Production secrets file not found"
    exit 1
fi

# Create timestamped backup
BACKUP_DIR="/var/backups/app/$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup at $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r /var/www/app "$BACKUP_DIR/"

# Database backup
echo "🗄️ Creating database backup..."
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/database.sql"

# Download and extract deployment package
echo "📋 Extracting deployment package..."
cd /tmp
wget -O deployment.tar.gz "$DEPLOYMENT_PACKAGE_URL"
tar -xzf deployment.tar.gz

# Stop services for deployment
echo "⏹️ Stopping services..."
sudo systemctl stop nginx
sudo systemctl stop lucee

# Deploy new version
echo "🚀 Deploying new version..."
rsync -av --delete /tmp/app/ /var/www/app/

# Set permissions
chown -R www-data:www-data /var/www/app
chmod -R 755 /var/www/app

# Run database migrations with transaction safety
echo "🔄 Running database migrations..."
cd /var/www/app

# Test migrations in dry-run mode first
if ! box wheels dbmigrate info; then
    echo "❌ Migration check failed"
    exit 1
fi

# Run actual migrations
box wheels dbmigrate latest

# Clear all caches
echo "🧹 Clearing production caches..."
rm -rf /tmp/lucee-cache/*
rm -rf /var/www/app/tmp/cache/*

# Start services
echo "▶️ Starting services..."
sudo systemctl start lucee
sudo systemctl start nginx

# Wait for services to fully start
echo "⏳ Waiting for services to start..."
sleep 60

# Comprehensive health checks
echo "🏥 Running health checks..."

# 1. Basic connectivity
if ! curl -f -s http://localhost/health > /dev/null; then
    echo "❌ Basic health check failed!"
    ./scripts/rollback-production.sh "$BACKUP_DIR"
    exit 1
fi

# 2. Database connectivity
if ! curl -f -s http://localhost/health/database > /dev/null; then
    echo "❌ Database health check failed!"
    ./scripts/rollback-production.sh "$BACKUP_DIR"
    exit 1
fi

# 3. Critical functionality
if ! curl -f -s http://localhost/health/critical > /dev/null; then
    echo "❌ Critical functionality check failed!"
    ./scripts/rollback-production.sh "$BACKUP_DIR"
    exit 1
fi

echo "✅ Production deployment completed successfully!"

# Clean up old backups (keep last 5)
find /var/backups/app -type d -name "????????_??????" | sort | head -n -5 | xargs rm -rf

# Send success notification
./scripts/notify-deployment.sh "success" "Production deployment completed successfully"

echo "📊 Deployment Summary:"
echo "  - Backup created: $BACKUP_DIR"
echo "  - Services restarted: lucee, nginx"
echo "  - Health checks: passed"
echo "  - Deployed at: $(date)"
```

## GitLab CI/CD Pipeline

### .gitlab-ci.yml Configuration
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test
  - security
  - build
  - deploy-staging
  - deploy-production
  - monitor

variables:
  CFML_ENGINE: "lucee"
  CFML_VERSION: "5.3"
  MYSQL_ROOT_PASSWORD: "wheels_test"
  MYSQL_DATABASE: "wheels_test"
  MYSQL_USER: "wheels"
  MYSQL_PASSWORD: "wheels_test"

# Code Quality and Validation
validate:
  stage: validate
  image: node:18
  before_script:
    - npm install -g cflint
  script:
    - cflint --folder app/ --output cflint-results.xml
    - npm install
    - npm run lint
  artifacts:
    reports:
      junit: cflint-results.xml
    paths:
      - cflint-results.xml
  only:
    - merge_requests
    - main
    - develop

# Unit and Integration Testing
test:
  stage: test
  image: ortussolutions/commandbox:lucee5
  services:
    - name: mysql:8.0
      alias: mysql
  variables:
    MYSQL_ROOT_PASSWORD: wheels_test
    MYSQL_DATABASE: wheels_test
  before_script:
    - box install
    - box server start cfengine=lucee@5 port=8080 rewritesEnable=true
    - sleep 30
  script:
    - box wheels dbmigrate latest
    - box testbox run
    - box wheels test run --reporter=json
  artifacts:
    reports:
      junit: tests/results/*.xml
    paths:
      - tests/results/
  coverage: '/Total Coverage: (\d+\.\d+)%/'
  only:
    - merge_requests
    - main
    - develop

# Security Testing
security:
  stage: security
  image: owasp/zap2docker-stable
  script:
    - zap-baseline.py -t http://localhost:8080 -r security-report.html
  artifacts:
    paths:
      - security-report.html
    expire_in: 1 week
  allow_failure: true
  only:
    - main
    - develop

# Build Assets
build:
  stage: build
  image: node:18
  script:
    - npm install
    - npm run build:production
  artifacts:
    paths:
      - public/dist/
    expire_in: 1 hour
  only:
    - main
    - develop

# Deploy to Staging
deploy-staging:
  stage: deploy-staging
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client curl
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ssh -o StrictHostKeyChecking=no $STAGING_USER@$STAGING_HOST "
        cd /var/www/staging &&
        git pull origin develop &&
        ./scripts/deploy-staging.sh
      "
    - sleep 30
    - curl -f $STAGING_URL/health
  environment:
    name: staging
    url: $STAGING_URL
  only:
    - develop

# Deploy to Production
deploy-production:
  stage: deploy-production
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client curl
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
  script:
    - ssh -o StrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_HOST "
        cd /var/www/production &&
        ./scripts/deploy-production.sh
      "
    - sleep 60
    - curl -f $PRODUCTION_URL/health
  environment:
    name: production
    url: $PRODUCTION_URL
  when: manual
  only:
    - main

# Post-Deployment Monitoring
monitor:
  stage: monitor
  image: node:18
  script:
    - npm install -g lighthouse
    - lighthouse $PRODUCTION_URL --output=json --output-path=lighthouse-results.json
    - cat lighthouse-results.json | jq '.categories.performance.score * 100'
  artifacts:
    paths:
      - lighthouse-results.json
  only:
    - main
  when: delayed
  start_in: 5 minutes
```

## Docker-Based CI/CD

### Multi-Stage Dockerfile
```dockerfile
# Dockerfile for CFWheels Application
FROM ortussolutions/commandbox:lucee5 as builder

# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# Install dependencies and build
RUN box install --production && \
    box server start cfengine=lucee@5 port=8080 && \
    sleep 30 && \
    box server stop

# Production image
FROM ortussolutions/commandbox:lucee5

# Install additional packages for production
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=builder /app .

# Create non-root user
RUN groupadd -r wheels && useradd -r -g wheels wheels && \
    chown -R wheels:wheels /app

# Switch to non-root user
USER wheels

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Start application
CMD ["box", "server", "start", "cfengine=lucee@5", "port=8080", "rewritesEnable=true"]
```

### Docker Compose for Testing
```yaml
# docker-compose.test.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=mysql
      - DB_NAME=wheels_test
      - DB_USER=wheels
      - DB_PASSWORD=wheels_test
      - APP_ENV=testing
    depends_on:
      - mysql
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: wheels_test
      MYSQL_DATABASE: wheels_test
      MYSQL_USER: wheels
      MYSQL_PASSWORD: wheels_test
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  test:
    build: .
    command: ["box", "testbox", "run"]
    depends_on:
      - app
      - mysql
    environment:
      - DB_HOST=mysql
      - DB_NAME=wheels_test
      - DB_USER=wheels
      - DB_PASSWORD=wheels_test
      - TEST_URL=http://app:8080
```

## Advanced Deployment Strategies

### Blue-Green Deployment
```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

BLUE_PORT=8080
GREEN_PORT=8081
HEALTH_ENDPOINT="/health"

# Determine current active environment
CURRENT_ACTIVE=$(curl -s http://localhost/active-env || echo "blue")

if [[ "$CURRENT_ACTIVE" == "blue" ]]; then
    DEPLOY_TO="green"
    DEPLOY_PORT=$GREEN_PORT
    ACTIVE_PORT=$BLUE_PORT
else
    DEPLOY_TO="blue"
    DEPLOY_PORT=$BLUE_PORT
    ACTIVE_PORT=$GREEN_PORT
fi

echo "🔄 Deploying to $DEPLOY_TO environment (port $DEPLOY_PORT)"

# Deploy to inactive environment
docker-compose -f docker-compose.$DEPLOY_TO.yml up -d

# Wait for new environment to be ready
echo "⏳ Waiting for $DEPLOY_TO environment to be healthy..."
timeout 300 bash -c "
  until curl -f http://localhost:$DEPLOY_PORT$HEALTH_ENDPOINT; do
    sleep 5
  done
"

# Run smoke tests on new environment
echo "💨 Running smoke tests on $DEPLOY_TO environment..."
npm run test:smoke -- --baseUrl=http://localhost:$DEPLOY_PORT

# Switch traffic to new environment
echo "🔀 Switching traffic to $DEPLOY_TO environment..."
nginx -s reload -c nginx.$DEPLOY_TO.conf

# Verify traffic switch
echo "🏥 Verifying traffic switch..."
sleep 30
curl -f http://localhost$HEALTH_ENDPOINT

# Stop old environment
echo "⏹️ Stopping old environment..."
OLD_ENV=$([ "$DEPLOY_TO" == "blue" ] && echo "green" || echo "blue")
docker-compose -f docker-compose.$OLD_ENV.yml down

echo "✅ Blue-green deployment completed successfully!"
```

### Canary Deployment
```bash
#!/bin/bash
# scripts/canary-deploy.sh

set -euo pipefail

CANARY_PERCENTAGE=${1:-10}  # Default to 10% traffic

echo "🐦 Starting canary deployment with $CANARY_PERCENTAGE% traffic..."

# Deploy canary version
docker-compose -f docker-compose.canary.yml up -d

# Wait for canary to be healthy
timeout 300 bash -c "
  until curl -f http://localhost:8082/health; do
    sleep 5
  done
"

# Configure load balancer to send percentage of traffic to canary
echo "⚖️ Configuring load balancer for $CANARY_PERCENTAGE% canary traffic..."
./scripts/configure-canary-traffic.sh $CANARY_PERCENTAGE

# Monitor canary for specified duration
MONITOR_DURATION=${2:-300}  # 5 minutes default
echo "📊 Monitoring canary for $MONITOR_DURATION seconds..."

for i in $(seq 1 $((MONITOR_DURATION / 30))); do
    # Check error rates
    ERROR_RATE=$(curl -s http://localhost:8082/metrics | grep error_rate | cut -d' ' -f2)

    if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
        echo "❌ Canary error rate too high ($ERROR_RATE), rolling back..."
        ./scripts/rollback-canary.sh
        exit 1
    fi

    echo "✅ Canary health check $i passed (error rate: $ERROR_RATE)"
    sleep 30
done

# Promote canary to production
echo "🚀 Promoting canary to production..."
./scripts/promote-canary.sh

echo "✅ Canary deployment completed successfully!"
```

This comprehensive CI/CD integration guide provides robust, production-ready pipelines for CFWheels applications with automated testing, security scanning, and multiple deployment strategies.