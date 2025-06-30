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

# test_url="http://localhost:${port}/wheels/testbox?db=${dbengine}&format=json&only=failure,error"
test_url="http://localhost:${port}/?db=${dbengine}&format=json&only=failure,error"
result_file="/tmp/${cfengine}-${db}-result.txt"

echo "\nRUNNING SUITE (${cfengine}/${dbengine}):\n"
echo ${test_url}
echo ${result_file}

http_code=$(curl -s -o "${result_file}" --write-out "%{http_code}" "${test_url}";)

echo ${http_code}

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

echo "\n"
cat $result_file

if [ "$http_code" -eq "200" ]; then
    echo "\nPASS: HTTP Status Code was 200"
else
    echo "\nFAIL: Status Code: $http_code"
    exit 1
fi

echo "------------------------------- Ending Core-tests.sh -------------------------------"
