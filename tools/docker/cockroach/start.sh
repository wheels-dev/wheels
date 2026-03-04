#!/bin/bash
set -e

# Start CockroachDB in background
cockroach start-single-node \
  --insecure \
  --store=/cockroach/cockroach-data \
  --http-addr=0.0.0.0:8080 &

# Wait for DB to be ready
sleep 10

# Run init SQL
cockroach sql --insecure --host=localhost:26257 < /docker-init/init.sql

# Keep container running
wait