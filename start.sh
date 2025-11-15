#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Grafana Observability Stack Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards
mkdir -p alertmanager
mkdir -p backups

# Check if configs exist
echo -e "${YELLOW}Checking configurations...${NC}"
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found${NC}"
    exit 1
fi

# Validate docker-compose configuration
echo -e "${YELLOW}Validating configuration...${NC}"
if ! docker-compose config > /dev/null 2>&1; then
    echo -e "${RED}Error: Invalid docker-compose configuration${NC}"
    exit 1
fi

# Pull images
echo -e "${YELLOW}Pulling Docker images...${NC}"
docker-compose pull

# Start services
echo -e "${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"
services=(
    "grafana:3000:Grafana"
    "prometheus:9090:Prometheus"
    "loki:3100:Loki"
    "tempo:3200:Tempo"
    "mimir:8080:Mimir"
)

all_healthy=true
for service in "${services[@]}"; do
    IFS=':' read -r name port display_name <<< "$service"
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}" | grep -q "200\|302"; then
        echo -e "${GREEN}✓ ${display_name} is running${NC}"
    else
        echo -e "${YELLOW}⚠ ${display_name} might still be starting...${NC}"
        all_healthy=false
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Stack Started Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Access your services at:"
echo -e "  ${GREEN}Grafana:${NC}      http://localhost:3000"
echo -e "                (admin / StrongPass123)"
echo -e "  ${GREEN}Prometheus:${NC}   http://localhost:9090"
echo -e "  ${GREEN}Alertmanager:${NC} http://localhost:9093"
echo -e "  ${GREEN}Mimir:${NC}        http://localhost:8080"
echo -e "  ${GREEN}Loki:${NC}         http://localhost:3100"
echo -e "  ${GREEN}Tempo:${NC}        http://localhost:3200"
echo ""
echo -e "Send telemetry data to:"
echo -e "  ${GREEN}OTLP gRPC:${NC}    localhost:4317"
echo -e "  ${GREEN}OTLP HTTP:${NC}    http://localhost:4318"
echo ""
echo -e "View logs:"
echo -e "  ${YELLOW}docker-compose logs -f${NC}"
echo ""
echo -e "Stop the stack:"
echo -e "  ${YELLOW}docker-compose down${NC}"
echo ""

if [ "$all_healthy" = false ]; then
    echo -e "${YELLOW}Note: Some services may take a few more seconds to fully start.${NC}"
    echo -e "${YELLOW}Run 'docker-compose ps' to check status.${NC}"
    echo ""
fi

