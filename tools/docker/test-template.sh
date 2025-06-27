#!/bin/bash

# Wheels Docker Test Script
# This script allows testing templates and examples without using the Wheels CLI
# Usage: ./test-template.sh [options]

set -e

# Default values
ENGINE="lucee@6"
DB="h2"
PORT="8080"
NAME="wheels-test"
DETACH=false
BUILD=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -e, --engine    CFML engine (default: lucee@6)"
    echo "                  Options: lucee@5, lucee@6, lucee@7, adobe@2018, adobe@2021, adobe@2023, adobe@2025"
    echo "  -d, --db        Database (default: h2)"
    echo "                  Options: h2, mysql, postgres, sqlserver"
    echo "  -p, --port      Port to expose (default: 8080)"
    echo "  -n, --name      Container name prefix (default: wheels-test)"
    echo "  --detach        Run containers in detached mode"
    echo "  --build         Force rebuild of Docker images"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --engine=adobe@2021 --db=mysql --port=8081"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -e|--engine)
            ENGINE="$2"
            shift
            shift
            ;;
        -d|--db)
            DB="$2"
            shift
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift
            shift
            ;;
        -n|--name)
            NAME="$2"
            shift
            shift
            ;;
        --detach)
            DETACH=true
            shift
            ;;
        --build)
            BUILD=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Function to detect context
detect_context() {
    local cwd=$(pwd)
    local monorepo_root=""
    
    # Find monorepo root
    local current_path="$cwd"
    while [[ ${#current_path} -gt 1 ]]; do
        if [[ -f "$current_path/compose.yml" && -d "$current_path/templates" && -d "$current_path/examples" ]]; then
            monorepo_root="$current_path"
            break
        fi
        current_path=$(dirname "$current_path")
    done
    
    if [[ -z "$monorepo_root" ]]; then
        echo -e "${RED}Error: Could not find monorepo root${NC}"
        echo "This script must be run from a Wheels template or example directory"
        exit 1
    fi
    
    # Check if we're in a template or example directory
    if [[ "$cwd" == *"/templates/"* ]]; then
        CONTEXT_TYPE="template"
        CONTEXT_NAME=$(echo "$cwd" | sed "s|.*\/templates\/||" | cut -d'/' -f1)
    elif [[ "$cwd" == *"/examples/"* ]]; then
        CONTEXT_TYPE="example"
        CONTEXT_NAME=$(echo "$cwd" | sed "s|.*\/examples\/||" | cut -d'/' -f1)
    else
        echo -e "${RED}Error: This script must be run from a Wheels template or example directory${NC}"
        echo "Current directory: $cwd"
        exit 1
    fi
    
    MONOREPO_ROOT="$monorepo_root"
}

# Function to get engine configuration
get_engine_config() {
    case "$ENGINE" in
        "lucee@5")
            ENGINE_IMAGE="cfwheels-test-lucee5:v1.0.2"
            ENGINE_PORT="60005"
            ;;
        "lucee@6")
            ENGINE_IMAGE="cfwheels-test-lucee6:v1.0.2"
            ENGINE_PORT="60006"
            ;;
        "lucee@7")
            ENGINE_IMAGE="cfwheels-test-lucee7:v1.0.0"
            ENGINE_PORT="60007"
            ;;
        "adobe@2018")
            ENGINE_IMAGE="cfwheels-test-adobe2018:v1.0.2"
            ENGINE_PORT="62018"
            ;;
        "adobe@2021")
            ENGINE_IMAGE="cfwheels-test-adobe2021:v1.0.2"
            ENGINE_PORT="62021"
            ;;
        "adobe@2023")
            ENGINE_IMAGE="cfwheels-test-adobe2023:v1.0.1"
            ENGINE_PORT="62023"
            ;;
        "adobe@2025")
            ENGINE_IMAGE="cfwheels-test-adobe2025:v1.0.0"
            ENGINE_PORT="62025"
            ;;
        *)
            echo -e "${RED}Error: Unsupported engine: $ENGINE${NC}"
            exit 1
            ;;
    esac
}

# Function to get database port
get_db_port() {
    case "$DB" in
        "mysql") DB_PORT="3306" ;;
        "postgres") DB_PORT="5432" ;;
        "sqlserver") DB_PORT="1433" ;;
    esac
}

# Main execution
echo -e "${MAGENTA}Wheels Docker Test Environment${NC}"
echo ""

# Detect context
detect_context

echo "Context:    $CONTEXT_TYPE ($CONTEXT_NAME)"
echo "Engine:     $ENGINE"
echo "Database:   $DB"
echo "Port:       $PORT"
echo ""

# Get engine configuration
get_engine_config

# Create .wheels-test directory
mkdir -p .wheels-test

# Generate docker-compose.yml
echo -e "${GREEN}✓ Generating docker-compose.yml${NC}"

cat > .wheels-test/docker-compose.yml << EOF
version: '3.8'

networks:
  ${NAME}-network:
    driver: bridge

services:
  app:
    image: ${ENGINE_IMAGE}
    container_name: ${NAME}-app
    volumes:
      # Mount the current directory as the application
      - ..:/cfwheels-test-suite
      # Mount the framework from monorepo
      - ${MONOREPO_ROOT}/core/src/wheels:/cfwheels-test-suite/vendor/wheels
      # Mount engine-specific configuration files
      - ${MONOREPO_ROOT}/tools/docker/${ENGINE}/server.json:/cfwheels-test-suite/server.json:ro
      - ${MONOREPO_ROOT}/tools/docker/${ENGINE}/box.json:/cfwheels-test-suite/box.json:ro
      - ${MONOREPO_ROOT}/tools/docker/${ENGINE}/CFConfig.json:/cfwheels-test-suite/CFConfig.json:ro
EOF

# Add settings.cfm mount if not H2
if [[ "$DB" != "h2" ]]; then
    cat >> .wheels-test/docker-compose.yml << EOF
      - ${MONOREPO_ROOT}/tools/docker/${ENGINE}/settings.cfm:/cfwheels-test-suite/config/settings.cfm:ro
EOF
fi

cat >> .wheels-test/docker-compose.yml << EOF
    ports:
      - "${PORT}:${ENGINE_PORT}"
    environment:
      - WHEELS_ENV=development
      - WHEELS_RELOAD_PASSWORD=wheels
EOF

# Add database environment variables if not H2
if [[ "$DB" != "h2" ]]; then
    get_db_port
    cat >> .wheels-test/docker-compose.yml << EOF
      - WHEELS_DATASOURCE=${DB}
      - WHEELS_DATABASE_HOST=${DB}
      - WHEELS_DATABASE_PORT=${DB_PORT}
      - WHEELS_DATABASE_NAME=wheelstestdb
      - WHEELS_DATABASE_USERNAME=wheelstestdb
      - WHEELS_DATABASE_PASSWORD=wheelstestdb
EOF
fi

cat >> .wheels-test/docker-compose.yml << EOF
    networks:
      - ${NAME}-network
EOF

# Add depends_on if using external database
if [[ "$DB" != "h2" ]]; then
    cat >> .wheels-test/docker-compose.yml << EOF
    depends_on:
      - ${DB}
EOF
fi

cat >> .wheels-test/docker-compose.yml << EOF
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${ENGINE_PORT}"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
EOF

# Add database service if not H2
if [[ "$DB" != "h2" ]]; then
    case "$DB" in
        "mysql")
            cat >> .wheels-test/docker-compose.yml << EOF

  mysql:
    image: mysql:8.0
    container_name: ${NAME}-mysql
    environment:
      MYSQL_ROOT_PASSWORD: wheelstestdb
      MYSQL_DATABASE: wheelstestdb
      MYSQL_USER: wheelstestdb
      MYSQL_PASSWORD: wheelstestdb
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - ${NAME}-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p\$\$MYSQL_ROOT_PASSWORD"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
EOF
            ;;
        "postgres")
            cat >> .wheels-test/docker-compose.yml << EOF

  postgres:
    image: postgres:14
    container_name: ${NAME}-postgres
    environment:
      POSTGRES_USER: wheelstestdb
      POSTGRES_PASSWORD: wheelstestdb
      POSTGRES_DB: wheelstestdb
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - ${NAME}-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U wheelstestdb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
EOF
            ;;
        "sqlserver")
            cat >> .wheels-test/docker-compose.yml << EOF

  sqlserver:
    image: cfwheels-sqlserver:v1.0.2
    container_name: ${NAME}-sqlserver
    environment:
      MSSQL_SA_PASSWORD: x!bsT8t60yo0cTVTPq
      ACCEPT_EULA: Y
      MSSQL_PID: Developer
      MSSQL_MEMORY_LIMIT_MB: 2048
    volumes:
      - sqlserver-data:/var/opt/mssql
    networks:
      - ${NAME}-network
    healthcheck:
      test: /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "\$\$MSSQL_SA_PASSWORD" -Q "SELECT 1" -C || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s
EOF
            ;;
    esac
fi

# Add volumes section if using external database
if [[ "$DB" != "h2" ]]; then
    cat >> .wheels-test/docker-compose.yml << EOF

volumes:
  ${DB}-data:
EOF
fi

# Update .gitignore if needed
if [[ -f .gitignore ]]; then
    if ! grep -q ".wheels-test/" .gitignore; then
        echo ".wheels-test/" >> .gitignore
        echo -e "${GREEN}✓ Updated .gitignore${NC}"
    fi
else
    echo ".wheels-test/" > .gitignore
    echo -e "${GREEN}✓ Created .gitignore${NC}"
fi

# Start Docker containers
echo ""
echo -e "${YELLOW}Starting Docker containers...${NC}"

cd .wheels-test

if [[ "$DETACH" == true ]]; then
    DOCKER_CMD="docker-compose up -d"
else
    DOCKER_CMD="docker-compose up"
fi

if [[ "$BUILD" == true ]]; then
    DOCKER_CMD="$DOCKER_CMD --build"
fi

if [[ "$DETACH" == true ]]; then
    $DOCKER_CMD
    echo ""
    echo -e "${GREEN}✓ Docker containers started successfully!${NC}"
    echo ""
    echo "Application URL: http://localhost:${PORT}"
    echo ""
    echo -e "${YELLOW}To view logs, run: cd .wheels-test && docker-compose logs -f${NC}"
    echo -e "${YELLOW}To stop containers, run: cd .wheels-test && docker-compose down${NC}"
else
    echo ""
    echo -e "${CYAN}Press Ctrl+C to stop the containers${NC}"
    echo ""
    $DOCKER_CMD
fi