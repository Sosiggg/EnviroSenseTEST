/*
 * EnviroSense - ESP32 Environmental Sensor with WebSocket Connection
 *
 * This sketch reads temperature, humidity, and obstacle data from sensors
 * and sends it to a FastAPI backend via secure WebSocket connection.
 *
 * Required Libraries (install via Arduino Library Manager):
 * - WebSockets by Markus Sattler (v2.3.5 or later)
 * - ArduinoJson by Benoit Blanchon (v6.19.4 or later)
 * - DHT sensor library by Adafruit (v1.4.3 or later)
 * - Adafruit Unified Sensor by Adafruit (dependency for DHT library)
 */

#include <WebSocketsClient.h>       // For WebSocket client on ESP32
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>            // For JSON parsing and creation
#include "DHT.h"

// WiFi Credentials
const char* ssid = "";
const char* password = "";

// WebSocket Server
const char* websocket_host = "envirosense-2khv.onrender.com";  // No `ws://`, just domain
const uint16_t websocket_port = 443;  // Use 443 for secure WebSocket (wss://)
const char* websocket_path = "/api/v1/sensor/ws";  // Adjust to match your FastAPI WebSocket endpoint

// JWT Token (get this from login endpoint)
const char* jwt_token = "";

// Pins
#define IR_SENSOR_PIN 15
#define DHT_PIN 13
#define DHT_TYPE DHT22

DHT dht(DHT_PIN, DHT_TYPE);
WebSocketsClient webSocket;

// Global variables for reconnection
static unsigned long lastReconnectAttempt = 0;
unsigned long reconnectInterval = 3000; // Start with 3 seconds
const unsigned long maxReconnectInterval = 60000; // Max 1 minute between attempts
bool wasConnected = false;

// Memory monitoring
static unsigned long lastMemReport = 0;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  // Get current time outside the switch to avoid jump errors
  unsigned long currentTime = millis();

  switch(type) {
    case WStype_CONNECTED:
      Serial.println("✅ WebSocket connected successfully!");
      Serial.println("🔌 Connection established with EnviroSense server");

      // Reset reconnect interval on successful connection
      reconnectInterval = 3000;
      wasConnected = true;

      // Report memory
      Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
      break;

    case WStype_DISCONNECTED:
      Serial.println("⚠️ WebSocket disconnected!");
      Serial.println("🔄 Will attempt to reconnect automatically...");

      // Implement exponential backoff for reconnection
      if (currentTime - lastReconnectAttempt > reconnectInterval) {
        lastReconnectAttempt = currentTime;

        // Exponential backoff - increase the interval each time
        if (wasConnected) {
          // If we were connected before, start with the base interval
          reconnectInterval = 3000;
          wasConnected = false;
        } else {
          // Otherwise, increase the interval (exponential backoff)
          reconnectInterval = min(reconnectInterval * 2, maxReconnectInterval);
        }

        Serial.printf("Reconnecting with interval: %d ms\n", reconnectInterval);

        // Check WiFi first
        if (WiFi.status() != WL_CONNECTED) {
          Serial.println("📡 WiFi disconnected, reconnecting first...");
          WiFi.disconnect();
          delay(500);
          connectToWiFi();
        }

        // Only try to reconnect WebSocket if WiFi is connected
        if (WiFi.status() == WL_CONNECTED) {
          Serial.println("🔄 Forcing WebSocket reconnection...");
          webSocket.disconnect();
          delay(500);
          setupWebSocket();
        }
      }
      break;

    case WStype_TEXT: {
      Serial.println("📨 Message received from server:");
      Serial.printf("%s\n", payload);

      // Use smaller JSON document size
      DynamicJsonDocument doc(256);
      DeserializationError error = deserializeJson(doc, payload);

      if (!error) {
        // Check if this is a status message
        if (doc.containsKey("status")) {
          String status = doc["status"];
          String message = doc["message"];

          Serial.printf("Status: %s, Message: %s\n", status.c_str(), message.c_str());

          if (status == "success") {
            Serial.println("✅ Data successfully received by server");
          } else if (status == "connected") {
            Serial.println("✅ Connection confirmation from server");
            // Reset reconnect interval on connection confirmation
            reconnectInterval = 3000;
          } else {
            Serial.println("⚠️ Server reported an issue with the data");
          }
        }
        // Check if this is a pong response
        else if (doc.containsKey("type") && doc["type"] == "pong") {
          Serial.println("📡 Pong response received from server");
          // Reset reconnect interval on pong
          reconnectInterval = 3000;
        }
        // Check if this is sensor data being echoed back
        else if (doc.containsKey("temperature") && doc.containsKey("humidity")) {
          Serial.println("📊 Server echoed back sensor data");
          float temp = doc["temperature"];
          float humid = doc["humidity"];
          bool obstacle = doc["obstacle"];
          Serial.printf("  Temperature: %.1f°C, Humidity: %.1f%%, Obstacle: %s\n",
                        temp, humid, obstacle ? "YES" : "NO");
        }
        // Unknown message type
        else {
          Serial.println("❓ Unknown message format received");
        }
      } else {
        Serial.println("⚠️ Failed to parse JSON from server: " + String(error.c_str()));
      }
      break;
    }

    case WStype_ERROR:
      Serial.println("❌ WebSocket error occurred!");
      Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());

      // Force reconnection on error with delay proportional to reconnect interval
      Serial.println("🔄 Attempting to reconnect after error...");
      webSocket.disconnect();
      delay(min(reconnectInterval / 3, (unsigned long)3000)); // Use a portion of the reconnect interval, max 3 seconds

      // Check WiFi first
      if (WiFi.status() != WL_CONNECTED) {
        connectToWiFi();
      }

      // Reconnect WebSocket
      if (WiFi.status() == WL_CONNECTED) {
        setupWebSocket();
      }
      break;

    case WStype_PING:
      Serial.println("📡 Ping received");
      break;

    case WStype_PONG:
      Serial.println("📡 Pong received");
      // Reset reconnect interval when we get a pong (connection is alive)
      reconnectInterval = 3000;
      break;
  }
}


void connectToWiFi() {
  Serial.println("🔌 Connecting to WiFi network: " + String(ssid));

  // Disconnect before reconnecting
  WiFi.disconnect();
  delay(100);

  // Set WiFi mode
  WiFi.mode(WIFI_STA);
  delay(100);

  // Begin connection
  WiFi.begin(ssid, password);

  // Wait for connection with timeout
  int timeout = 0;
  while (WiFi.status() != WL_CONNECTED && timeout < 30) { // 15 second timeout (increased)
    delay(500);
    Serial.print(".");
    timeout++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected successfully!");
    Serial.print("📱 IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("📶 Signal strength (RSSI): ");
    Serial.println(WiFi.RSSI());
  } else {
    Serial.println("\n❌ Failed to connect to WiFi! Will retry later...");
  }
}

// SSL Certificate verification callback
// This is needed because ESP32 can't verify SSL certificates properly
// for most websites. In production, you should implement proper certificate verification.
void setCertificateVerification() {
  // Disable SSL certificate verification
  // IMPORTANT: In production, you should use proper certificate verification!
  // This is just for development and testing.
  WiFiClientSecure *client = new WiFiClientSecure;
  client->setInsecure(); // Skip certificate verification

  Serial.println("⚠️ SSL certificate verification disabled for development");
  Serial.println("   In production, implement proper certificate verification!");
}

void setupWebSocket() {
  // Construct WebSocket path with token
  String fullPath = String(websocket_path) + "?token=" + jwt_token;

  Serial.println("🔌 Setting up secure WebSocket connection...");
  Serial.print("🌐 Host: ");
  Serial.println(websocket_host);
  Serial.print("🔌 Port: ");
  Serial.println(websocket_port);
  Serial.print("🔗 Path: ");
  Serial.println(fullPath);

  // Set certificate verification (or bypass it for development)
  setCertificateVerification();


  // Begin WebSocket connection with SSL
  webSocket.beginSSL(websocket_host, websocket_port, fullPath.c_str());
  webSocket.onEvent(webSocketEvent);

  // Set more aggressive reconnection settings
  webSocket.setReconnectInterval(reconnectInterval); // Use the dynamic reconnect interval

  // Enable heartbeat to keep connection alive with more aggressive settings
  webSocket.enableHeartbeat(3000, 2000, 10); // Ping every 3 seconds, timeout after 2 seconds, 10 tries
}

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  delay(1000); // Give serial monitor time to start

  Serial.println("\n\n🔧 EnviroSense starting up...");
  Serial.printf("Initial free heap: %d bytes\n", ESP.getFreeHeap());

  // Initialize sensors
  pinMode(IR_SENSOR_PIN, INPUT);
  dht.begin();
  Serial.println("✅ Sensors initialized");

  // Connect to WiFi
  connectToWiFi();

  // Setup WebSocket connection
  setupWebSocket();

  Serial.println("🚀 EnviroSense system ready!");
}

// Global variables for sensor data
float lastTemp = 0;
float lastHumid = 0;
bool lastObstacle = false;
unsigned long lastSendTime = 0;
const unsigned long SEND_INTERVAL = 2000; // 2 seconds between sends (reduced from 3 seconds)
bool firstReading = true;

void loop() {
  // Get current time
  unsigned long currentTime = millis();

  // Periodic memory reporting
  if (currentTime - lastMemReport >= 60000) { // Every minute
    lastMemReport = currentTime;
    Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
  }

  // Check if WebSocket needs reconnection
  static unsigned long lastWebSocketCheck = 0;
  if (currentTime - lastWebSocketCheck >= 15000) { // Check every 15 seconds (reduced from 30)
    lastWebSocketCheck = currentTime;

    // Force a ping to check connection
    if (WiFi.status() == WL_CONNECTED) {
      webSocket.sendPing();

      // Also send a ping message in JSON format that the server can understand
      DynamicJsonDocument pingDoc(64);
      pingDoc["type"] = "ping";
      String pingPayload;
      serializeJson(pingDoc, pingPayload);
      webSocket.sendTXT(pingPayload);
      Serial.println("📡 Sending ping message: " + pingPayload);
    }
  }

  // Process WebSocket events
  webSocket.loop();

  // Print connection status every 30 seconds
  static unsigned long lastStatusPrint = 0;
  if (currentTime - lastStatusPrint >= 30000) { // Every 30 seconds
    lastStatusPrint = currentTime;

    // Print connection status
    Serial.println("\n--- CONNECTION STATUS ---");
    Serial.printf("WiFi Connected: %s (RSSI: %d dBm)\n",
                  WiFi.status() == WL_CONNECTED ? "YES" : "NO",
                  WiFi.RSSI());
    Serial.printf("WebSocket Connected: %s\n",
                  webSocket.isConnected() ? "YES" : "NO");
    Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
    Serial.printf("Uptime: %lu seconds\n", currentTime / 1000);
    Serial.println("------------------------\n");
  }

  // Check WiFi connection and reconnect if needed
  static unsigned long lastWifiCheck = 0;
  if (currentTime - lastWifiCheck >= 10000) { // Check every 10 seconds
    lastWifiCheck = currentTime;

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("⚠️ WiFi connection lost! Reconnecting...");
      WiFi.disconnect();
      delay(1000);
      connectToWiFi();

      // Reinitialize WebSocket after WiFi reconnection
      if (WiFi.status() == WL_CONNECTED) {
        setupWebSocket();
      }
    }
  }

  // Only send data at the specified interval
  if (currentTime - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = currentTime;

    // IR Sensor Reading
    int irValue = digitalRead(IR_SENSOR_PIN);
    bool obstacle = (irValue == LOW); // Most IR sensors output LOW when obstacle detected

    // Debug IR sensor
    static unsigned long lastIrDebug = 0;
    if (currentTime - lastIrDebug >= 5000) { // Print IR status every 5 seconds
      lastIrDebug = currentTime;
      Serial.printf("IR Sensor: Pin %d, Raw Value: %d, Obstacle Detected: %s\n",
                    IR_SENSOR_PIN, irValue, obstacle ? "YES" : "NO");
    }

    // DHT22 Readings
    float temp = dht.readTemperature();
    float humid = dht.readHumidity();

    // Check if readings are valid
    bool validReadings = true;

    if (isnan(temp) || isnan(humid)) {
      Serial.println("⚠️ Failed to read from DHT22 sensor!");

      if (!firstReading) {
        // Use last valid readings if this isn't the first attempt
        Serial.println("ℹ️ Using last valid readings instead");
        temp = lastTemp;
        humid = lastHumid;
        validReadings = true;
      } else {
        validReadings = false;
      }
    } else {
      // Save valid readings
      lastTemp = temp;
      lastHumid = humid;
      lastObstacle = obstacle;
      firstReading = false;
    }

    if (validReadings) {
      // Print to serial
      Serial.printf("🌡️ Temp: %.1f°C | 💧 Humidity: %.1f%% | 🚧 Obstacle: %s\n",
                    temp, humid, obstacle ? "YES" : "NO");

      // Create JSON using ArduinoJson
      DynamicJsonDocument doc(256); // Increased size for additional fields
      doc["temperature"] = round(temp * 10) / 10.0; // Round to 1 decimal place
      doc["humidity"] = round(humid * 10) / 10.0;   // Round to 1 decimal place

      // TEST: Alternate obstacle value every 10 seconds to test if it updates in the app
      static bool testObstacle = false;
      static unsigned long lastObstacleToggle = 0;
      if (currentTime - lastObstacleToggle >= 10000) { // Toggle every 10 seconds
        lastObstacleToggle = currentTime;
        testObstacle = !testObstacle;
        Serial.printf("TEST: Toggling obstacle test value to %s\n", testObstacle ? "TRUE" : "FALSE");
      }

      // Use the test value instead of the actual sensor reading
      doc["obstacle"] = testObstacle;

      // Add a timestamp in ISO8601 format (the server will override this with its own timestamp)
      // This is just to ensure the JSON structure matches what the app expects
      unsigned long epochTime = currentTime / 1000; // Convert milliseconds to seconds
      char timestamp[25]; // Buffer for timestamp string
      sprintf(timestamp, "2023-01-01T%02d:%02d:%02dZ",
              (epochTime % 86400) / 3600,  // Hours
              (epochTime % 3600) / 60,     // Minutes
              epochTime % 60);             // Seconds
      doc["timestamp"] = timestamp;

      // Add a dummy ID and user_id to match the expected format
      doc["id"] = 0;
      doc["user_id"] = 1;

      // Serialize JSON to string
      String payload;
      serializeJson(doc, payload);

      // Check if we're connected before sending
      if (WiFi.status() == WL_CONNECTED) {
        Serial.println("📤 Sending data to server: " + payload);
        webSocket.sendTXT(payload);
      } else {
        Serial.println("❌ Cannot send data - WiFi not connected");
      }
    }
  }

  // Small delay to prevent CPU hogging
  delay(100);
}
