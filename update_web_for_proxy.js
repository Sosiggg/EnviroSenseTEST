const fs = require('fs');
const path = require('path');

// Copy the proxy environment file to the production environment file
console.log('Updating web application to use CORS proxy...');

// Read the proxy environment file
const proxyEnvContent = fs.readFileSync(path.join(__dirname, 'web', '.env.proxy'), 'utf8');

// Write the content to the production environment file
fs.writeFileSync(path.join(__dirname, 'web', '.env.production'), proxyEnvContent);

// Update the development environment file as well
fs.writeFileSync(path.join(__dirname, 'web', '.env.development'), proxyEnvContent);

console.log('Web application updated to use CORS proxy.');
console.log('You will need to rebuild and redeploy the web application for the changes to take effect.');
