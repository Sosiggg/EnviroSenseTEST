import React, { createContext, useState, useEffect, useContext } from 'react';
import {
  login as loginService,
  register as registerService,
  logout as logoutService,
  isAuthenticated,
  getCurrentUser,
  updateUserProfile as updateProfileService,
  changePassword as changePasswordService
} from '../services/authService';

// Create context
const AuthContext = createContext();

// Auth provider component
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Initialize auth state
  useEffect(() => {
    const initAuth = () => {
      try {
        if (isAuthenticated()) {
          const currentUser = getCurrentUser();
          setUser(currentUser);
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        setError('Failed to initialize authentication');
      } finally {
        setLoading(false);
      }
    };

    initAuth();
  }, []);

  // Login function
  const login = async (username, password) => {
    setLoading(true);
    setError(null);

    try {
      const userData = await loginService(username, password);
      setUser(userData);
      return userData;
    } catch (error) {
      console.error('Login error:', error);

      // Set appropriate error message
      if (error.response && error.response.status === 401) {
        setError('Invalid username or password');
      } else {
        setError('Failed to login. Please try again.');
      }

      throw error;
    } finally {
      setLoading(false);
    }
  };

  // Register function
  const register = async (username, email, password) => {
    setLoading(true);
    setError(null);

    try {
      const result = await registerService(username, email, password);
      return result;
    } catch (error) {
      console.error('Registration error:', error);

      // Set appropriate error message
      if (error.response && error.response.data && error.response.data.detail) {
        setError(error.response.data.detail);
      } else {
        setError('Failed to register. Please try again.');
      }

      throw error;
    } finally {
      setLoading(false);
    }
  };

  // Logout function
  const logout = () => {
    logoutService();
    setUser(null);
  };

  // Update profile function
  const updateProfile = async (userData) => {
    setLoading(true);
    setError(null);

    try {
      const updatedUser = await updateProfileService(userData);
      setUser(updatedUser);
      return updatedUser;
    } catch (error) {
      console.error('Update profile error:', error);

      // Set appropriate error message
      if (error.response && error.response.data && error.response.data.detail) {
        setError(error.response.data.detail);
      } else {
        setError('Failed to update profile. Please try again.');
      }

      throw error;
    } finally {
      setLoading(false);
    }
  };

  // Change password function
  const changePassword = async (currentPassword, newPassword) => {
    setLoading(true);
    setError(null);

    try {
      console.log('Changing password with:', { currentPassword, newPassword });

      // Validate inputs
      if (!currentPassword || !newPassword) {
        const errorMsg = 'Current password and new password are required';
        setError(errorMsg);
        throw new Error(errorMsg);
      }

      // Call the service function
      const result = await changePasswordService(currentPassword, newPassword);
      console.log('Password change response:', result);
      return result;
    } catch (error) {
      console.error('Change password error:', error);

      // Extract error details
      let errorMessage = 'Failed to change password. Please try again.';

      if (error.message) {
        errorMessage = error.message;
      } else if (error.response?.data?.detail) {
        errorMessage = error.response.data.detail;
      }

      console.error('Error message:', errorMessage);
      setError(errorMessage);

      // Rethrow with better error message
      throw new Error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Context value
  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    updateProfile,
    changePassword,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Custom hook to use auth context
export const useAuth = () => {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  return context;
};
