import React, { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  AppBar,
  Box,
  CssBaseline,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
  Avatar,
  Tooltip,
  alpha
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  Person as PersonIcon,
  Group as GroupIcon,
  Logout as LogoutIcon,
  Thermostat as ThermostatIcon,
  Opacity as OpacityIcon,
  DarkMode as DarkModeIcon,
  LightMode as LightModeIcon
} from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';
import { useSensor } from '../context/SensorContext';
import { useThemeContext } from '../context/ThemeContext';

const drawerWidth = 260;

const Layout = () => {
  const { user, logout } = useAuth();
  const { latestData, isConnected } = useSensor();
  const { isDarkMode, toggleTheme } = useThemeContext();
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleNavigation = (path) => {
    navigate(path);
    if (isMobile) {
      setMobileOpen(false);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  // Get user initials for avatar
  const getUserInitials = () => {
    if (!user || !user.username) return '?';
    return user.username.charAt(0).toUpperCase();
  };

  // Navigation items
  const navItems = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/' },
    { text: 'Profile', icon: <PersonIcon />, path: '/profile' },
    { text: 'Team', icon: <GroupIcon />, path: '/team' },
  ];

  // Drawer content
  const drawer = (
    <div>
      <Box
        sx={{
          p: 2,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          backgroundColor: 'primary.main',
          color: 'white',
          pb: 3
        }}
      >
        <Typography
          variant="h5"
          component="div"
          sx={{
            fontWeight: 'bold',
            letterSpacing: '0.5px',
            mb: 1
          }}
        >
          EnviroSense
        </Typography>
        <Typography variant="body2" sx={{ opacity: 0.8, mb: 3 }}>
          Environmental Monitoring
        </Typography>

        {user && (
          <Box sx={{ display: 'flex', alignItems: 'center', width: '100%', mt: 1 }}>
            <Avatar
              sx={{
                bgcolor: 'primary.light',
                color: 'white',
                width: 50,
                height: 50,
                boxShadow: '0 3px 10px rgba(0,0,0,0.2)'
              }}
            >
              {getUserInitials()}
            </Avatar>
            <Box sx={{ ml: 2 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 'medium' }}>
                {user.username}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>
                {user.email}
              </Typography>
            </Box>
          </Box>
        )}
      </Box>

      <Box sx={{ mt: 2 }}>
        <List>
          {navItems.map((item) => (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                selected={location.pathname === item.path}
                onClick={() => handleNavigation(item.path)}
                sx={{
                  borderRadius: '0 20px 20px 0',
                  mx: 1,
                  mb: 0.5,
                  '&.Mui-selected': {
                    backgroundColor: alpha(theme.palette.primary.main, 0.1),
                    color: 'primary.main',
                    '&:hover': {
                      backgroundColor: alpha(theme.palette.primary.main, 0.15),
                    },
                    '& .MuiListItemIcon-root': {
                      color: 'primary.main',
                    }
                  },
                  '&:hover': {
                    backgroundColor: alpha(theme.palette.primary.main, 0.05),
                  }
                }}
              >
                <ListItemIcon sx={{ minWidth: 45 }}>
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.text}
                  primaryTypographyProps={{
                    fontWeight: location.pathname === item.path ? 'medium' : 'normal'
                  }}
                />
                {item.text === 'Dashboard' && isConnected && (
                  <Box
                    sx={{
                      width: 8,
                      height: 8,
                      borderRadius: '50%',
                      bgcolor: 'success.main',
                      mr: 1
                    }}
                  />
                )}
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </Box>

      {latestData && (
        <Box sx={{ px: 3, py: 2 }}>
          <Typography variant="subtitle2" color="text.secondary" gutterBottom>
            Latest Readings
          </Typography>
          <Box sx={{
            bgcolor: 'background.paper',
            p: 2,
            borderRadius: 2,
            boxShadow: '0 2px 8px rgba(0,0,0,0.05)'
          }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
              <ThermostatIcon color="error" fontSize="small" sx={{ mr: 1 }} />
              <Typography variant="body2">
                {latestData.temperature.toFixed(1)}°C
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <OpacityIcon color="info" fontSize="small" sx={{ mr: 1 }} />
              <Typography variant="body2">
                {latestData.humidity.toFixed(1)}%
              </Typography>
            </Box>
          </Box>
        </Box>
      )}

      <Box sx={{ mt: 'auto' }}>
        <Divider />
        <List>
          <ListItem disablePadding>
            <ListItemButton onClick={toggleTheme}>
              <ListItemIcon>
                {isDarkMode ? <LightModeIcon /> : <DarkModeIcon />}
              </ListItemIcon>
              <ListItemText primary={isDarkMode ? "Light Mode" : "Dark Mode"} />
            </ListItemButton>
          </ListItem>
          <ListItem disablePadding>
            <ListItemButton onClick={handleLogout}>
              <ListItemIcon>
                <LogoutIcon />
              </ListItemIcon>
              <ListItemText primary="Logout" />
            </ListItemButton>
          </ListItem>
        </List>
      </Box>
    </div>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
          bgcolor: 'background.paper',
          color: 'text.primary',
          borderBottom: '1px solid',
          borderColor: 'divider',
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>

          <Typography
            variant="h6"
            component="div"
            sx={{
              flexGrow: 1,
              fontWeight: 'medium',
              display: 'flex',
              alignItems: 'center'
            }}
          >
            {navItems.find(item => item.path === location.pathname)?.text || 'EnviroSense'}
            {isConnected && (
              <Box
                sx={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  ml: 2,
                  bgcolor: 'success.light',
                  color: 'success.dark',
                  px: 1.5,
                  py: 0.5,
                  borderRadius: 10,
                  fontSize: '0.75rem',
                  fontWeight: 'medium'
                }}
              >
                <Box
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    bgcolor: 'success.main',
                    mr: 1,
                    animation: 'pulse 2s infinite'
                  }}
                />
                Live
              </Box>
            )}
          </Typography>

          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            {user && (
              <Tooltip title={`Logged in as ${user.username}`}>
                <Avatar
                  sx={{
                    bgcolor: 'primary.main',
                    cursor: 'pointer',
                    '&:hover': {
                      boxShadow: '0 0 0 2px',
                      borderColor: 'primary.light'
                    }
                  }}
                  onClick={() => navigate('/profile')}
                >
                  {getUserInitials()}
                </Avatar>
              </Tooltip>
            )}
          </Box>
        </Toolbar>
      </AppBar>

      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better open performance on mobile
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              borderRight: 'none',
              boxShadow: '4px 0 10px rgba(0,0,0,0.05)'
            },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              borderRight: 'none',
              boxShadow: '4px 0 10px rgba(0,0,0,0.05)'
            },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: { xs: 2, sm: 3, md: 4 },
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          minHeight: '100vh',
          backgroundColor: 'background.default',
          transition: 'all 0.3s ease'
        }}
      >
        <Toolbar />
        <Outlet />
      </Box>

      {/* Global styles for animations */}
      <Box
        sx={{
          '@keyframes pulse': {
            '0%': {
              opacity: 0.5,
              transform: 'scale(0.8)',
            },
            '50%': {
              opacity: 1,
              transform: 'scale(1.2)',
            },
            '100%': {
              opacity: 0.5,
              transform: 'scale(0.8)',
            },
          },
        }}
      />
    </Box>
  );
};

export default Layout;
