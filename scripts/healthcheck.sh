#!/bin/bash
# Health check script for SimpleCP

API_URL="${API_URL:-http://localhost:49917}"
TIMEOUT=5

echo "=== SimpleCP Health Check ==="
echo ""
echo "Checking: $API_URL"
echo ""

# Check if API is responding
response=$(curl -s -w "\n%{http_code}" --max-time $TIMEOUT "$API_URL/health" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo "✓ API is healthy"
    echo ""
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    exit 0
else
    echo "✗ API is unhealthy (HTTP $http_code)"
    exit 1
fi
