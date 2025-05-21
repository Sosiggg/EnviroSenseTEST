const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');

// Create Express app
const app = express();

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  credentials: true
}));

// Add logging middleware
app.use(morgan('combined'));

// Add a health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'CORS proxy is running' });
});

// Configure proxy middleware
const apiProxy = createProxyMiddleware({
  target: 'https://envirosense-2khv.onrender.com',
  changeOrigin: true,
  pathRewrite: {
    '^/api': '/api/v1' // Rewrite path
  },
  onProxyReq: (proxyReq, req, res) => {
    // Log proxy requests
    console.log(`Proxying ${req.method} request to: ${proxyReq.path}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    // Add CORS headers to the response
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS, PATCH';
    proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept, Origin, X-Requested-With';
    proxyRes.headers['Access-Control-Allow-Credentials'] = 'true';
    
    // Log response status
    console.log(`Proxy response status: ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    // Handle proxy errors
    console.error('Proxy error:', err);
    res.writeHead(500, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, Origin, X-Requested-With',
      'Access-Control-Allow-Credentials': 'true'
    });
    res.end(JSON.stringify({ error: 'Proxy error', message: err.message }));
  }
});

// Use the proxy middleware for all API requests
app.use('/api', apiProxy);

// Handle OPTIONS requests explicitly
app.options('*', cors({
  origin: '*',
  methods: ['GET', 'POST', PUT, 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  credentials: true
}));

// Start the server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`CORS proxy server running on port ${PORT}`);
});
