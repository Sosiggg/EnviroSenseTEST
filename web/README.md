# EnviroSense Web Dashboard

A modern, responsive web dashboard for the EnviroSense environmental monitoring system. Built with React, Material-UI, and Chart.js.

[![Netlify Status](https://api.netlify.com/api/v1/badges/your-netlify-badge-id/deploy-status)](https://app.netlify.com/sites/envirosense/deploys)

## Features

- **Real-time Sensor Data**: View temperature, humidity, and obstacle detection data in real-time
- **Historical Data**: Browse and filter historical sensor readings
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Dark Mode**: Toggle between light and dark themes
- **Secure Authentication**: JWT-based authentication system
- **User Profile Management**: Update profile information and change password

## Technologies Used

- **React**: Frontend library for building user interfaces
- **Material-UI**: React component library implementing Google's Material Design
- **Chart.js**: JavaScript charting library for data visualization
- **Axios**: Promise-based HTTP client for API requests
- **React Router**: Declarative routing for React applications
- **JWT Decode**: Library for decoding JWT tokens
- **Date-fns**: Modern JavaScript date utility library

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/envirosense.git
   cd envirosense/web
   ```

2. Install dependencies:
   ```bash
   npm install
   # or
   yarn install
   ```

3. Create a `.env.local` file in the web directory with the following content:
   ```
   REACT_APP_API_URL=https://envirosense-2khv.onrender.com/api/v1
   # For local development with backend running locally:
   # REACT_APP_API_URL=http://localhost:8000/api/v1
   ```

4. Start the development server:
   ```bash
   npm start
   # or
   yarn start
   ```

5. Open [http://localhost:3000](http://localhost:3000) to view the app in your browser.

### Building for Production

```bash
npm run build
# or
yarn build
```

The build artifacts will be stored in the `build/` directory.

## Deployment

This project is configured for easy deployment to Netlify:

1. Connect your GitHub repository to Netlify
2. Set the build command to `npm run build`
3. Set the publish directory to `web/build`
4. Add the following environment variables in Netlify:
   - `REACT_APP_API_URL`: Your backend API URL

## Environment Variables

- `REACT_APP_API_URL`: URL of the backend API
- `REACT_APP_ENV`: Environment (development, production)

## Available Scripts

- `npm start`: Runs the app in development mode
- `npm test`: Launches the test runner
- `npm run build`: Builds the app for production
- `npm run eject`: Ejects from Create React App

## Acknowledgments

- EnviroSense Team: Salas, Nacalaban, Paigna, and Olandria
- This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app)
