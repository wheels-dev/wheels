#!/bin/sh

echo "------------------------------- Starting Core-tests.sh -------------------------------"

pwd
ls ../
# box server status

cfengine=${1}
dbengine=${2}

. $(dirname "$0")/functions.sh

port="$(get_port ${cfengine})"
db="$(get_db ${dbengine})"

test_url="http://127.0.0.1:${port}/wheels/testbox?db=${db}&format=json&only=failure,error"
result_file="/tmp/${cfengine}-${db}-result.txt"
junit_url="http://127.0.0.1:${port}/wheels/testbox?db=${db}&format=junit"
junit_file="/tmp/${cfengine}-${db}-junit.xml"

echo "\nRUNNING SUITE (${cfengine}/${dbengine}):\n"
echo ${test_url}
echo ${result_file}

http_code=$(curl -s -o "${result_file}" --write-out "%{http_code}" "${test_url}";)

# Also fetch JUnit format for artifact upload
# This will be used by GitHub Actions to display test results in the UI
echo "\nFetching JUnit results..."
echo "JUnit URL: ${junit_url}"
echo "JUnit file: ${junit_file}"
curl -s -o "${junit_file}" "${junit_url}"

echo ${http_code}

echo "\nls /tmp/:"
ls /tmp -la

echo "\nResult file:"
cat ${result_file}

echo "\nJUnit file preview (first 20 lines):"
head -20 ${junit_file} || echo "JUnit file not found or empty"

echo "\nHTTP Code Pulled Down:"
echo ${http_code}

echo "\npwd:"
pwd

echo "\nls:"
ls -la

echo "\nwhich box"
which box

echo "\n"
cat $result_file

if [ "$http_code" -eq "200" ]; then
    echo "\nPASS: HTTP Status Code was 200"
else
    echo "\nFAIL: Status Code: $http_code"
    exit 1
fi

echo "------------------------------- Ending Core-tests.sh -------------------------------"
