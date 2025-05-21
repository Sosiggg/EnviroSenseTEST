# EnviroSense CORS Proxy

A simple CORS proxy server for the EnviroSense API.

## Description

This proxy server handles CORS (Cross-Origin Resource Sharing) issues by adding the necessary headers to all responses from the EnviroSense API.

## Installation

```bash
npm install
```

## Usage

```bash
npm start
```

The server will start on port 3001 by default. You can change the port by setting the `PORT` environment variable.

## API

All requests to the EnviroSense API should be made through this proxy server. For example:

- Original API endpoint: `https://envirosense-2khv.onrender.com/api/v1/auth/me`
- Proxy endpoint: `http://localhost:3001/api/auth/me`

The proxy server will automatically add the necessary CORS headers to all responses.

## Deployment

This proxy server can be deployed to services like Render or Netlify. Simply push this code to a GitHub repository and connect it to your preferred deployment service.

### Render Deployment

1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Set the following configuration:
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Environment Variables: None required

## License

MIT
