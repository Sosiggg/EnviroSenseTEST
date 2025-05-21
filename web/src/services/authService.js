import api from '../utils/api';
import { jwtDecode } from 'jwt-decode';

// Login user
export const login = async (username, password) => {
  try {
    console.log('Attempting login for user:', username);

    // Create URLSearchParams for proper form encoding
    const params = new URLSearchParams();
    params.append('username', username);
    params.append('password', password);

    // Try using fetch API as a fallback if there are CORS issues with axios
    let response;
    try {
      // First attempt with axios
      console.log('Attempting login with axios...');
      response = await api.post('/auth/token', params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
        },
        // Disable withCredentials for this specific request
        withCredentials: false,
        // Increase timeout for this specific request
        timeout: 90000, // 90 seconds
      });
    } catch (axiosError) {
      console.warn('Axios login attempt failed:', axiosError.message);

      // If axios fails with CORS or timeout, try native fetch as fallback
      if (axiosError.message === 'Network Error' || axiosError.code === 'ECONNABORTED') {
        console.log('Attempting login with fetch API as fallback...');

        // Determine the full URL
        const baseUrl = process.env.REACT_APP_API_URL || 'https://envirosense-2khv.onrender.com/api/v1';
        const url = `${baseUrl}/auth/token`;

        const fetchResponse = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': '*/*',
          },
          body: params,
        });

        if (!fetchResponse.ok) {
          throw new Error(`Fetch failed with status: ${fetchResponse.status}`);
        }

        response = { data: await fetchResponse.json(), status: fetchResponse.status };
        console.log('Fetch login successful:', response.status);
      } else {
        // If it's not a CORS or timeout issue, rethrow the original error
        throw axiosError;
      }
    }

    console.log('Login response:', response.status);

    // Get token from response
    const { access_token } = response.data;

    // Store token in local storage
    localStorage.setItem('token', access_token);

    // Get user info
    const userInfo = await getUserInfo();

    return userInfo;
  } catch (error) {
    console.error('Login error:', error);

    // Provide more detailed error information
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      console.error('Error response data:', error.response.data);
      console.error('Error response status:', error.response.status);
      console.error('Error response headers:', error.response.headers);
    } else if (error.request) {
      // The request was made but no response was received
      console.error('Error request:', error.request);
    } else {
      // Something happened in setting up the request that triggered an Error
      console.error('Error message:', error.message);
    }

    // Add user-friendly error message
    let userMessage = 'Login failed. Please try again later.';

    if (error.code === 'ECONNABORTED') {
      userMessage = 'Connection timed out. The server might be down or overloaded.';
    } else if (error.message === 'Network Error') {
      userMessage = 'Network error. Please check your internet connection or try again later.';
    } else if (error.response && error.response.status === 401) {
      userMessage = 'Invalid username or password.';
    } else if (error.response && error.response.status === 500) {
      userMessage = 'Server error. Please try again later.';
    }

    // Create a new error with the user-friendly message
    const enhancedError = new Error(userMessage);
    enhancedError.originalError = error;
    throw enhancedError;
  }
};

// Register user
export const register = async (username, email, password) => {
  try {
    console.log('Attempting to register user:', { username, email });

    // Add retry logic for registration
    let attempts = 0;
    const maxAttempts = 3;
    let lastError = null;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        console.log(`Registration attempt ${attempts}/${maxAttempts}`);

        const response = await api.post('/auth/register', {
          username,
          email,
          password,
        });

        console.log('Registration successful:', response.status);
        return response.data;
      } catch (attemptError) {
        console.error(`Registration attempt ${attempts} failed:`, attemptError.message);
        lastError = attemptError;

        // Only retry on network errors or 500 errors
        if (attemptError.message !== 'Network Error' &&
            !(attemptError.response && attemptError.response.status >= 500)) {
          throw attemptError; // Don't retry on client errors
        }

        // Wait before retrying
        if (attempts < maxAttempts) {
          const delay = 1000 * attempts; // Increasing delay
          console.log(`Retrying in ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    // If we get here, all attempts failed
    throw lastError || new Error('Registration failed after multiple attempts');
  } catch (error) {
    console.error('Registration error:', error);

    // Enhance error message for better user feedback
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      if (error.response.status === 400) {
        if (error.response.data.detail?.includes('Username already registered')) {
          error.message = 'This username is already taken. Please choose another one.';
        } else if (error.response.data.detail?.includes('Email already registered')) {
          error.message = 'This email is already registered. Please use another email or try logging in.';
        } else {
          error.message = error.response.data.detail || 'Invalid registration data. Please check your information.';
        }
      } else if (error.response.status === 500) {
        error.message = 'Server error during registration. Please try again later.';
      }
    }

    throw error;
  }
};

// Get user info
export const getUserInfo = async () => {
  try {
    console.log('Fetching user info...');

    // Try using axios first
    let response;
    try {
      response = await api.get('/auth/me');
    } catch (axiosError) {
      console.warn('Axios getUserInfo attempt failed:', axiosError.message);

      // If axios fails with CORS or timeout, try native fetch as fallback
      if (axiosError.message === 'Network Error' || axiosError.code === 'ECONNABORTED') {
        console.log('Attempting getUserInfo with fetch API as fallback...');

        // Get token from local storage
        const token = localStorage.getItem('token');
        if (!token) {
          throw new Error('No authentication token found');
        }

        // Determine the full URL
        const baseUrl = process.env.REACT_APP_API_URL || 'https://envirosense-2khv.onrender.com/api/v1';
        const url = `${baseUrl}/auth/me`;

        const fetchResponse = await fetch(url, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Accept': '*/*',
            'Authorization': `Bearer ${token}`
          }
        });

        if (!fetchResponse.ok) {
          throw new Error(`Fetch failed with status: ${fetchResponse.status}`);
        }

        response = { data: await fetchResponse.json() };
        console.log('Fetch getUserInfo successful');
      } else {
        // If it's not a CORS or timeout issue, rethrow the original error
        throw axiosError;
      }
    }

    // Store user info in local storage
    localStorage.setItem('user', JSON.stringify(response.data));

    return response.data;
  } catch (error) {
    console.error('Get user info error:', error);

    // Provide more detailed error information
    if (error.response) {
      console.error('Error response data:', error.response.data);
      console.error('Error response status:', error.response.status);
    } else if (error.request) {
      console.error('Error request:', error.request);
    }

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

// Update user profile
export const updateUserProfile = async (userData) => {
  try {
    const response = await api.put('/auth/me', userData);

    // Update user info in local storage
    localStorage.setItem('user', JSON.stringify(response.data));

    return response.data;
  } catch (error) {
    console.error('Update user profile error:', error);
    throw error;
  }
};

// Change password
export const changePassword = async (currentPassword, newPassword) => {
  try {
    console.log('Attempting to change password via service');

    // Validate inputs
    if (!currentPassword || !newPassword) {
      throw new Error('Current password and new password are required');
    }

    // Make the API request
    const response = await api.post('/auth/change-password', {
      current_password: currentPassword,
      new_password: newPassword,
    });

    console.log('Password change service response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Change password service error:', error);

    // Enhance error message
    if (error.response) {
      console.error('Error response data:', error.response.data);
      console.error('Error response status:', error.response.status);

      // Handle specific error cases
      if (error.response.status === 400) {
        throw new Error(error.response.data.detail || 'Incorrect current password');
      } else if (error.response.status === 401) {
        throw new Error('Authentication failed. Please log in again.');
      }
    }

    throw error;
  }
};
