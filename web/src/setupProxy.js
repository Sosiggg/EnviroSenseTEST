const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  // Proxy for local backend
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'http://localhost:8000',
      changeOrigin: true,
      pathRewrite: {
        '^/api': '/api/v1', // rewrite path
      },
      onProxyReq: (proxyReq, req, res) => {
        // Log proxy requests
        console.log('Proxying request:', req.method, req.path);
      },
      onError: (err, req, res) => {
        console.error('Proxy error:', err);

        // Try to fallback to production API
        console.log('Attempting fallback to production API...');

        // Create a new proxy middleware for the production API
        const productionProxy = createProxyMiddleware({
          target: 'https://envirosense-2khv.onrender.com',
          changeOrigin: true,
          pathRewrite: {
            '^/api': '/api/v1',
          },
          onProxyReq: (proxyReq, req, res) => {
            console.log('Proxying request to production API:', req.method, req.path);
          },
        });

        // Try the production proxy
        try {
          return productionProxy(req, res);
        } catch (fallbackErr) {
          console.error('Production API fallback failed:', fallbackErr);
          res.writeHead(500, {
            'Content-Type': 'text/plain',
          });
          res.end('Proxy error: Could not connect to any API server. Please try again later.');
        }
      },
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    })
  );

  // Proxy for production backend (fallback)
  app.use(
    '/prod-api',
    createProxyMiddleware({
      target: 'https://envirosense-2khv.onrender.com',
      changeOrigin: true,
      pathRewrite: {
        '^/prod-api': '/api/v1',
      },
      onProxyReq: (proxyReq, req, res) => {
        console.log('Proxying request to production API:', req.method, req.path);
      },
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    })
  );
};
