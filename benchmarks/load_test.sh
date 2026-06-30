#!/usr/bin/env bash
# Concurrent throughput benchmark using wrk.
# Install wrk first: brew install wrk (Mac) / apt install wrk (Linux)
#
# Run: ./load_test.sh [base_url]

set -e

BASE_URL="${1:-http://localhost:3000}"
ENDPOINT="$BASE_URL/api/v1/webhooks/benchmark"
DURATION="15s"
THREADS=4
CONNECTIONS=50

cat > /tmp/wrk_payload.lua <<'EOF'
wrk.method = "POST"
wrk.body   = '{"event_type":"load.test","nested":{"a":1,"b":"x"}}'
wrk.headers["Content-Type"] = "application/json"
EOF

echo "Hitting $ENDPOINT for $DURATION with $CONNECTIONS connections / $THREADS threads..."
echo "Make sure Puma is running with the workers/threads from config/puma.rb"
echo ""

wrk -t"$THREADS" -c"$CONNECTIONS" -d"$DURATION" -s /tmp/wrk_payload.lua "$ENDPOINT"

echo ""
echo "Read 'Requests/sec' from the output above — that is your real"
echo "sustained throughput number. It will vary with worker/thread count,"
echo "machine, and whether Postgres is local or remote."
