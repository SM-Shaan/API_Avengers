# Observability & Monitoring Stack

A lightweight, complete observability setup using Prometheus, Grafana, and Node Exporter for monitoring a local web service in Docker.

## Features

- Real-time monitoring of CPU, memory, and response times
- Visual dashboards with Grafana
- Automated alerts for high CPU usage and application health
- Prometheus metrics collection
- Alert dispatcher script for notification simulation

## Architecture

```
┌─────────────────┐
│   Demo App      │──┐
│   (Node.js)     │  │
│   Port: 3000    │  │
└─────────────────┘  │
                     │
┌─────────────────┐  │    ┌─────────────────┐
│ Node Exporter   │──┼───▶│   Prometheus    │
│   Port: 9100    │  │    │   Port: 9090    │
└─────────────────┘  │    └────────┬────────┘
                     │             │
                     │             ▼
                     │    ┌─────────────────┐
                     └───▶│    Grafana      │
                          │   Port: 3001    │
                          └─────────────────┘
```

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone the repository)
- Bash shell (for running the alert dispatcher script)

## Quick Start

### 1. Start the Stack

```bash
docker-compose up -d
```

This will start all services:
- Demo App: http://localhost:3000
- Prometheus: http://localhost:9090
- Node Exporter: http://localhost:9100
- Grafana: http://localhost:3001

### 2. Access Grafana Dashboard

1. Open http://localhost:3001 in your browser
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
3. Navigate to Dashboards → "Demo Application Monitoring Dashboard"

### 3. View Metrics

The dashboard displays:
- **CPU Usage** - Current CPU percentage with threshold indicators
- **Application Health** - Health status (Healthy/Unhealthy)
- **Request Rate** - HTTP requests per second
- **CPU Usage Over Time** - Historical CPU trends
- **Response Time Percentiles** - P50, P95, P99 latency
- **Memory Usage** - Application memory consumption
- **Active Alerts** - Currently firing alerts

## Services & Endpoints

### Demo Application
- **URL**: http://localhost:3000
- **Endpoints**:
  - `GET /` - Basic health check
  - `GET /health` - Application health status
  - `GET /metrics` - Prometheus metrics endpoint
  - `GET /stress` - Simulate high CPU load for 30 seconds

### Prometheus
- **URL**: http://localhost:9090
- **Configuration**: `prometheus.yml`
- **Alert Rules**: `alert.rules.yml`

### Grafana
- **URL**: http://localhost:3001
- **Default Credentials**: admin/admin
- **Dashboard**: Pre-configured monitoring dashboard

### Node Exporter
- **URL**: http://localhost:9100/metrics
- **Purpose**: Collects host-level metrics (CPU, memory, disk, etc.)

## Testing Alerts

### Trigger High CPU Alert

```bash
curl http://localhost:3000/stress
```

This will simulate 85% CPU usage for 30 seconds, triggering the `HighCPUUsage` alert.

### View Alerts in Prometheus

1. Open http://localhost:9090/alerts
2. You should see alerts change state from "Inactive" → "Pending" → "Firing"

### View Alerts in Grafana

The "Active Alerts" panel in the dashboard will show firing alerts in real-time.

## Alert Dispatcher Script (Bonus)

The `alert_dispatcher.sh` script fetches active alerts from Prometheus and logs them locally.

### Usage

```bash
# Make the script executable
chmod +x alert_dispatcher.sh

# Run once and check for alerts
bash alert_dispatcher.sh --once

# Run in continuous monitoring mode (checks every 30 seconds)
bash alert_dispatcher.sh
```

### Configuration

Environment variables:
```bash
PROMETHEUS_URL=http://localhost:9090 \
LOG_FILE=./alerts.log \
CHECK_INTERVAL=30 \
bash alert_dispatcher.sh
```

### Output

Alerts are logged to `alerts.log` with timestamps:
```
[2025-01-15 10:30:45] INFO: Alert dispatcher started
[2025-01-15 10:31:15] ALERT: Found 1 active alert(s)
[2025-01-15 10:31:15] ALERT: HighCPUUsage is firing
```

## Alert Rules

### Configured Alerts

1. **HighCPUUsage**
   - Condition: CPU > 70%
   - Duration: 30 seconds
   - Severity: Warning

2. **ApplicationUnhealthy**
   - Condition: Health check failing
   - Duration: 30 seconds
   - Severity: Critical

3. **ApplicationDown**
   - Condition: App not responding to Prometheus scrapes
   - Duration: 1 minute
   - Severity: Critical

4. **HighResponseTime**
   - Condition: P95 response time > 1000ms
   - Duration: 2 minutes
   - Severity: Warning

## Metrics Collected

### Application Metrics
- `app_cpu_usage_percent` - Simulated CPU usage
- `app_health_status` - Application health (1=healthy, 0=unhealthy)
- `http_requests_total` - Total HTTP requests counter
- `http_request_duration_ms` - Request duration histogram
- `process_resident_memory_bytes` - Memory usage
- `nodejs_*` - Node.js runtime metrics

### Node Metrics (via Node Exporter)
- `node_cpu_seconds_total` - CPU usage by mode
- `node_memory_*` - Memory statistics
- `node_disk_*` - Disk I/O metrics
- `node_network_*` - Network statistics

## Project Structure

```
.
├── docker-compose.yml              # Service definitions
├── prometheus.yml                  # Prometheus configuration
├── alert.rules.yml                 # Alert rule definitions
├── grafana-dashboard.json          # Grafana dashboard export
├── alert_dispatcher.sh             # Alert notification script
├── grafana-provisioning/           # Grafana auto-provisioning
│   ├── dashboards/
│   │   └── dashboard-provider.yml
│   └── datasources/
│       └── prometheus.yml
├── app/                            # Demo application
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── README.md                       # This file
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs app
docker-compose logs prometheus
docker-compose logs grafana
```

### Grafana dashboard not showing data
1. Verify Prometheus is running: http://localhost:9090
2. Check Prometheus targets: http://localhost:9090/targets
3. Ensure all targets show "UP" status
4. Verify datasource in Grafana: Configuration → Data Sources

### Alerts not firing
1. Check Prometheus rules: http://localhost:9090/rules
2. Trigger CPU stress: `curl http://localhost:3000/stress`
3. Wait 30 seconds for alert to transition to "Firing"

## Stopping the Stack

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (resets data)
docker-compose down -v
```

## Screenshot Requirement

For submission, capture a screenshot showing:
1. Grafana dashboard with all panels displaying metrics
2. At least one alert in "Firing" state (trigger with `/stress` endpoint)
3. Include browser URL bar showing `localhost:3001`

## Next Steps

- Integrate with Alertmanager for email/Slack notifications
- Add more application endpoints and metrics
- Create custom dashboards for specific use cases
- Implement distributed tracing with Jaeger
- Add log aggregation with Loki

## License

MIT License - Feel free to use and modify for your projects.
