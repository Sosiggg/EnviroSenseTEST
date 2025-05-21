/**
 * Network utilities for API client robustness
 * Implements retry logic, circuit breaker pattern, and offline detection
 */

// Circuit breaker state
let isCircuitOpen = false;
let circuitResetTime = null;
let failureCount = 0;
const FAILURE_THRESHOLD = 5;
const RESET_TIMEOUT = 60 * 1000; // 1 minute in milliseconds

/**
 * Check if the circuit breaker is open (preventing requests)
 * @returns {boolean} True if circuit is open
 */
export const isCircuitBreakerOpen = () => {
  // If circuit is open, check if it's time to reset
  if (isCircuitOpen && circuitResetTime) {
    if (Date.now() > circuitResetTime) {
      // Reset the circuit breaker
      isCircuitOpen = false;
      failureCount = 0;
      circuitResetTime = null;
      console.log('Circuit breaker reset after timeout');
    }
  }
  return isCircuitOpen;
};

/**
 * Record a failure and potentially open the circuit breaker
 */
export const recordFailure = () => {
  failureCount++;
  console.log(`Circuit breaker: Failure count: ${failureCount}`);
  
  if (failureCount >= FAILURE_THRESHOLD) {
    isCircuitOpen = true;
    circuitResetTime = Date.now() + RESET_TIMEOUT;
    console.log('Circuit breaker opened due to too many failures');
    console.log(`Circuit will reset at: ${new Date(circuitResetTime).toLocaleTimeString()}`);
  }
};

/**
 * Reset the circuit breaker
 */
export const resetCircuitBreaker = () => {
  isCircuitOpen = false;
  failureCount = 0;
  circuitResetTime = null;
  console.log('Circuit breaker manually reset');
};

/**
 * Check if the device has internet connection
 * @returns {Promise<boolean>} True if connected
 */
export const hasInternetConnection = async () => {
  try {
    // Use navigator.onLine as a quick check
    if (!navigator.onLine) {
      return false;
    }

    // Additional check by trying to reach a reliable host
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    
    try {
      const response = await fetch('https://www.google.com/favicon.ico', {
        method: 'HEAD',
        mode: 'no-cors',
        cache: 'no-store',
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      return true;
    } catch (error) {
      clearTimeout(timeoutId);
      console.log('Internet connection check failed:', error);
      return false;
    }
  } catch (error) {
    console.error('Error checking internet connection:', error);
    return navigator.onLine; // Fall back to navigator.onLine
  }
};

/**
 * Execute a function with retry logic and circuit breaker
 * @param {Function} fn - Function to execute
 * @param {Object} options - Options
 * @param {number} options.maxRetries - Maximum number of retries
 * @param {number} options.retryDelay - Delay between retries in ms
 * @param {boolean} options.useExponentialBackoff - Whether to use exponential backoff
 * @returns {Promise<any>} Result of the function
 */
export const executeWithRetry = async (fn, options = {}) => {
  const {
    maxRetries = 3,
    retryDelay = 1000,
    useExponentialBackoff = true,
  } = options;

  // Check circuit breaker first
  if (isCircuitBreakerOpen()) {
    throw new Error('Circuit breaker is open. Too many failures recently.');
  }

  // Check internet connection
  const hasInternet = await hasInternetConnection();
  if (!hasInternet) {
    throw new Error('No internet connection');
  }

  let retryCount = 0;
  let lastError = null;

  while (retryCount <= maxRetries) {
    try {
      // Execute the function
      const result = await fn();
      
      // If successful, reduce failure count (partial reset for circuit breaker)
      if (failureCount > 0) {
        failureCount = Math.max(0, failureCount - 1);
      }
      
      return result;
    } catch (error) {
      lastError = error;
      
      // Don't retry for certain error types
      if (error.response) {
        const statusCode = error.response.status;
        // Don't retry for client errors (except 429 Too Many Requests)
        if (statusCode >= 400 && statusCode < 500 && statusCode !== 429) {
          throw error;
        }
      }

      // Increment retry count
      retryCount++;
      
      // If we've reached max retries, record failure and throw
      if (retryCount > maxRetries) {
        recordFailure();
        throw lastError;
      }

      // Wait before retrying with exponential backoff if enabled
      const delay = useExponentialBackoff
          ? retryDelay * Math.pow(2, retryCount - 1)
          : retryDelay;
          
      console.log(`Retrying request (${retryCount}/${maxRetries}) after ${delay}ms`);
      
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  // This should never be reached, but just in case
  throw lastError || new Error('Unknown error during retry');
};

/**
 * Create a cache key from a request
 * @param {string} url - URL
 * @param {Object} params - Query parameters
 * @returns {string} Cache key
 */
export const createCacheKey = (url, params = {}) => {
  const queryString = Object.keys(params)
    .sort()
    .map(key => `${key}=${params[key]}`)
    .join('&');
    
  return queryString ? `${url}?${queryString}` : url;
};

/**
 * Simple in-memory cache
 */
export const apiCache = {
  cache: new Map(),
  
  /**
   * Get item from cache
   * @param {string} key - Cache key
   * @param {number} maxAge - Maximum age in milliseconds
   * @returns {any} Cached item or undefined
   */
  get(key, maxAge = 60 * 1000) { // Default 1 minute
    const item = this.cache.get(key);
    if (!item) return undefined;
    
    const now = Date.now();
    if (now - item.timestamp > maxAge) {
      this.cache.delete(key);
      return undefined;
    }
    
    return item.value;
  },
  
  /**
   * Set item in cache
   * @param {string} key - Cache key
   * @param {any} value - Value to cache
   */
  set(key, value) {
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
    });
  },
  
  /**
   * Clear cache
   * @param {string} keyPrefix - Optional key prefix to clear only matching items
   */
  clear(keyPrefix) {
    if (keyPrefix) {
      for (const key of this.cache.keys()) {
        if (key.startsWith(keyPrefix)) {
          this.cache.delete(key);
        }
      }
    } else {
      this.cache.clear();
    }
  }
};
