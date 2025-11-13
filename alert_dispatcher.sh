#!/bin/bash

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
LOG_FILE="${LOG_FILE:-./alerts.log}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' 

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

fetch_alerts() {
    local response=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts")

    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to connect to Prometheus at ${PROMETHEUS_URL}"
        return 1
    fi

    echo "$response"
}

process_alerts() {
    local alerts_json="$1"

    local alert_count=$(echo "$alerts_json" | grep -o '"state":"firing"' | wc -l)

    if [ "$alert_count" -eq 0 ]; then
        echo -e "${GREEN}[INFO] No active alerts${NC}"
        log_message "INFO: No active alerts detected"
        return 0
    fi

    echo -e "${RED}[ALERT] Found $alert_count active alert(s)${NC}"
    log_message "ALERT: Found $alert_count active alert(s)"

    echo "$alerts_json" | grep -o '"alertname":"[^"]*"' | while read -r line; do
        alert_name=$(echo "$line" | sed 's/"alertname":"//g' | sed 's/"//g')

        if [ ! -z "$alert_name" ]; then
            echo -e "${YELLOW}  - Alert: $alert_name${NC}"
            log_message "ALERT: $alert_name is firing"
        fi
    done
}

display_summary() {
    echo ""
    echo "========================================="
    echo "Alert Dispatcher Summary"
    echo "========================================="
    echo "Prometheus URL: $PROMETHEUS_URL"
    echo "Log File: $LOG_FILE"
    echo "Check Interval: ${CHECK_INTERVAL}s"
    echo "========================================="
    echo ""
}

main() {
    display_summary
    log_message "INFO: Alert dispatcher started"

    if [ "$1" == "--once" ]; then
        alerts=$(fetch_alerts)
        process_alerts "$alerts"
        exit 0
    fi

    echo "Starting continuous monitoring (press Ctrl+C to stop)..."
    echo ""

    while true; do
        alerts=$(fetch_alerts)

        if [ $? -eq 0 ]; then
            process_alerts "$alerts"
        fi

        echo "Sleeping for ${CHECK_INTERVAL} seconds..."
        echo ""
        sleep "$CHECK_INTERVAL"
    done
}

trap 'log_message "INFO: Alert dispatcher stopped"; exit 0' SIGINT SIGTERM

main "$@"
