const client = require('prom-client');

// buat registry default
const register = new client.Registry();

// default metric (cpu, memory, dll)
client.collectDefaultMetrics({ register });

// custom metric 1: counter untuk total request
const httpRequestsTotal = new client.Counter({
    name: 'http_request_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register]
});

// custom metric 2: histogram untuk durassi request
const httpRequestDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5], // bucket untuk durasi
    registers: [register]
});

// custom metric 3: gauge untuk active connection
const activeConnections = new client.Gauge({
    name: 'active_connections',
    help: 'Number of active connections',
    registers: [register]
});

module.exports = {
    register,
    httpRequestsTotal,
    httpRequestDuration,
    activeConnections
};
