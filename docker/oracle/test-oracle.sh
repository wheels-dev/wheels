#!/bin/bash

echo "=== Oracle Testing Script for CFWheels ==="

# Function to check if Oracle is ready
check_oracle_ready() {
    echo "Checking if Oracle is ready..."
    docker exec wheels-oracle-1 /opt/oracle/checkDBStatus.sh 2>/dev/null
    return $?
}

# Wait for Oracle to be ready
echo "Waiting for Oracle to start (this may take 5-10 minutes)..."
while ! check_oracle_ready; do
    echo -n "."
    sleep 30
done
echo ""
echo "Oracle is ready!"

# Test connection with sqlplus
echo "Testing Oracle connection..."
docker exec wheels-oracle-1 sh -c 'echo "SELECT 1 FROM DUAL;" | sqlplus -s wheelstestdb/wheelstestdb123!@FREEPDB1' 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Oracle connection successful"
else
    echo "✗ Oracle connection failed"
    exit 1
fi

# Start Lucee container
echo "Starting Lucee 5 container..."
docker compose --profile lucee up -d lucee5

# Wait for Lucee to start
echo "Waiting for Lucee to start..."
sleep 30

# Run tests
echo "Running CFWheels tests against Oracle..."
docker compose exec lucee5 curl -s "http://localhost:60005/wheels/testbox?db=oracle&format=json&only=failure,error" -o /tmp/oracle-test-results.json

# Check results
if [ -f /tmp/oracle-test-results.json ]; then
    echo "Test results saved to /tmp/oracle-test-results.json"
    # Display summary
    docker compose exec lucee5 curl -s "http://localhost:60005/wheels/testbox?db=oracle&format=text&only=failure,error"
else
    echo "Failed to get test results"
fi

echo "=== Oracle Testing Complete ==="