#include <SocketIOclient.h>         // Optional, only if you use Socket.IO protocol
#include <WebSocketsClient.h>       // For WebSocket client on ESP32
#include <WiFi.h>
#include "DHT.h"

// WiFi Credentials
const char* ssid = "HakunaMatata";
const char* password = "Honeybadger@1993";

// WebSocket Server
const char* websocket_host = "envirosense-2khv.onrender.com";  // No `ws://`, just domain
const uint16_t websocket_port = 443;  // Use 443 for secure WebSocket (wss://)
const char* websocket_path = "/api/v1/sensor/ws";  // Adjust to match your FastAPI WebSocket endpoint

// JWT Token (get this from login endpoint)
const char* jwt_token = "your-jwt-token-here";  // Replace with your actual JWT token

// Pins
#define IR_SENSOR_PIN 15
#define DHT_PIN 13
#define DHT_TYPE DHT22

DHT dht(DHT_PIN, DHT_TYPE);
WebSocketsClient webSocket;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  // Handle WebSocket events (optional)
  switch(type) {
    case WStype_CONNECTED:
      Serial.println("✅ WebSocket connected.");
      break;
    case WStype_DISCONNECTED:
      Serial.println("⚠️ WebSocket disconnected.");
      break;
    case WStype_TEXT:
      Serial.printf("📨 Message from server: %s\n", payload);
      break;
  }
}

void connectToWiFi() {
  Serial.print("🔌 Connecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi connected!");
  Serial.println(WiFi.localIP());
}

void setup() {
  Serial.begin(115200);
  pinMode(IR_SENSOR_PIN, INPUT);
  dht.begin();

  connectToWiFi();

  // Construct WebSocket path with token
  String fullPath = String(websocket_path) + "?token=" + jwt_token;

  // Begin WebSocket connection
  webSocket.beginSSL(websocket_host, websocket_port, fullPath.c_str());
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);

  Serial.println("🔧 EnviroSense started.");
}

void loop() {
  webSocket.loop();

  // IR Sensor Reading
  int irValue = digitalRead(IR_SENSOR_PIN);
  bool obstacle = (irValue == LOW);

  // DHT22 Readings
  float temp = dht.readTemperature();
  float humid = dht.readHumidity();

  if (isnan(temp) || isnan(humid)) {
    Serial.println("⚠️ Failed to read from DHT22!");
  } else {
    // Print to serial
    Serial.printf("🌡️ Temp: %.1f°C | 💧 Humidity: %.1f%% | 🚧 Obstacle: %s\n",
                  temp, humid, obstacle ? "YES" : "NO");

    // Send JSON payload via WebSocket
    String payload = "{";
    payload += "\"temperature\":" + String(temp, 1) + ",";
    payload += "\"humidity\":" + String(humid, 1) + ",";
    payload += "\"obstacle\":" + String(obstacle ? "true" : "false");
    payload += "}";

    webSocket.sendTXT(payload);
  }

  delay(3000); // Wait between reads
}
