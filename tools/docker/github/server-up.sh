#!/bin/sh

. $(dirname "$0")/functions.sh

port="$(get_port ${1})"

max_iterations=10
wait_seconds=6
http_endpoint="http://127.0.0.1:${port}"

iterations=0
while true; do
  iterations=$(expr $iterations + 1)

	echo -n "Attempt ${iterations}.. "
	sleep $wait_seconds

  # store the whole response with the status at the and
  http_response=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" $http_endpoint)
  # extract the status
  http_status=$(echo $http_response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  # extract the body
  http_body=$(echo $http_response | sed -e 's/HTTPSTATUS\:.*//g')

  # print the status & body
  echo "$http_status"

	if [ "$http_status" -eq 200 ]; then
		echo "Server Up"
		break
  else
    echo "$http_body"
	fi

	if [ "$iterations" -ge "$max_iterations" ]; then
		echo "Loop Timeout"
		exit 1
	fi
done
