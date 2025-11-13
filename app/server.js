const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = 3000;

// Create a Registry to register the metrics
const register = new client.Registry();

// Add default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in milliseconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [50, 100, 200, 300, 400, 500, 1000, 2000, 5000]
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const appHealthStatus = new client.Gauge({
  name: 'app_health_status',
  help: 'Application health status (1 = healthy, 0 = unhealthy)'
});

// Custom CPU usage metric (simulated)
const cpuUsageGauge = new client.Gauge({
  name: 'app_cpu_usage_percent',
  help: 'Application CPU usage percentage (simulated)'
});

// Register custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(appHealthStatus);
register.registerMetric(cpuUsageGauge);

// Simulate CPU usage that occasionally spikes above 70%
let simulatedCpuUsage = 30;
let stressTestActive = false;

setInterval(() => {
  // Skip automatic updates during stress test
  if (stressTestActive) {
    return;
  }

  // Randomly fluctuate CPU usage between 20% and 85%
  const random = Math.random();
  if (random > 0.8) {
    // 20% chance of high CPU (60-85%)
    simulatedCpuUsage = 60 + Math.random() * 25;
  } else {
    // 80% chance of normal CPU (20-50%)
    simulatedCpuUsage = 20 + Math.random() * 30;
  }
  cpuUsageGauge.set(simulatedCpuUsage);
}, 5000);

// Middleware to track request duration
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route ? req.route.path : req.path;

    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(duration);

    httpRequestTotal
      .labels(req.method, route, res.statusCode.toString())
      .inc();
  });

  next();
});

// Routes
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Demo monitoring application is running',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  const isHealthy = Math.random() > 0.1; // 90% chance of being healthy

  if (isHealthy) {
    appHealthStatus.set(1);
    res.status(200).json({ status: 'healthy' });
  } else {
    appHealthStatus.set(0);
    res.status(503).json({ status: 'unhealthy' });
  }
});

// Endpoint to simulate high CPU load
app.get('/stress', (req, res) => {
  stressTestActive = true;
  cpuUsageGauge.set(85);

  setTimeout(() => {
    stressTestActive = false;
    cpuUsageGauge.set(30);
  }, 60000); // Reset after 60 seconds

  res.json({ message: 'CPU stress simulated for 60 seconds at 85%' });
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Start server
app.listen(PORT, () => {
  console.log(`Demo app listening on port ${PORT}`);
  console.log(`Metrics available at http://localhost:${PORT}/metrics`);

  // Set initial health status
  appHealthStatus.set(1);
  cpuUsageGauge.set(simulatedCpuUsage);
});
