#!/bin/bash
set -e

# Start CockroachDB in background
cockroach start-single-node \
  --insecure \
  --store=/cockroach/cockroach-data \
  --http-addr=0.0.0.0:8080 &

# Wait for DB to be ready using a proper readiness loop
for i in $(seq 1 30); do
  if cockroach sql --insecure --host=localhost:26257 --execute="SELECT 1" > /dev/null 2>&1; then
    echo "CockroachDB is ready"
    break
  fi
  echo "Waiting for CockroachDB... (attempt $i/30)"
  sleep 2
done

# Run init SQL
cockroach sql --insecure --host=localhost:26257 < /docker-init/init.sql

# Keep container running
wait
