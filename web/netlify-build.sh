#!/bin/bash

# Netlify build script for EnviroSense web app

echo "Starting Netlify build process for EnviroSense web app..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the app
echo "Building the app..."
npm run build

# Copy _redirects to build folder (in case it wasn't copied during build)
echo "Ensuring _redirects file is in build folder..."
if [ -f "public/_redirects" ]; then
  cp public/_redirects build/
fi

echo "Build completed successfully!"
