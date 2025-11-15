#!/bin/bash

# Test script to send sample telemetry data to the observability stack

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Testing Observability Stack${NC}"
echo ""

# Test Loki (Logs)
echo -e "${YELLOW}Testing Loki (Logs)...${NC}"
TIMESTAMP=$(date +%s)000000000
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d "{
    \"streams\": [
      {
        \"stream\": {
          \"job\": \"test\",
          \"level\": \"info\",
          \"service\": \"test-app\"
        },
        \"values\": [
          [\"${TIMESTAMP}\", \"Test log message from test script\"]
        ]
      }
    ]
  }" && echo -e "${GREEN}✓ Log sent to Loki${NC}" || echo -e "${RED}✗ Failed to send log to Loki${NC}"

echo ""

# Test Mimir (Metrics)
echo -e "${YELLOW}Testing Mimir (Metrics)...${NC}"
cat <<EOF | curl -X POST http://localhost:8080/api/v1/push \
  -H "Content-Type: application/x-protobuf" \
  -H "X-Prometheus-Remote-Write-Version: 0.1.0" \
  --data-binary @- && echo -e "${GREEN}✓ Metrics sent to Mimir${NC}" || echo -e "${RED}✗ Failed to send metrics to Mimir${NC}"
EOF

echo ""

# Test OTLP HTTP endpoint
echo -e "${YELLOW}Testing OTLP HTTP endpoint...${NC}"
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [
      {
        "resource": {
          "attributes": [
            {
              "key": "service.name",
              "value": { "stringValue": "test-service" }
            }
          ]
        },
        "scopeSpans": [
          {
            "scope": {
              "name": "test-scope"
            },
            "spans": [
              {
                "traceId": "5B8EFFF798038103D269B633813FC60C",
                "spanId": "EEE19B7EC3C1B174",
                "name": "test-span",
                "kind": 1,
                "startTimeUnixNano": "'$(date +%s%N)'",
                "endTimeUnixNano": "'$(date +%s%N)'",
                "attributes": [
                  {
                    "key": "test.attribute",
                    "value": { "stringValue": "test-value" }
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }' && echo -e "${GREEN}✓ Trace sent via OTLP HTTP${NC}" || echo -e "${RED}✗ Failed to send trace${NC}"

echo ""

# Check service endpoints
echo -e "${YELLOW}Checking service endpoints...${NC}"
services=(
    "http://localhost:3000/api/health:Grafana"
    "http://localhost:9090/-/healthy:Prometheus"
    "http://localhost:3100/ready:Loki"
    "http://localhost:3200/ready:Tempo"
    "http://localhost:8080/ready:Mimir"
    "http://localhost:13133/:OTel Collector"
)

for service in "${services[@]}"; do
    IFS=':' read -r url name <<< "$service"
    if curl -s -o /dev/null -f "$url"; then
        echo -e "${GREEN}✓ ${name} is healthy${NC}"
    else
        echo -e "${RED}✗ ${name} is not responding${NC}"
    fi
done

echo ""
echo -e "${GREEN}Testing complete!${NC}"
echo ""
echo "You can now:"
echo "1. Open Grafana at http://localhost:3000 (admin/StrongPass123)"
echo "2. Go to Explore and select Loki datasource"
echo "3. Query: {job=\"test\"}"
echo "4. You should see the test log message"
echo ""
echo "For traces, select Tempo datasource and search for recent traces"

