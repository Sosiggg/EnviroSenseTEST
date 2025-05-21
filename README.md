# EnviroSense - Environmental Monitoring System

EnviroSense is a comprehensive environmental monitoring system that collects temperature, humidity, and obstacle detection data using ESP32 devices and displays it in real-time through both web and mobile applications.

![EnviroSense Logo](https://via.placeholder.com/800x400?text=EnviroSense)

## Project Overview

EnviroSense consists of four main components:

1. **ESP32 Hardware** - Collects environmental data using sensors
2. **FastAPI Backend** - Processes and stores sensor data
3. **Flutter Mobile App** - Displays real-time data on mobile devices
4. **React Web Dashboard** - Provides a web interface for monitoring

## Repository Structure

```
EnviroSense/
├── backend/                # FastAPI backend server
├── mobile/                 # Flutter mobile application
├── web/                    # React web dashboard
├── EnviroSensors/          # ESP32 Arduino code
└── docs/                   # Documentation files
```

## Components

### 1. ESP32 Hardware (EnviroSensors/)

The hardware component uses an ESP32 microcontroller with the following sensors:
- DHT22 temperature and humidity sensor (connected to pin 13)
- IR obstacle detection sensor (connected to pin 15)

The ESP32 connects to the backend via WebSocket and sends sensor data in real-time.

**Key Files:**
- `EnviroSensors.ino` - Main Arduino sketch with JWT authentication
- `EnviroSensors_Email_Auth.ino` - Version using email-based authentication
- `EnviroSensors_Email_Auth_Updated.ino` - Updated version with improved reliability

### 2. FastAPI Backend (backend/)

A Python-based backend built with FastAPI that handles:
- User authentication with JWT tokens
- WebSocket connections for real-time data
- RESTful API endpoints for data retrieval
- PostgreSQL database integration

**Key Features:**
- Secure authentication system
- Email functionality for sending tokens
- Data storage and retrieval
- WebSocket server for real-time communication

### 3. Flutter Mobile App (mobile/)

A cross-platform mobile application built with Flutter that provides:
- User authentication
- Real-time sensor data visualization
- Historical data viewing
- User profile management
- Team information

**Key Features:**
- Clean architecture with BLoC pattern
- WebSocket connection for real-time updates
- Responsive design for various device sizes
- Dark and light theme support

### 4. React Web Dashboard (web/)

A responsive web application built with React that offers:
- Real-time monitoring dashboard
- Historical data analysis
- User authentication
- Responsive design

**Key Features:**
- Material-UI components
- Chart.js for data visualization
- JWT authentication
- Responsive layout for all screen sizes

## Deployment

- **Backend**: Deployed on [Render](https://envirosense-2khv.onrender.com)
- **Web Dashboard**: Deployed on [Netlify](https://envirosense.netlify.app)
- **Mobile App**: Available as APK for Android devices

## Getting Started

### Prerequisites

- Node.js and npm for web development
- Flutter SDK for mobile development
- Python 3.10+ for backend development
- Arduino IDE for ESP32 programming

### Setup Instructions

1. **Backend Setup**:
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

2. **Web Dashboard Setup**:
   ```bash
   cd web
   npm install
   npm start
   ```

3. **Mobile App Setup**:
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

4. **ESP32 Setup**:
   - Open the Arduino IDE
   - Load the appropriate sketch from the EnviroSensors directory
   - Update WiFi credentials and authentication details
   - Upload to your ESP32 device

## Documentation

- Backend API documentation: Available at `/docs` endpoint when running the backend
- Mobile app architecture: See `mobile/README.md`
- Web dashboard: See `web/README.md`
- ESP32 setup: See comments in the Arduino sketches

## Team

- **Salas**: Team Lead & Backend Developer
- **Nacalaban**: Frontend Developer
- **Paigna**: IoT Specialist
- **Olandria**: Data Analyst

## License

This project is licensed under the MIT License - see the LICENSE file for details.
