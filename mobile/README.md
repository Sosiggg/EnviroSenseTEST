# EnviroSense Mobile App

A Flutter mobile application for the EnviroSense environmental monitoring system.

## Features

- **Authentication**:
  - Login with username and password
  - Registration for new users
  - Forgot password functionality
  - JWT token management

- **Dashboard**:
  - Real-time sensor data display
  - Temperature and humidity charts
  - Obstacle detection status

- **Profile Management**:
  - View and edit user profile
  - Change password

- **Team Information**:
  - Meet the developers behind EnviroSense

- **Theme Support**:
  - Light and dark theme options
  - Theme persistence

## Architecture

The app follows a clean architecture approach with the following layers:

- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and entities
- **Data Layer**: Data sources and repositories

## State Management

The app uses BLoC (Business Logic Component) pattern for state management, with the following components:

- **AuthBloc**: Handles authentication-related state
- **SensorBloc**: Manages sensor data and WebSocket connections

## Backend Integration

The app connects to a FastAPI backend with the following features:

- REST API endpoints for authentication and data retrieval
- WebSocket connection for real-time sensor data updates
- JWT authentication for secure API access

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- An Android or iOS device/emulator

### Installation

1. Clone the repository
2. Navigate to the mobile directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Backend Configuration

The app is configured to connect to the EnviroSense backend at:

- Local development: `http://10.0.2.2:8000/api/v1`
- Production: `https://envirosense-2khv.onrender.com/api/v1`

To change these settings, modify the `ApiConstants` class in `lib/core/constants/api_constants.dart`.

## Team

- **Salas**: Team Lead & Backend Developer
- **Nacalaban**: Frontend Developer
- **Paigna**: IoT Specialist
- **Olandria**: Data Analyst
