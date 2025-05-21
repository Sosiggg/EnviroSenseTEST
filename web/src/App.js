import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { CssBaseline } from '@mui/material';

// Import fonts
import '@fontsource/poppins/300.css';
import '@fontsource/poppins/400.css';
import '@fontsource/poppins/500.css';
import '@fontsource/poppins/600.css';
import '@fontsource/poppins/700.css';
import '@fontsource/inter/400.css';
import '@fontsource/inter/500.css';
import '@fontsource/inter/600.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';

// Context providers
import { AuthProvider } from './context/AuthContext';
import { SensorProvider } from './context/SensorContext';
import { ThemeProvider } from './context/ThemeContext';

// Components
import PrivateRoute from './components/PrivateRoute';

// Pages
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Profile from './pages/Profile';
import Team from './pages/Team';



function App() {
  return (
    <ThemeProvider>
      <CssBaseline />
      <AuthProvider>
        <SensorProvider>
          <Router>
            <Routes>
              {/* Public routes */}
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />

              {/* Protected routes */}
              <Route element={<PrivateRoute />}>
                <Route path="/" element={<Dashboard />} />
                <Route path="/profile" element={<Profile />} />
                <Route path="/team" element={<Team />} />
              </Route>

              {/* Redirect to dashboard for any unknown routes */}
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </Router>
        </SensorProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
