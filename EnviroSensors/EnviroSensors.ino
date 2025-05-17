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
const char* ssid = "HakunaMatata";
const char* password = "Honeybadger@1993";

// WebSocket Server
const char* websocket_host = "envirosense-2khv.onrender.com";  // No `ws://`, just domain
const uint16_t websocket_port = 443;  // Use 443 for secure WebSocket (wss://)
const char* websocket_path = "/api/v1/sensor/ws";  // Adjust to match your FastAPI WebSocket endpoint

// JWT Token (get this from login endpoint)
const char* jwt_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJTb3NpZ2dnMiIsImV4cCI6MTc0NzUwOTk3MX0.7xQVuP0bHxeQCtCELpYsuWqYonhHNDL7lnL7gHR_SIc";

// Pins
#define IR_SENSOR_PIN 15
#define DHT_PIN 13
#define DHT_TYPE DHT22

DHT dht(DHT_PIN, DHT_TYPE);
WebSocketsClient webSocket;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_CONNECTED:
      Serial.println("✅ WebSocket connected successfully!");
      Serial.println("🔌 Connection established with EnviroSense server");
      break;

    case WStype_DISCONNECTED:
      Serial.println("⚠️ WebSocket disconnected!");
      Serial.println("🔄 Will attempt to reconnect automatically...");
      break;

    case WStype_TEXT: {
      Serial.println("📨 Message received from server:");
      Serial.printf("%s\n", payload);

      // 👇 Now wrapped in a scope block to fix 'jump to case label' error
      DynamicJsonDocument doc(256);
      DeserializationError error = deserializeJson(doc, payload);

      if (!error) {
        String status = doc["status"];
        String message = doc["message"];

        Serial.printf("Status: %s, Message: %s\n", status.c_str(), message.c_str());

        if (status == "success") {
          Serial.println("✅ Data successfully received by server");
        } else {
          Serial.println("⚠️ Server reported an issue with the data");
        }
      } else {
        Serial.println("⚠️ Failed to parse JSON from server");
      }
      break;
    }

    case WStype_ERROR:
      Serial.println("❌ WebSocket error occurred!");
      break;

    case WStype_PING:
      Serial.println("📡 Ping received");
      break;

    case WStype_PONG:
      Serial.println("📡 Pong received");
      break;
  }
}


void connectToWiFi() {
  Serial.println("🔌 Connecting to WiFi network: " + String(ssid));
  WiFi.begin(ssid, password);

  // Wait for connection with timeout
  int timeout = 0;
  while (WiFi.status() != WL_CONNECTED && timeout < 20) { // 10 second timeout
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
    Serial.println("\n❌ Failed to connect to WiFi! Will retry in setup...");
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
  webSocket.setReconnectInterval(5000);

  // Enable heartbeat to keep connection alive
  webSocket.enableHeartbeat(15000, 3000, 2);
}

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  delay(1000); // Give serial monitor time to start

  Serial.println("\n\n🔧 EnviroSense starting up...");

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
const unsigned long SEND_INTERVAL = 3000; // 3 seconds between sends
bool firstReading = true;

void loop() {
  // Process WebSocket events
  webSocket.loop();

  // Check WiFi connection and reconnect if needed
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️ WiFi connection lost! Reconnecting...");
    connectToWiFi();
  }

  // Only send data at the specified interval
  unsigned long currentTime = millis();
  if (currentTime - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = currentTime;

    // IR Sensor Reading
    int irValue = digitalRead(IR_SENSOR_PIN);
    bool obstacle = (irValue == LOW);

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
      DynamicJsonDocument doc(128);
      doc["temperature"] = round(temp * 10) / 10.0; // Round to 1 decimal place
      doc["humidity"] = round(humid * 10) / 10.0;   // Round to 1 decimal place
      doc["obstacle"] = obstacle;

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
