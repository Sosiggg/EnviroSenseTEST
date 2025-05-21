import React, { useState } from 'react';
import {
  Container,
  Box,
  Typography,
  TextField,
  Button,
  Paper,
  Link,
  Alert,
  CircularProgress,
  useTheme,
  alpha,
  InputAdornment,
  IconButton,
  Divider,
  Card,
  CardContent
} from '@mui/material';
import {
  Person as PersonIcon,
  Lock as LockIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Login as LoginIcon,
  ThermostatAuto as ThermostatIcon,
  OpacityOutlined as OpacityIcon
} from '@mui/icons-material';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Login = () => {
  const { login, error, loading } = useAuth();
  const navigate = useNavigate(); const theme = useTheme();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [formError, setFormError] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validate form
    if (!username.trim() || !password.trim()) {
      setFormError('Please enter both username and password');
      return;
    }

    setFormError('');

    try {
      await login(username, password);
      navigate('/');
    } catch (error) {
      console.error('Login error:', error);

      // Display the user-friendly error message
      setFormError(error.message || 'An error occurred during login. Please try again later.');
    }
  };

  const handleTogglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: `linear-gradient(135deg, ${alpha(theme.palette.primary.light, 0.2)} 0%, ${alpha(theme.palette.primary.main, 0.1)} 100%)`,
        py: 4
      }}
    >
      <Container maxWidth="md">
        <Card
          elevation={6}
          sx={{
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            overflow: 'hidden',
            borderRadius: 4,
            boxShadow: '0 8px 40px rgba(0, 0, 0, 0.12)'
          }}
        >
          {/* Left side - Brand/Logo */}
          <Box
            sx={{
              flex: { md: '1 0 45%' },
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              p: 6,
              color: 'white',
              background: `linear-gradient(135deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 100%)`,
              position: 'relative',
              overflow: 'hidden'
            }}
          >
            <Box
              sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                opacity: 0.1,
                backgroundImage: 'url("data:image/svg+xml,%3Csvg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"%3E%3Cpath d="M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z" fill="%23ffffff" fill-opacity="1" fill-rule="evenodd"/%3E%3C/svg%3E")',
              }}
            />

            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                mb: 4
              }}
            >
              <Typography
                variant="h3"
                component="h1"
                sx={{
                  fontWeight: 'bold',
                  letterSpacing: '0.5px'
                }}
              >
                EnviroSense
              </Typography>
            </Box>

            <Typography
              variant="h6"
              sx={{
                mb: 4,
                textAlign: 'center',
                fontWeight: 'normal',
                opacity: 0.9
              }}
            >
              Environmental Monitoring System
            </Typography>

            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 2,
                mb: 4
              }}
            >
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1.5
                }}
              >
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 40,
                    height: 40,
                    borderRadius: '50%',
                    bgcolor: 'rgba(255, 255, 255, 0.2)',
                  }}
                >
                  <ThermostatIcon fontSize="small" />
                </Box>
                <Typography variant="body1">
                  Real-time temperature monitoring
                </Typography>
              </Box>

              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1.5
                }}
              >
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 40,
                    height: 40,
                    borderRadius: '50%',
                    bgcolor: 'rgba(255, 255, 255, 0.2)',
                  }}
                >
                  <OpacityIcon fontSize="small" />
                </Box>
                <Typography variant="body1">
                  Humidity and obstacle detection
                </Typography>
              </Box>
            </Box>

            <Typography
              variant="body2"
              sx={{
                textAlign: 'center',
                opacity: 0.7,
                mt: 'auto'
              }}
            >
              © 2025 EnviroSense Team
            </Typography>
          </Box>

          {/* Right side - Login Form */}
          <Box
            sx={{
              flex: { md: '1 0 55%' },
              p: { xs: 4, sm: 6 },
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center',
            }}
          >
            <Typography
              variant="h4"
              component="h2"
              sx={{
                mb: 1,
                fontWeight: 'bold',
                color: 'text.primary'
              }}
            >
              Welcome Back
            </Typography>

            <Typography
              variant="body1"
              color="text.secondary"
              sx={{ mb: 4 }}
            >
              Sign in to access your EnviroSense dashboard
            </Typography>

            {(error || formError) && (
              <Alert
                severity="error"
                sx={{
                  width: '100%',
                  mb: 3,
                  borderRadius: 2
                }}
              >
                {formError || error}
              </Alert>
            )}

            <Box
              component="form"
              onSubmit={handleSubmit}
              sx={{ width: '100%' }}
            >
              <TextField
                margin="normal"
                required
                fullWidth
                id="username"
                label="Username"
                name="username"
                autoComplete="username"
                autoFocus
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                disabled={loading}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PersonIcon color="action" />
                    </InputAdornment>
                  ),
                }}
                sx={{
                  mb: 2,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 2,
                  }
                }}
              />

              <TextField
                margin="normal"
                required
                fullWidth
                name="password"
                label="Password"
                type={showPassword ? 'text' : 'password'}
                id="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <LockIcon color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle password visibility"
                        onClick={handleTogglePasswordVisibility}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                      </IconButton>
                    </InputAdornment>
                  )
                }}
                sx={{
                  mb: 3,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 2,
                  }
                }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading}
                startIcon={loading ? null : <LoginIcon />}
                sx={{
                  mt: 1,
                  mb: 3,
                  py: 1.5,
                  borderRadius: 2,
                  boxShadow: '0 4px 12px rgba(0, 120, 215, 0.2)',
                  '&:hover': {
                    boxShadow: '0 6px 16px rgba(0, 120, 215, 0.3)',
                  }
                }}
              >
                {loading ? <CircularProgress size={24} /> : 'Sign In'}
              </Button>

              <Divider sx={{ my: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  OR
                </Typography>
              </Divider>

              <Box sx={{ textAlign: 'center', mt: 2 }}>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  Don't have an account?
                </Typography>
                <Link
                  component={RouterLink}
                  to="/register"
                  variant="body1"
                  sx={{
                    fontWeight: 'medium',
                    color: 'primary.main',
                    textDecoration: 'none',
                    '&:hover': {
                      textDecoration: 'underline'
                    }
                  }}
                >
                  Create an account
                </Link>
              </Box>
            </Box>
          </Box>
        </Card>
      </Container>
    </Box>
  );
};

export default Login;
