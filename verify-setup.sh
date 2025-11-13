#!/bin/bash

# Setup Verification Script
# Checks if all services are running and accessible

echo "========================================="
echo "Monitoring Stack Verification"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local expected=$3

    printf "Checking %-20s ... " "$name"

    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    if [ "$response" == "$expected" ]; then
        echo -e "${GREEN}OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}FAILED${NC} (HTTP $response, expected $expected)"
        return 1
    fi
}

# Function to check if Docker is running
check_docker() {
    printf "Checking %-20s ... " "Docker"

    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo "Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if containers are running
check_containers() {
    local containers=("demo-app" "prometheus" "grafana" "node-exporter")
    local all_running=true

    for container in "${containers[@]}"; do
        printf "Checking container %-15s ... " "$container"

        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo -e "${GREEN}RUNNING${NC}"
        else
            echo -e "${RED}NOT RUNNING${NC}"
            all_running=false
        fi
    done

    if [ "$all_running" = false ]; then
        echo ""
        echo -e "${YELLOW}Some containers are not running. Start them with:${NC}"
        echo "docker-compose up -d"
        echo ""
    fi
}

# Main checks
echo "1. Docker Status"
echo "─────────────────────────────────────────"
check_docker
echo ""

echo "2. Container Status"
echo "─────────────────────────────────────────"
check_containers
echo ""

echo "3. Service Endpoints"
echo "─────────────────────────────────────────"

# Give services time to start if just launched
sleep 2

check_service "Demo App" "http://localhost:3000" "200"
check_service "Demo App /metrics" "http://localhost:3000/metrics" "200"
check_service "Prometheus" "http://localhost:9090" "200"
check_service "Prometheus API" "http://localhost:9090/api/v1/status/config" "200"
check_service "Node Exporter" "http://localhost:9100/metrics" "200"
check_service "Grafana" "http://localhost:3001" "302"

echo ""
echo "4. Prometheus Targets"
echo "─────────────────────────────────────────"

targets=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null)

if echo "$targets" | grep -q '"health":"up"'; then
    up_count=$(echo "$targets" | grep -o '"health":"up"' | wc -l)
    echo -e "Active targets: ${GREEN}${up_count}${NC}"
else
    echo -e "${RED}No active targets found${NC}"
fi

echo ""
echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Access Points:"
echo "  Demo App:    http://localhost:3000"
echo "  Prometheus:  http://localhost:9090"
echo "  Grafana:     http://localhost:3001 (admin/admin)"
echo ""
echo "Next Steps:"
echo "  1. Open Grafana dashboard at http://localhost:3001"
echo "  2. Trigger a test alert: curl http://localhost:3000/stress"
echo "  3. Run alert dispatcher: bash alert_dispatcher.sh --once"
echo ""
