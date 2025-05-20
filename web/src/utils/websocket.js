// WebSocket connection manager
class WebSocketManager {
  constructor() {
    this.socket = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectInterval = 3000; // 3 seconds
    this.listeners = [];
    this.pingInterval = null;
  }

  // Connect to the WebSocket server
  connect(token) {
    if (this.socket) {
      this.disconnect();
    }

    // Use the production URL by default
    const wsUrl = `wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?token=${token}`;
    // For local development, uncomment the line below
    // const wsUrl = `ws://localhost:8000/api/v1/sensor/ws?token=${token}`;

    try {
      this.socket = new WebSocket(wsUrl);

      this.socket.onopen = () => {
        console.log('WebSocket connected');
        this.isConnected = true;
        this.reconnectAttempts = 0;
        this.startPingInterval();
      };

      this.socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          this.notifyListeners(data);
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
        }
      };

      this.socket.onclose = (event) => {
        console.log(`WebSocket disconnected: ${event.code} ${event.reason}`);
        this.isConnected = false;
        this.stopPingInterval();
        this.attemptReconnect();
      };

      this.socket.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.isConnected = false;
      };
    } catch (error) {
      console.error('Error creating WebSocket connection:', error);
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
      
      setTimeout(() => {
        const token = localStorage.getItem('token');
        if (token) {
          this.connect(token);
        }
      }, this.reconnectInterval);
    } else {
      console.log('Max reconnect attempts reached');
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
