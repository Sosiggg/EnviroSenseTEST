/**
 * Centralized error handling utility
 * Provides consistent error handling across the application
 */

// Error types
export const ErrorTypes = {
  NETWORK: 'NETWORK',
  AUTH: 'AUTH',
  VALIDATION: 'VALIDATION',
  SERVER: 'SERVER',
  TIMEOUT: 'TIMEOUT',
  UNKNOWN: 'UNKNOWN',
};

/**
 * Get error type from an error object
 * @param {Error} error - Error object
 * @returns {string} Error type
 */
export const getErrorType = (error) => {
  if (!error) return ErrorTypes.UNKNOWN;
  
  // Network errors
  if (error.message === 'Network Error' || 
      error.code === 'ERR_NETWORK' ||
      error.name === 'NetworkError') {
    return ErrorTypes.NETWORK;
  }
  
  // Timeout errors
  if (error.code === 'ECONNABORTED' || 
      error.message?.includes('timeout')) {
    return ErrorTypes.TIMEOUT;
  }
  
  // Authentication errors
  if (error.response?.status === 401 || 
      error.response?.status === 403 ||
      error.message?.includes('unauthorized') ||
      error.message?.includes('forbidden')) {
    return ErrorTypes.AUTH;
  }
  
  // Validation errors
  if (error.response?.status === 400 || 
      error.response?.status === 422) {
    return ErrorTypes.VALIDATION;
  }
  
  // Server errors
  if (error.response?.status >= 500) {
    return ErrorTypes.SERVER;
  }
  
  return ErrorTypes.UNKNOWN;
};

/**
 * Get user-friendly error message
 * @param {Error} error - Error object
 * @returns {string} User-friendly error message
 */
export const getUserFriendlyMessage = (error) => {
  if (!error) return 'An unknown error occurred';
  
  // If the error already has a user-friendly message, use it
  if (error.userMessage) {
    return error.userMessage;
  }
  
  const errorType = getErrorType(error);
  
  switch (errorType) {
    case ErrorTypes.NETWORK:
      return 'Network error. Please check your internet connection and try again.';
    
    case ErrorTypes.TIMEOUT:
      return 'Request timed out. The server might be down or overloaded. Please try again later.';
    
    case ErrorTypes.AUTH:
      if (error.response?.status === 401) {
        return 'Your session has expired. Please log in again.';
      }
      if (error.response?.status === 403) {
        return 'You don\'t have permission to access this resource.';
      }
      return 'Authentication error. Please log in again.';
    
    case ErrorTypes.VALIDATION:
      // Try to extract validation error messages
      if (error.response?.data?.detail) {
        return error.response.data.detail;
      }
      if (error.response?.data?.message) {
        return error.response.data.message;
      }
      return 'Invalid input. Please check your information and try again.';
    
    case ErrorTypes.SERVER:
      return 'Server error. Our team has been notified. Please try again later.';
    
    default:
      // Try to extract any message from the error
      if (error.response?.data?.detail) {
        return error.response.data.detail;
      }
      if (error.response?.data?.message) {
        return error.response.data.message;
      }
      if (error.message && !error.message.includes('Error') && !error.message.includes('error')) {
        return error.message;
      }
      return 'An unexpected error occurred. Please try again.';
  }
};

/**
 * Get detailed error message for logging
 * @param {Error} error - Error object
 * @returns {string} Detailed error message
 */
export const getDetailedErrorMessage = (error) => {
  if (!error) return 'Unknown error';
  
  const details = [];
  
  // Add error message
  if (error.message) {
    details.push(`Message: ${error.message}`);
  }
  
  // Add error name and code
  if (error.name) details.push(`Name: ${error.name}`);
  if (error.code) details.push(`Code: ${error.code}`);
  
  // Add response details if available
  if (error.response) {
    details.push(`Status: ${error.response.status}`);
    
    if (error.response.data) {
      if (typeof error.response.data === 'object') {
        details.push(`Data: ${JSON.stringify(error.response.data)}`);
      } else {
        details.push(`Data: ${error.response.data}`);
      }
    }
  }
  
  // Add request details if available
  if (error.config) {
    details.push(`URL: ${error.config.url}`);
    details.push(`Method: ${error.config.method}`);
  }
  
  return details.join(', ');
};

/**
 * Log an error with detailed information
 * @param {Error} error - Error object
 * @param {string} context - Context where the error occurred
 */
export const logError = (error, context = '') => {
  const errorType = getErrorType(error);
  const detailedMessage = getDetailedErrorMessage(error);
  
  console.error(`[${context}] ${errorType} Error:`, detailedMessage);
  
  // Here you could add integration with a logging service like Sentry
  // for production error tracking
};

/**
 * Create an enhanced error with user-friendly message
 * @param {Error} error - Original error
 * @param {string} userMessage - Optional custom user message
 * @returns {Error} Enhanced error
 */
export const createEnhancedError = (error, userMessage = null) => {
  const enhancedError = new Error(userMessage || getUserFriendlyMessage(error));
  enhancedError.originalError = error;
  enhancedError.errorType = getErrorType(error);
  enhancedError.userMessage = userMessage || getUserFriendlyMessage(error);
  enhancedError.timestamp = new Date().toISOString();
  return enhancedError;
};

/**
 * Handle an error with appropriate logging and return enhanced error
 * @param {Error} error - Error object
 * @param {string} context - Context where the error occurred
 * @param {string} userMessage - Optional custom user message
 * @returns {Error} Enhanced error
 */
export const handleError = (error, context = '', userMessage = null) => {
  // Log the error
  logError(error, context);
  
  // Create and return enhanced error
  return createEnhancedError(error, userMessage);
};
