// WebSocket connection manager
class WebSocketManager {
  constructor() {
    this.socket = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 10; // Increased from 5 to 10
    this.reconnectInterval = 5000; // Increased from 3 to 5 seconds
    this.listeners = [];
    this.pingInterval = null;
    this.lastEmail = null; // Store the last email used for connection
  }

  // Connect to the WebSocket server using email
  connect(email) {
    if (!email) {
      console.error('Cannot connect WebSocket: No email provided');
      return;
    }

    // Store the email for reconnection attempts
    this.lastEmail = email;

    if (this.socket) {
      this.disconnect();
    }

    // Use the production URL by default with email parameter
    const wsUrl = `wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?email=${encodeURIComponent(email)}`;
    // For local development, uncomment the line below
    // const wsUrl = `ws://localhost:8000/api/v1/sensor/ws?email=${encodeURIComponent(email)}`;

    console.log(`Connecting to WebSocket at ${wsUrl}`);

    try {
      this.socket = new WebSocket(wsUrl);

      this.socket.onopen = () => {
        console.log('WebSocket connected successfully');
        this.isConnected = true;
        this.reconnectAttempts = 0;
        this.startPingInterval();

        // Notify listeners of connection status
        this.notifyListeners({ type: 'connection', status: 'connected' });
      };

      this.socket.onmessage = (event) => {
        try {
          console.log('Raw WebSocket message received:', event.data);
          const data = JSON.parse(event.data);
          console.log('Parsed WebSocket message:', data);
          this.notifyListeners(data);
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
          console.error('Raw message that failed to parse:', event.data);
        }
      };

      this.socket.onclose = (event) => {
        console.log(`WebSocket disconnected: ${event.code} ${event.reason}`);
        this.isConnected = false;
        this.stopPingInterval();

        // Notify listeners of connection status
        this.notifyListeners({ type: 'connection', status: 'disconnected', code: event.code, reason: event.reason });

        // Attempt to reconnect
        this.attemptReconnect();
      };

      this.socket.onerror = (error) => {
        console.error('WebSocket error:', error);
        // Log more details about the error
        console.error('WebSocket error details:', {
          readyState: this.socket ? this.socket.readyState : 'No socket',
          url: wsUrl,
          email: email
        });
        this.isConnected = false;

        // Notify listeners of connection error with more details
        this.notifyListeners({
          type: 'connection',
          status: 'error',
          error: 'Connection error',
          details: {
            readyState: this.socket ? this.socket.readyState : 'No socket',
            url: wsUrl
          }
        });
      };
    } catch (error) {
      console.error('Error creating WebSocket connection:', error);

      // Notify listeners of connection error
      this.notifyListeners({ type: 'connection', status: 'error', error: 'Failed to create connection' });
    }
  }

  // Disconnect from the WebSocket server
  disconnect() {
    if (this.socket) {
      this.stopPingInterval();
      this.socket.close();
      this.socket = null;
      this.isConnected = false;
    }
  }

  // Attempt to reconnect to the WebSocket server
  attemptReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);

      // Calculate backoff interval (increases with each attempt)
      const backoffInterval = this.reconnectInterval * Math.min(this.reconnectAttempts, 3);
      console.log(`Will retry in ${backoffInterval / 1000} seconds`);

      setTimeout(() => {
        // First try using the stored email
        if (this.lastEmail) {
          console.log(`Reconnecting using stored email: ${this.lastEmail}`);
          this.connect(this.lastEmail);
          return;
        }

        // Fallback to getting user from localStorage
        const userJson = localStorage.getItem('user');
        if (userJson) {
          try {
            const user = JSON.parse(userJson);
            if (user && user.email) {
              console.log(`Reconnecting using email from localStorage: ${user.email}`);
              this.connect(user.email);
            } else {
              console.error('No email found in user data');
              this.notifyListeners({ type: 'connection', status: 'error', error: 'No email available for reconnection' });
            }
          } catch (error) {
            console.error('Error parsing user JSON:', error);
            this.notifyListeners({ type: 'connection', status: 'error', error: 'Failed to parse user data for reconnection' });
          }
        } else {
          console.error('No user data found in localStorage');
          this.notifyListeners({ type: 'connection', status: 'error', error: 'No user data available for reconnection' });
        }
      }, backoffInterval);
    } else {
      console.log('Max reconnect attempts reached');
      this.notifyListeners({
        type: 'connection',
        status: 'error',
        error: `Max reconnect attempts (${this.maxReconnectAttempts}) reached`
      });
    }
  }

  // Start the ping interval to keep the connection alive
  startPingInterval() {
    this.pingInterval = setInterval(() => {
      if (this.isConnected) {
        this.sendPing();
      }
    }, 30000); // Send ping every 30 seconds
  }

  // Stop the ping interval
  stopPingInterval() {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }
  }

  // Send a ping message to keep the connection alive
  sendPing() {
    if (this.isConnected) {
      try {
        this.socket.send(JSON.stringify({ type: 'ping' }));
      } catch (error) {
        console.error('Error sending ping:', error);
      }
    }
  }

  // Add a listener for WebSocket messages
  addListener(callback) {
    this.listeners.push(callback);
    return () => this.removeListener(callback);
  }

  // Remove a listener
  removeListener(callback) {
    this.listeners = this.listeners.filter(listener => listener !== callback);
  }

  // Notify all listeners of a new message
  notifyListeners(data) {
    this.listeners.forEach(listener => {
      try {
        listener(data);
      } catch (error) {
        console.error('Error in WebSocket listener:', error);
      }
    });
  }
}

// Create a singleton instance
const websocketManager = new WebSocketManager();

export default websocketManager;
