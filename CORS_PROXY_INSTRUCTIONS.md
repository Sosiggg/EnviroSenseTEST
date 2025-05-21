# EnviroSense CORS Proxy

This document provides instructions on how to set up and use the CORS proxy for the EnviroSense application.

## What is a CORS Proxy?

A CORS (Cross-Origin Resource Sharing) proxy is a server that sits between your web application and the API server. It adds the necessary CORS headers to the API responses, allowing your web application to access the API from a different domain.

## Why Do We Need a CORS Proxy?

The EnviroSense backend deployed on Render is experiencing CORS issues, which prevent the web application from accessing the API. The CORS proxy solves this problem by adding the necessary CORS headers to all API responses.

## Setting Up the CORS Proxy

### 1. Create a GitHub Repository

1. Create a new GitHub repository named `envirosense-cors-proxy`
2. Clone the repository to your local machine

### 2. Copy the CORS Proxy Files

Copy the following files from this project to your new repository:

- `cors-proxy/package.json`
- `cors-proxy/index.js`
- `cors-proxy/README.md`
- `cors-proxy/.gitignore`
- `cors-proxy/render.yaml`

### 3. Deploy to Render

1. Push the repository to GitHub
2. Create a new Web Service on Render
3. Connect your GitHub repository
4. Set the following configuration:
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Environment Variables: None required

### 4. Update the Web Application

After deploying the CORS proxy, you need to update the web application to use it:

1. Update the `REACT_APP_API_URL` in `web/.env.proxy` with your Render URL
2. Run `node update_web_for_proxy.js` to update the web application
3. Rebuild and redeploy the web application

## Using the CORS Proxy

Once the CORS proxy is set up and the web application is updated, all API requests will be routed through the proxy. You don't need to make any changes to your code.

### Testing the CORS Proxy

You can test the CORS proxy using the included `test.html` file:

1. Open `cors-proxy/test.html` in a web browser
2. Enter your proxy URL and JWT token
3. Click the test buttons to test different endpoints

## Troubleshooting

If you're still experiencing CORS issues:

1. Check the proxy logs on Render to see if there are any errors
2. Make sure the proxy URL is correct in the web application
3. Try accessing the proxy directly using the test HTML file

## Alternative Approach

If you prefer not to use a separate proxy server, you can also use a browser extension like [CORS Unblock](https://chrome.google.com/webstore/detail/cors-unblock/lfhmikememgdcahcdlaciloancbhjino) to bypass CORS restrictions during development.

## Automated Deployment

You can use the included `deploy_cors_proxy.js` script to automate the deployment process:

```bash
node deploy_cors_proxy.js
```

This script will:

1. Create a new repository for the CORS proxy
2. Copy the necessary files
3. Initialize a git repository
4. Provide instructions for manual deployment

## Conclusion

The CORS proxy is a temporary solution to the CORS issues with the EnviroSense backend. In the long term, it's better to fix the CORS configuration on the backend server. However, the proxy provides a quick and easy way to get the application working in the meantime.
