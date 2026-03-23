#!/usr/bin/env bash
#
# Wheels Contributor Quick-Start
# One-command setup for a local development environment.
#
# Usage:
#   bash tools/scripts/setup.sh            # Default: app + MySQL
#   bash tools/scripts/setup.sh --full     # App + all databases
#   bash tools/scripts/setup.sh --docker   # Docker-only dev environment
#   bash tools/scripts/setup.sh --help     # Show usage
#
# Idempotent — safe to re-run at any time.

set -euo pipefail

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors (disabled when not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' YELLOW='' RED='' BLUE='' BOLD='' RESET=''
fi

# Defaults
MODE="default"        # default | full | docker
HEALTH_RETRIES=30
HEALTH_INTERVAL=2

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

info()  { printf "${BLUE}→${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}!${RESET} %s\n" "$*"; }
fail()  { printf "${RED}✗${RESET} %s\n" "$*" >&2; }
header(){ printf "\n${BOLD}%s${RESET}\n" "$*"; }

usage() {
  cat <<EOF
${BOLD}Wheels Contributor Quick-Start${RESET}

Usage: bash tools/scripts/setup.sh [OPTIONS]

Options:
  --full      Start all database services (MySQL, PostgreSQL, SQL Server, etc.)
  --docker    Use Docker-only dev environment (no local CommandBox needed)
  --help      Show this help message

Without flags, starts MySQL and uses local CommandBox (if installed).
EOF
  exit 0
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

# ──────────────────────────────────────────────
# Parse arguments
# ──────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --full)   MODE="full" ;;
    --docker) MODE="docker" ;;
    --help|-h) usage ;;
    *)
      fail "Unknown option: $arg"
      usage
      ;;
  esac
done

# ──────────────────────────────────────────────
# Step 1: Check prerequisites
# ──────────────────────────────────────────────

header "Step 1/5: Checking prerequisites"

MISSING=()

if check_command docker; then
  ok "docker found"
else
  MISSING+=("docker")
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose found"
elif docker-compose version >/dev/null 2>&1; then
  ok "docker-compose (legacy) found"
else
  MISSING+=("docker compose")
fi

HAS_BOX=false
if check_command box; then
  HAS_BOX=true
  ok "CommandBox (box) found"
else
  if [ "$MODE" = "docker" ]; then
    ok "CommandBox not required (--docker mode)"
  else
    warn "CommandBox (box) not found — install from https://www.ortussolutions.com/products/commandbox"
    warn "Or use: bash tools/scripts/setup.sh --docker"
  fi
fi

if check_command git; then
  ok "git found"
else
  MISSING+=("git")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  fail "Missing required tools: ${MISSING[*]}"
  fail "Install them and re-run this script."
  exit 1
fi

# Verify Docker daemon is running
if ! docker info >/dev/null 2>&1; then
  fail "Docker daemon is not running. Start Docker Desktop (or dockerd) and try again."
  exit 1
fi
ok "Docker daemon is running"

# ──────────────────────────────────────────────
# Step 2: Start database services
# ──────────────────────────────────────────────

header "Step 2/5: Starting database services"

cd "$PROJECT_ROOT"

if [ "$MODE" = "full" ]; then
  info "Starting all databases (MySQL, PostgreSQL, SQL Server, CockroachDB, Oracle)..."
  docker compose up -d mysql postgres sqlserver cockroachdb cockroachdb-init oracle
  ok "All database containers started"
elif [ "$MODE" = "docker" ]; then
  info "Starting Docker dev environment (app + H2 embedded database)..."
  docker compose -f docker-compose.dev.yml up -d
  ok "Docker dev environment started"
else
  info "Starting MySQL..."
  docker compose up -d mysql
  ok "MySQL container started"
fi

# ──────────────────────────────────────────────
# Step 3: Wait for database health
# ──────────────────────────────────────────────

header "Step 3/5: Waiting for database health checks"

wait_for_healthy() {
  local service="$1"
  local retries="$HEALTH_RETRIES"

  # Check if container exists and has a health check
  local container_id
  container_id=$(docker compose ps -q "$service" 2>/dev/null || true)
  if [ -z "$container_id" ]; then
    warn "Service $service is not running — skipping health check"
    return 0
  fi

  info "Waiting for $service to be healthy..."
  while [ "$retries" -gt 0 ]; do
    local status
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "none")
    case "$status" in
      healthy)
        ok "$service is healthy"
        return 0
        ;;
      none)
        # No health check defined — assume ready
        ok "$service is running (no health check)"
        return 0
        ;;
      *)
        retries=$((retries - 1))
        sleep "$HEALTH_INTERVAL"
        ;;
    esac
  done

  warn "$service did not become healthy in time (may still be starting)"
  return 0
}

if [ "$MODE" = "docker" ]; then
  wait_for_healthy "app"
elif [ "$MODE" = "full" ]; then
  wait_for_healthy "mysql"
  wait_for_healthy "postgres"
  wait_for_healthy "sqlserver"
  wait_for_healthy "cockroachdb"
else
  wait_for_healthy "mysql"
fi

# ──────────────────────────────────────────────
# Step 4: Install dependencies & start app server
# ──────────────────────────────────────────────

header "Step 4/5: Setting up application"

if [ "$MODE" = "docker" ]; then
  info "Application runs inside Docker — no local install needed"
  ok "Docker dev container handles dependencies automatically"
else
  if [ "$HAS_BOX" = true ]; then
    info "Installing CommandBox dependencies..."
    box install --force 2>&1 | tail -5
    ok "Dependencies installed"

    # Check if server is already running
    if box server status 2>/dev/null | grep -q "running"; then
      ok "CommandBox server is already running"
    else
      info "Starting CommandBox server..."
      box server start 2>&1 | tail -5
      ok "CommandBox server started"
    fi
  else
    warn "Skipping app server start — install CommandBox or use --docker mode"
  fi
fi

# ──────────────────────────────────────────────
# Step 5: Verify environment
# ──────────────────────────────────────────────

header "Step 5/5: Verifying environment"

APP_PORT="${WHEELS_DEV_PORT:-8080}"
APP_URL="http://localhost:$APP_PORT"

verify_http() {
  local url="$1"
  local retries=10
  local interval=3

  while [ "$retries" -gt 0 ]; do
    if curl -sf -o /dev/null "$url" 2>/dev/null; then
      return 0
    fi
    retries=$((retries - 1))
    sleep "$interval"
  done
  return 1
}

if [ "$MODE" = "docker" ]; then
  info "Checking Docker dev server at $APP_URL ..."
  if verify_http "$APP_URL"; then
    ok "Application is responding"
  else
    warn "Application not responding yet — it may need more time to start"
    warn "Check status with: docker compose -f docker-compose.dev.yml logs app"
  fi
elif [ "$HAS_BOX" = true ]; then
  info "Checking local server at $APP_URL ..."
  if verify_http "$APP_URL"; then
    ok "Application is responding"
  else
    warn "Application not responding yet — check: box server log"
  fi
else
  info "Skipping HTTP check (no app server running)"
fi

# ──────────────────────────────────────────────
# Success summary
# ──────────────────────────────────────────────

header "Setup Complete!"

cat <<EOF

${BOLD}URLs:${RESET}
  App:          $APP_URL
  Test Runner:  $APP_URL/wheels/app/tests
  Admin:        $APP_URL/lucee/admin/web.cfm
EOF

if [ "$MODE" = "docker" ]; then
  cat <<EOF

${BOLD}Docker Commands:${RESET}
  Logs:         docker compose -f docker-compose.dev.yml logs -f app
  Stop:         docker compose -f docker-compose.dev.yml down
  Restart:      docker compose -f docker-compose.dev.yml restart
EOF
else
  cat <<EOF

${BOLD}Database Credentials (MySQL):${RESET}
  Host:         localhost:3307
  Database:     wheelstestdb
  User:         wheelstestdb
  Password:     wheelstestdb
EOF

  if [ "$MODE" = "full" ]; then
    cat <<EOF

${BOLD}Additional Databases:${RESET}
  PostgreSQL:   localhost:5433  (wheelstestdb / wheelstestdb)
  SQL Server:   localhost:1434  (SA / x!bsT8t60yo0cTVTPq)
  CockroachDB:  localhost:26258 (wheelstestdb, insecure)
  Oracle:       localhost:1522  (wheelstestdb / wheelstestdb)
EOF
  fi

  if [ "$HAS_BOX" = true ]; then
    cat <<EOF

${BOLD}CommandBox Commands:${RESET}
  Server log:   box server log
  Stop server:  box server stop
  Run tests:    box testbox run
  Reload app:   curl "$APP_URL/?reload=true&password=commandbox"
EOF
  fi

  cat <<EOF

${BOLD}Database Commands:${RESET}
  Stop DBs:     docker compose down
  DB logs:      docker compose logs -f mysql
  Reset DBs:    docker compose down -v && docker compose up -d mysql
EOF
fi

cat <<EOF

${BOLD}Next Steps:${RESET}
  1. Open ${APP_URL} in your browser
  2. Run the test suite at ${APP_URL}/wheels/app/tests
  3. Start coding! Edit files in app/, config/, or tests/
  4. Read CONTRIBUTING.md for PR guidelines

${GREEN}Happy hacking!${RESET}
EOF
