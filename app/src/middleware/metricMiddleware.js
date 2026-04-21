const { httpRequestsTotal, httpRequestDuration, activeConnections } = require('../metrics');

const metricsMiddleware = (req, res, next) => {
    // catat waktu mulai
    const start = Date.now();

    // Increment active connections
    activeConnections.inc();

    const originalEnd = res.end;
    res.end = function (...args) {
        // catat waktu selesai
        const duration = (Date.now() - start) / 1000; // durasi dalam detik
        const route = req.route ? req.route.path : req.path;
        const labels = {
            method: req.method,
            route: route,
            status_code: res.statusCode
        };

        // record metrics
        httpRequestsTotal.inc(labels);
        httpRequestDuration.observe(labels, duration);
        
        // Decrement active connections
        activeConnections.dec();

        originalEnd.apply(this, args);
    };

    next();
};

module.exports = metricsMiddleware;