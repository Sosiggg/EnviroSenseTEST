import api from '../utils/api';
import { jwtDecode } from 'jwt-decode';

// Login user
export const login = async (username, password) => {
  try {
    // Create form data for login
    const formData = new FormData();
    formData.append('username', username);
    formData.append('password', password);

    // Make login request
    const response = await api.post('/auth/token', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    // Get token from response
    const { access_token } = response.data;

    // Store token in local storage
    localStorage.setItem('token', access_token);

    // Get user info
    const userInfo = await getUserInfo();

    return userInfo;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
};

// Register user
export const register = async (username, email, password) => {
  try {
    const response = await api.post('/auth/register', {
      username,
      email,
      password,
    });

    return response.data;
  } catch (error) {
    console.error('Registration error:', error);
    throw error;
  }
};

// Get user info
export const getUserInfo = async () => {
  try {
    const response = await api.get('/auth/me');
    
    // Store user info in local storage
    localStorage.setItem('user', JSON.stringify(response.data));
    
    return response.data;
  } catch (error) {
    console.error('Get user info error:', error);
    throw error;
  }
};

// Logout user
export const logout = () => {
  // Remove token and user info from local storage
  localStorage.removeItem('token');
  localStorage.removeItem('user');
};

// Check if user is authenticated
export const isAuthenticated = () => {
  const token = localStorage.getItem('token');
  
  if (!token) {
    return false;
  }
  
  try {
    // Decode token to check expiration
    const decoded = jwtDecode(token);
    const currentTime = Date.now() / 1000;
    
    // Check if token is expired
    if (decoded.exp < currentTime) {
      // Token is expired, remove from local storage
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Token validation error:', error);
    return false;
  }
};

// Get current user
export const getCurrentUser = () => {
  const userJson = localStorage.getItem('user');
  
  if (!userJson) {
    return null;
  }
  
  try {
    return JSON.parse(userJson);
  } catch (error) {
    console.error('Error parsing user JSON:', error);
    return null;
  }
};
