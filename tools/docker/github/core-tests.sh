#!/bin/sh

echo "------------------------------- Starting Core-tests.sh -------------------------------"

pwd
cd tools/docker/github
ls -la
# box server status

cfengine=${1}
dbengine=${2}

./functions.sh

case $1 in
  lucee5)
    port="60005"
    ;;
  lucee6)
    port="60006"
    ;;
  lucee7)
    port="60007"
    ;;
  adobe2018)
    port="62018"
    ;;
  adobe2021)
    port="62021"
    ;;
  adobe2023)
    port="62023"
    ;;
  adobe2025)
    port="62025"
    ;;
  boxlang)
    port="60001"
    ;;
  mysql56)
    port="3306"
    ;;
  sqlserver)
    port="1433"
    ;;
  postgres)
    port="5432"
    ;;
  h2)
    port="9092"
    ;;
  oracle)
    port="1521"
    ;;
  *)
    port="unknown"
    ;;
esac

# Determine host based on environment
if [ -n "$GITHUB_ACTIONS" ]; then
    # In GitHub Actions, containers communicate via localhost
    echo "Running in GitHub Actions environment"
    host="localhost"
elif [ -f /.dockerenv ]; then
    # Running inside a Docker container
    echo "Running inside Docker container"
    # Try to use host.docker.internal or the service name
    if nc -zv host.docker.internal ${port} 2>&1 >/dev/null; then
        host="host.docker.internal"
    else
        host="${cfengine}"
    fi
else
    # Local development uses localhost
    echo "Running in local environment"
    host="localhost"
fi

echo "Using host: ${host}"

test_url="http://${host}:${port}/wheels/testbox?db=${dbengine}&format=json&only=failure,error"
# test_url="http://${host}:${port}/"
result_file="/tmp/${cfengine}-${dbengine}-result.txt"

echo "\nRUNNING SUITE (${cfengine}/${dbengine}):\n"
echo "Test URL: ${test_url}"
echo "Result file: ${result_file}"

# Check Docker containers status
echo "\nChecking Docker containers..."
docker ps -a | grep -E "(${cfengine}|${dbengine})" || echo "No matching containers found"

# Also show all running containers for debugging
echo "\nAll running containers:"
docker ps

# Try to get the actual exposed port from docker
echo "\nChecking actual exposed ports for ${cfengine}:"
docker port $(docker ps -q -f "name=${cfengine}") 2>/dev/null || echo "Could not get port mapping"

# Check if the service is ready
echo "\nChecking if service is ready on ${host}:${port}..."
nc -zv ${host} ${port} 2>&1 || echo "Port ${port} is not open on ${host}"

# Check container logs if available
echo "\nChecking container logs for ${cfengine}..."
# Try different container name patterns
docker logs "${cfengine}" 2>&1 | tail -20 || \
docker logs "wheels-${cfengine}" 2>&1 | tail -20 || \
docker logs "wheels-${cfengine}-1" 2>&1 | tail -20 || \
echo "Could not get container logs for ${cfengine}"

# Try to diagnose connectivity
echo "\nTrying basic connectivity test..."
curl -v --connect-timeout 5 "http://${host}:${port}/" 2>&1 | head -20

# Wait for service to be ready using server-up.sh logic
echo "\nWaiting for service to be ready..."
max_wait_iterations=30
wait_seconds=5
iterations=0

while [ "$iterations" -lt "$max_wait_iterations" ]; do
    iterations=$((iterations + 1))
    echo -n "Checking service (attempt ${iterations}/${max_wait_iterations})... "
    
    # Quick health check
    health_code=$(curl -s -o /dev/null --connect-timeout 2 --max-time 5 -w "%{http_code}" "http://${host}:${port}/" || echo "000")
    
    if [ "$health_code" = "200" ] || [ "$health_code" = "404" ] || [ "$health_code" = "302" ]; then
        echo "Service responding with ${health_code}"
        break
    else
        echo "Not ready (${health_code})"
        if [ "$iterations" -lt "$max_wait_iterations" ]; then
            sleep $wait_seconds
        fi
    fi
done

if [ "$iterations" -ge "$max_wait_iterations" ]; then
    echo "Service failed to become ready after ${max_wait_iterations} attempts"
fi

# Run the actual test with retry logic
echo "\nRunning test request with retry logic..."
max_retries=3
retry_count=0
http_code="000"

while [ "$retry_count" -lt "$max_retries" ] && [ "$http_code" = "000" ]; do
    retry_count=$((retry_count + 1))
    echo "Test attempt ${retry_count} of ${max_retries}..."
    
    http_code=$(curl -s -o "${result_file}" --max-time 900 --write-out "%{http_code}" "${test_url}";)
    
    if [ "$http_code" = "000" ] && [ "$retry_count" -lt "$max_retries" ]; then
        echo "Connection failed (code 000), waiting 10 seconds before retry..."
        sleep 10
    fi
done

echo "Final HTTP code: ${http_code}"

echo "\nls /tmp/:"
ls /tmp -la

echo "\nResult file:"
cat ${result_file}

echo "\nHTTP Code Pulled Down:"
echo ${http_code}

echo "\npwd:"
pwd

echo "\nls:"
ls -la

echo "\nwhich box"
which box

echo "\nResult file contents:"
if [ -f "$result_file" ]; then
    cat "$result_file"
else
    echo "Result file does not exist!"
fi

# Check for curl error codes
if [ "$http_code" = "000" ]; then
    echo "\nFAIL: Curl returned 000 - Connection failed"
    echo "Possible causes:"
    echo "- Service not running on port ${port}"
    echo "- Network/firewall blocking connection"
    echo "- Container not started or crashed"
    echo "- DNS resolution failure"
    exit 1
elif [ "$http_code" -eq "200" ]; then
    echo "\nPASS: HTTP Status Code was 200"
else
    echo "\nFAIL: Status Code: $http_code"
    exit 1
fi

echo "------------------------------- Ending Core-tests.sh -------------------------------"
