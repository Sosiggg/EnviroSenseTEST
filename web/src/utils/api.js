import axios from 'axios';
import { executeWithRetry, apiCache, createCacheKey, isCircuitBreakerOpen, resetCircuitBreaker } from './networkUtils';

// Get API URL from environment variables or use default
const API_URL = process.env.REACT_APP_API_URL || 'https://envirosense-2khv.onrender.com/api/v1';

// For development, log the API URL being used
console.log('API URL:', API_URL);

// Create axios instance with default config
const api = axios.create({
  baseURL: API_URL,
  timeout: 60000, // Increased to 60 seconds timeout
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Access-Control-Allow-Origin': '*', // Request CORS headers
  },
  // Disable withCredentials for CORS
  withCredentials: false,
});

// Add cache control to the API
api.cache = {
  /**
   * Make a GET request with caching
   * @param {string} url - URL to fetch
   * @param {Object} config - Axios config
   * @param {number} maxAge - Maximum cache age in milliseconds
   * @returns {Promise<any>} Response data
   */
  async get(url, config = {}, maxAge = 60 * 1000) { // Default 1 minute
    const cacheKey = createCacheKey(url, config.params);
    const cachedData = apiCache.get(cacheKey, maxAge);

    if (cachedData) {
      console.log(`Cache hit for ${cacheKey}`);
      return cachedData;
    }

    console.log(`Cache miss for ${cacheKey}, fetching...`);
    const response = await api.get(url, config);
    apiCache.set(cacheKey, response.data);
    return response.data;
  },

  /**
   * Clear the cache
   * @param {string} urlPrefix - Optional URL prefix to clear only matching items
   */
  clear(urlPrefix) {
    apiCache.clear(urlPrefix);
  }
};

// Add a request interceptor to add the auth token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add a response interceptor to handle common errors
api.interceptors.response.use(
  (response) => {
    // Reset circuit breaker on successful response
    if (isCircuitBreakerOpen()) {
      resetCircuitBreaker();
    }
    return response;
  },
  (error) => {
    console.log('API Error:', error.message);

    // Handle 401 Unauthorized errors (token expired)
    if (error.response && error.response.status === 401) {
      // Clear local storage and redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }

    // Handle timeout errors
    if (error.code === 'ECONNABORTED') {
      console.error('Request timeout. The server might be down or overloaded.');
    }

    // Handle CORS errors
    if (error.message === 'Network Error') {
      console.error('CORS or network error. Check if the server is accessible and CORS is configured correctly.');

      // If we're in development, suggest using the production API
      if (process.env.NODE_ENV === 'development') {
        console.info('Consider using the production API by editing .env.development file.');
      }
    }

    return Promise.reject(error);
  }
);

// Add retry and circuit breaker functionality to API methods
const originalGet = api.get;
api.get = function(url, config) {
  return executeWithRetry(() => originalGet(url, config), {
    maxRetries: 3,
    retryDelay: 1000,
    useExponentialBackoff: true
  });
};

const originalPost = api.post;
api.post = function(url, data, config) {
  return executeWithRetry(() => originalPost(url, data, config), {
    maxRetries: 2, // Fewer retries for mutations
    retryDelay: 1000,
    useExponentialBackoff: true
  });
};

const originalPut = api.put;
api.put = function(url, data, config) {
  return executeWithRetry(() => originalPut(url, data, config), {
    maxRetries: 2, // Fewer retries for mutations
    retryDelay: 1000,
    useExponentialBackoff: true
  });
};

const originalDelete = api.delete;
api.delete = function(url, config) {
  return executeWithRetry(() => originalDelete(url, config), {
    maxRetries: 2, // Fewer retries for mutations
    retryDelay: 1000,
    useExponentialBackoff: true
  });
};

export default api;
