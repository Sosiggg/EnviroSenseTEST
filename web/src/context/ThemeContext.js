import React, { createContext, useState, useContext } from 'react';
import { ThemeProvider as MuiThemeProvider, createTheme } from '@mui/material';

// Create the theme context
const ThemeContext = createContext();

// Create light and dark themes
const createAppTheme = (mode) => {
  return createTheme({
    // Base spacing unit in pixels
    spacing: 8,

    palette: {
      mode,
      primary: {
        main: '#0078D7', // Modern blue similar to Flutter app
        light: mode === 'dark' ? '#4DA3FF' : '#4DA3FF',
        dark: mode === 'dark' ? '#0050A1' : '#0050A1',
        contrastText: '#FFFFFF',
      },
      secondary: {
        main: '#00C853', // Green for success/positive indicators
        light: mode === 'dark' ? '#5EFF82' : '#5EFF82',
        dark: mode === 'dark' ? '#009624' : '#009624',
        contrastText: '#FFFFFF',
      },
      error: {
        main: '#FF3D00', // Bright orange-red for errors
        light: '#FF7539',
        dark: '#C30000',
      },
      warning: {
        main: '#FFC107', // Amber for warnings
        light: '#FFF350',
        dark: '#C79100',
      },
      info: {
        main: '#29B6F6', // Light blue for info
        light: '#73E8FF',
        dark: '#0086C3',
      },
      success: {
        main: '#00E676', // Green for success
        light: '#66FFA6',
        dark: '#00B248',
      },
      background: {
        default: mode === 'dark' ? '#121212' : '#F5F7FA',
        paper: mode === 'dark' ? '#1E1E1E' : '#FFFFFF',
      },
      text: {
        primary: mode === 'dark' ? '#FFFFFF' : '#212121',
        secondary: mode === 'dark' ? '#B0B0B0' : '#757575',
        disabled: mode === 'dark' ? '#6E6E6E' : '#BDBDBD',
      },
    },
    typography: {
      fontFamily: [
        'Inter',
        'Roboto',
        'Arial',
        'sans-serif',
      ].join(','),
      h1: {
        fontWeight: 600,
        letterSpacing: '-0.5px',
      },
      h2: {
        fontWeight: 600,
        letterSpacing: '-0.5px',
      },
      h3: {
        fontWeight: 600,
        letterSpacing: '-0.25px',
      },
      h4: {
        fontWeight: 600,
        letterSpacing: '-0.25px',
      },
      h5: {
        fontWeight: 600,
      },
      h6: {
        fontWeight: 600,
      },
      subtitle1: {
        fontWeight: 500,
      },
      subtitle2: {
        fontWeight: 500,
      },
      body1: {
        lineHeight: 1.6,
      },
      body2: {
        lineHeight: 1.6,
      },
      button: {
        fontWeight: 500,
      },
    },
    shape: {
      borderRadius: 8,
    },
    components: {
      MuiContainer: {
        styleOverrides: {
          root: {
            paddingLeft: 16,
            paddingRight: 16,
            '@media (min-width:600px)': {
              paddingLeft: 24,
              paddingRight: 24,
            },
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            textTransform: 'none',
            borderRadius: 6,
            padding: '8px 16px',
            boxShadow: 'none',
            transition: 'all 0.2s ease-in-out',
            '&:hover': {
              boxShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
            },
          },
          contained: {
            '&:hover': {
              boxShadow: '0 3px 8px rgba(0, 120, 215, 0.2)',
            },
          },
        },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: 8,
            boxShadow: mode === 'dark'
              ? '0 2px 8px rgba(0, 0, 0, 0.3)'
              : '0 1px 4px rgba(0, 0, 0, 0.05)',
            overflow: 'hidden',
            transition: 'box-shadow 0.2s ease',
            '&:hover': {
              boxShadow: mode === 'dark'
                ? '0 3px 10px rgba(0, 0, 0, 0.4)'
                : '0 2px 8px rgba(0, 0, 0, 0.08)',
            }
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
          },
          elevation1: {
            boxShadow: mode === 'dark'
              ? '0 1px 6px rgba(0, 0, 0, 0.3)'
              : '0 1px 4px rgba(0, 0, 0, 0.05)',
          },
          elevation2: {
            boxShadow: mode === 'dark'
              ? '0 2px 8px rgba(0, 0, 0, 0.4)'
              : '0 2px 8px rgba(0, 0, 0, 0.08)',
          },
        },
      },
      MuiAppBar: {
        styleOverrides: {
          root: {
            boxShadow: mode === 'dark'
              ? '0 1px 6px rgba(0, 0, 0, 0.4)'
              : '0 1px 4px rgba(0, 0, 0, 0.05)',
          },
        },
      },
      MuiTextField: {
        styleOverrides: {
          root: {
            '& .MuiOutlinedInput-root': {
              borderRadius: 6,
              '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                borderWidth: 2,
              },
            },
          },
        },
      },
      MuiChip: {
        styleOverrides: {
          root: {
            borderRadius: 6,
            height: 28,
          },
        },
      },
      MuiAlert: {
        styleOverrides: {
          root: {
            borderRadius: 6,
          },
        },
      },
      MuiCardContent: {
        styleOverrides: {
          root: {
            padding: 16,
            '&:last-child': {
              paddingBottom: 16,
            },
            '@media (min-width:600px)': {
              padding: 20,
              '&:last-child': {
                paddingBottom: 20,
              },
            },
          },
        },
      },
      MuiIconButton: {
        styleOverrides: {
          root: {
            padding: 8,
          },
        },
      },
    },
  });
};

// Theme provider component
export const ThemeProvider = ({ children }) => {
  // Check if dark mode was previously set
  const storedMode = localStorage.getItem('themeMode');
  const [mode, setMode] = useState(storedMode === 'dark' ? 'dark' : 'light');
  const theme = createAppTheme(mode);

  // Toggle between light and dark mode
  const toggleTheme = () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    localStorage.setItem('themeMode', newMode);
  };

  // Context value
  const value = {
    mode,
    toggleTheme,
    isDarkMode: mode === 'dark',
  };

  return (
    <ThemeContext.Provider value={value}>
      <MuiThemeProvider theme={theme}>
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  );
};

// Custom hook to use theme context
export const useThemeContext = () => {
  const context = useContext(ThemeContext);

  if (!context) {
    throw new Error('useThemeContext must be used within a ThemeProvider');
  }

  return context;
};
