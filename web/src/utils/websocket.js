// WebSocket connection manager
class WebSocketManager {
  constructor() {
    this.socket = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 15; // Increased to 15 attempts
    this.reconnectInterval = 5000; // Base reconnect interval (5 seconds)
    this.maxReconnectInterval = 30000; // Maximum reconnect interval (30 seconds)
    this.listeners = [];
    this.pingInterval = null;
    this.lastEmail = null; // Store the last email used for connection
    this.connectionStatus = 'disconnected'; // Track detailed connection status
    this.lastErrorMessage = null; // Store the last error message
    this.isReconnecting = false; // Flag to track if reconnection is in progress
    this.reconnectTimer = null; // Timer for reconnection attempts
  }

  // Connect to the WebSocket server using email
  connect(email) {
    if (!email) {
      console.error('Cannot connect WebSocket: No email provided');
      this.updateConnectionStatus('error', 'No email provided for WebSocket connection');
      return;
    }

    // Clear any existing reconnect timer
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    // Store the email for reconnection attempts
    this.lastEmail = email;

    // Update status to connecting
    this.updateConnectionStatus('connecting', 'Establishing connection...');

    // Close existing connection if any
    if (this.socket) {
      this.disconnect(false); // Don't notify listeners as we're reconnecting
    }

    // Use the production URL by default with email parameter
    const wsUrl = `wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?email=${encodeURIComponent(email)}`;
    // For local development, uncomment the line below
    // const wsUrl = `ws://localhost:8000/api/v1/sensor/ws?email=${encodeURIComponent(email)}`;

    console.log(`Connecting to WebSocket at ${wsUrl}`);

    try {
      // Create new WebSocket connection
      this.socket = new WebSocket(wsUrl);

      // Set connection timeout
      const connectionTimeout = setTimeout(() => {
        if (this.socket && this.socket.readyState !== WebSocket.OPEN) {
          console.error('WebSocket connection timeout');
          this.updateConnectionStatus('timeout', 'Connection attempt timed out');

          // Force close and cleanup
          if (this.socket) {
            this.socket.close();
            this.socket = null;
          }

          // Attempt to reconnect
          this.attemptReconnect();
        }
      }, 10000); // 10 second timeout

      // Connection opened successfully
      this.socket.onopen = () => {
        console.log('WebSocket connected successfully');
        clearTimeout(connectionTimeout);

        this.isConnected = true;
        this.reconnectAttempts = 0;
        this.isReconnecting = false;
        this.startPingInterval();

        this.updateConnectionStatus('connected', 'Connected to EnviroSense server');
      };

      // Message received
      this.socket.onmessage = (event) => {
        try {
          console.log('Raw WebSocket message received:', event.data);
          const data = JSON.parse(event.data);
          console.log('Parsed WebSocket message:', data);

          // Handle pong responses
          if (data.type === 'pong') {
            console.log('Received pong from server');
            return;
          }

          this.notifyListeners(data);
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
          console.error('Raw message that failed to parse:', event.data);
        }
      };

      // Connection closed
      this.socket.onclose = (event) => {
        console.log(`WebSocket disconnected: ${event.code} ${event.reason}`);
        clearTimeout(connectionTimeout);

        this.isConnected = false;
        this.stopPingInterval();

        // Different messages based on close code
        let message = 'Connection closed';
        if (event.code === 1000) {
          message = 'Normal closure';
        } else if (event.code === 1001) {
          message = 'Server going down';
        } else if (event.code === 1006) {
          message = 'Connection lost';
        } else if (event.code === 1011) {
          message = 'Server error';
        }

        if (event.reason) {
          message += `: ${event.reason}`;
        }

        this.updateConnectionStatus('disconnected', message, { code: event.code });

        // Attempt to reconnect
        this.attemptReconnect();
      };

      // Connection error
      this.socket.onerror = (error) => {
        console.error('WebSocket error:', error);
        clearTimeout(connectionTimeout);

        // Log more details about the error
        const errorDetails = {
          readyState: this.socket ? this.socket.readyState : 'No socket',
          url: wsUrl,
          email: email,
          timestamp: new Date().toISOString()
        };
        console.error('WebSocket error details:', errorDetails);

        this.isConnected = false;
        this.updateConnectionStatus('error', 'Connection error', errorDetails);

        // Note: We don't call attemptReconnect() here because onclose will be called after onerror
      };
    } catch (error) {
      console.error('Error creating WebSocket connection:', error);
      this.updateConnectionStatus('error', 'Failed to create connection', { error: error.message });

      // Attempt to reconnect
      this.attemptReconnect();
    }
  }

  // Update connection status and notify listeners
  updateConnectionStatus(status, message, details = {}) {
    this.connectionStatus = status;
    this.lastErrorMessage = message;

    console.log(`WebSocket status: ${status} - ${message}`);

    // Notify listeners of connection status change
    this.notifyListeners({
      type: 'connection',
      status: status,
      message: message,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  // Disconnect from the WebSocket server
  disconnect(notify = true) {
    // Clear any reconnect timer
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.socket) {
      this.stopPingInterval();

      try {
        // Only try to close if not already closed
        if (this.socket.readyState !== WebSocket.CLOSED) {
          this.socket.close(1000, "Normal closure by client");
        }
      } catch (error) {
        console.error('Error closing WebSocket:', error);
      }

      this.socket = null;
      this.isConnected = false;

      if (notify) {
        this.updateConnectionStatus('disconnected', 'Disconnected by client');
      }
    }
  }

  // Attempt to reconnect to the WebSocket server
  attemptReconnect() {
    // Don't attempt to reconnect if already reconnecting
    if (this.isReconnecting) {
      console.log('Already attempting to reconnect, skipping duplicate attempt');
      return;
    }

    // Check if max attempts reached
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log(`Max reconnect attempts (${this.maxReconnectAttempts}) reached`);
      this.updateConnectionStatus('failed', `Failed to reconnect after ${this.maxReconnectAttempts} attempts`);
      return;
    }

    // Set reconnecting flag
    this.isReconnecting = true;
    this.reconnectAttempts++;

    // Calculate backoff interval with exponential backoff and jitter
    const baseDelay = Math.min(
      this.maxReconnectInterval,
      this.reconnectInterval * Math.pow(1.5, this.reconnectAttempts - 1)
    );
    // Add jitter (±20%)
    const jitter = 0.2 * baseDelay * (Math.random() * 2 - 1);
    const delay = Math.floor(baseDelay + jitter);

    console.log(`Reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay/1000} seconds`);
    this.updateConnectionStatus('reconnecting', `Reconnecting (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);

    // Set reconnect timer
    this.reconnectTimer = setTimeout(() => {
      this.isReconnecting = false;

      // First try using the stored email
      if (this.lastEmail) {
        console.log(`Reconnecting using stored email: ${this.lastEmail}`);
        this.connect(this.lastEmail);
        return;
      }

      // Fallback to getting user from localStorage
      try {
        const userJson = localStorage.getItem('user');
        if (userJson) {
          const user = JSON.parse(userJson);
          if (user && user.email) {
            console.log(`Reconnecting using email from localStorage: ${user.email}`);
            this.connect(user.email);
            return;
          }
        }

        // If we get here, we couldn't find an email
        console.error('No email available for reconnection');
        this.updateConnectionStatus('error', 'No email available for reconnection');
      } catch (error) {
        console.error('Error during reconnection:', error);
        this.updateConnectionStatus('error', 'Error during reconnection attempt', { error: error.message });
      }
    }, delay);
  }

  // Start the ping interval to keep the connection alive
  startPingInterval() {
    // Clear any existing interval first
    this.stopPingInterval();

    // Set a new ping interval
    this.pingInterval = setInterval(() => {
      if (this.isConnected && this.socket && this.socket.readyState === WebSocket.OPEN) {
        this.sendPing();
      } else if (this.pingInterval) {
        // If we're not connected but the interval is running, stop it
        this.stopPingInterval();
      }
    }, 30000); // Send ping every 30 seconds

    console.log('Started WebSocket ping interval');
  }

  // Stop the ping interval
  stopPingInterval() {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
      console.log('Stopped WebSocket ping interval');
    }
  }

  // Send a ping message to keep the connection alive
  sendPing() {
    if (this.isConnected && this.socket && this.socket.readyState === WebSocket.OPEN) {
      try {
        console.log('Sending ping to keep WebSocket alive');
        this.socket.send(JSON.stringify({ type: 'ping', timestamp: new Date().toISOString() }));
      } catch (error) {
        console.error('Error sending ping:', error);

        // If we can't send a ping, the connection might be dead
        if (this.socket.readyState !== WebSocket.OPEN) {
          console.error('Socket not open when trying to send ping, forcing reconnect');
          this.disconnect(false);
          this.attemptReconnect();
        }
      }
    }
  }

  // Get current connection status
  getStatus() {
    return {
      connected: this.isConnected,
      status: this.connectionStatus,
      lastError: this.lastErrorMessage,
      reconnectAttempts: this.reconnectAttempts,
      maxReconnectAttempts: this.maxReconnectAttempts,
      isReconnecting: this.isReconnecting
    };
  }

  // Force a manual reconnection attempt
  forceReconnect() {
    console.log('Manual reconnection requested');

    // Reset reconnect attempts to give more chances
    this.reconnectAttempts = 0;

    // Disconnect and reconnect
    this.disconnect(false);

    if (this.lastEmail) {
      this.connect(this.lastEmail);
    } else {
      this.updateConnectionStatus('error', 'Cannot reconnect: No email available');
    }
  }

  // Add a listener for WebSocket messages
  addListener(callback) {
    if (typeof callback !== 'function') {
      console.error('Invalid WebSocket listener: not a function');
      return () => {};
    }

    this.listeners.push(callback);

    // Return a function to remove this listener
    return () => this.removeListener(callback);
  }

  // Remove a listener
  removeListener(callback) {
    const initialCount = this.listeners.length;
    this.listeners = this.listeners.filter(listener => listener !== callback);

    if (initialCount !== this.listeners.length) {
      console.log(`Removed WebSocket listener (${initialCount} -> ${this.listeners.length})`);
    }
  }

  // Notify all listeners of a new message
  notifyListeners(data) {
    if (!data) {
      console.error('Attempted to notify listeners with null/undefined data');
      return;
    }

    // Add timestamp if not present
    if (!data.timestamp) {
      data.timestamp = new Date().toISOString();
    }

    this.listeners.forEach(listener => {
      try {
        listener(data);
      } catch (error) {
        console.error('Error in WebSocket listener:', error);
        console.error('Listener error details:', {
          error: error.message,
          stack: error.stack,
          data: JSON.stringify(data).substring(0, 200) // Truncate for log readability
        });
      }
    });
  }
}

// Create a singleton instance
const websocketManager = new WebSocketManager();

export default websocketManager;
