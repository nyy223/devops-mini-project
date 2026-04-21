// src/index.js
const express = require('express');
const { register } = require('./metrics');
const metricsMiddleware = require('./middleware/metricsMiddleware');

// Import routes
const healthRoutes = require('./routes/health');
const userRoutes = require('./routes/users');
const productRoutes = require('./routes/products');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(metricsMiddleware); // auto-track semua request

// Routes
app.use(healthRoutes);
app.use(userRoutes);
app.use(productRoutes);

// Metrics endpoint — WAJIB untuk Prometheus scraping
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`App running on port ${PORT}`);
  console.log(`Metrics available at http://localhost:${PORT}/metrics`);
});

module.exports = app;