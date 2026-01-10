#!/bin/bash

# Set error handling
set -e

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting SQL Server..."

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

# Set a maximum wait time (in seconds)
MAX_WAIT=240
START_TIME=$(date +%s)

# Wait for SQL Server to start with timeout
log "Waiting for SQL Server to accept connections (timeout: ${MAX_WAIT}s)..."
while ! /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${MSSQL_SA_PASSWORD}" -Q "SELECT 1" -C > /dev/null 2>&1; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $MAX_WAIT ]; then
        log "ERROR: Timed out waiting for SQL Server to start after ${MAX_WAIT} seconds"
        log "Dumping SQL Server error log:"
        cat /var/opt/mssql/log/errorlog || log "Could not access error log"
        exit 1
    fi
    
    # Check if SQL Server is still running
    if ! kill -0 $SQL_PID 2>/dev/null; then
        log "ERROR: SQL Server process died unexpectedly"
        log "Dumping SQL Server error log:"
        cat /var/opt/mssql/log/errorlog || log "Could not access error log"
        exit 1
    fi
    
    log "Still waiting... (${ELAPSED}s elapsed)"
    sleep 5
done

log "SQL Server started successfully after $ELAPSED seconds"

# Create the database
log "Creating database 'wheelstestdb'..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${MSSQL_SA_PASSWORD}" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'wheelstestdb') CREATE DATABASE wheelstestdb" -C

if [ $? -eq 0 ]; then
    log "Database 'wheelstestdb' created successfully"
else
    log "ERROR: Failed to create database"
    exit 1
fi

log "SQL Server setup completed"

# Keep the container running but trap signals to shutdown cleanly
trap 'kill $SQL_PID; exit 0' SIGTERM SIGINT

# Wait for the SQL Server process to terminate
wait $SQL_PID