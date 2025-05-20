#include <WebSocketsClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "DHT.h"

// WiFi Credentials
const char* ssid = "HakunaMatata";
const char* password = "Honeybadger@1993";

// WebSocket Server
const char* websocket_host = "envirosense-2khv.onrender.com";
const uint16_t websocket_port = 443;
const char* websocket_path = "/api/v1/sensor/ws"; // This should match your backend route

// Email used in query param
const char* user_email = "ivi.salski.35@gmail.com";

// DHT Sensor
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Ultrasonic Sensor
#define TRIG_PIN 5
#define ECHO_PIN 18
const int OBSTACLE_THRESHOLD = 30;

// LED Indicators
#define WIFI_LED 2
#define SENSOR_LED 15
#define ERROR_LED 13

WebSocketsClient webSocket;

// Timing variables
unsigned long lastSensorReadTime = 0;
const long sensorReadInterval = 5000;
unsigned long lastHeartbeatTime = 0;
const long heartbeatInterval = 30000;
unsigned long reconnectInterval = 5000;
const long maxReconnectInterval = 60000;

// Status flags
bool isWifiConnected = false;
bool isWebSocketConnected = false;

// ----------------------------------
// Setup
// ----------------------------------
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n🚀 EnviroSense ESP32 Client Starting...");

  // LED Setup
  pinMode(WIFI_LED, OUTPUT);
  pinMode(SENSOR_LED, OUTPUT);
  pinMode(ERROR_LED, OUTPUT);
  digitalWrite(WIFI_LED, LOW);
  digitalWrite(SENSOR_LED, LOW);
  digitalWrite(ERROR_LED, LOW);

  // Sensor Pin Setup
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  dht.begin();

  connectToWiFi();
  setupWebSocket();
}

// ----------------------------------
// Main Loop
// ----------------------------------
void loop() {
  webSocket.loop();

  if (WiFi.status() != WL_CONNECTED) {
    if (isWifiConnected) {
      Serial.println("❌ WiFi disconnected.");
      isWifiConnected = false;
      digitalWrite(WIFI_LED, LOW);
    }
    connectToWiFi();
  }

  if (isWifiConnected && !isWebSocketConnected) {
    static unsigned long lastReconnectAttempt = 0;
    if (millis() - lastReconnectAttempt > reconnectInterval) {
      lastReconnectAttempt = millis();
      reconnectInterval = min(reconnectInterval * 2, (unsigned long)maxReconnectInterval);

      // Reset WebSocket connection before attempting to reconnect
      webSocket.disconnect();
      delay(500); // Give it time to disconnect properly

      Serial.println("🔄 Reconnecting WebSocket...");
      Serial.print("📶 WiFi Status: ");
      Serial.println(WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
      Serial.print("🔄 Reconnect Interval: ");
      Serial.print(reconnectInterval / 1000.0);
      Serial.println(" seconds");

      setupWebSocket();
    }
  }

  if (isWebSocketConnected) {
    unsigned long now = millis();

    if (now - lastSensorReadTime > sensorReadInterval) {
      lastSensorReadTime = now;
      readAndSendSensorData();
    }

    if (now - lastHeartbeatTime > heartbeatInterval) {
      lastHeartbeatTime = now;
      sendHeartbeat();
    }
  }
}

// ----------------------------------
// WiFi Connection
// ----------------------------------
void connectToWiFi() {
  if (isWifiConnected) return;

  Serial.print("📶 Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    digitalWrite(WIFI_LED, !digitalRead(WIFI_LED));
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    digitalWrite(WIFI_LED, HIGH);
    isWifiConnected = true;
    reconnectInterval = 5000;
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    digitalWrite(ERROR_LED, HIGH);
    delay(1000);
    digitalWrite(ERROR_LED, LOW);
  }
}

// ----------------------------------
// WebSocket Setup
// ----------------------------------
void setupWebSocket() {
  String fullPath = String(websocket_path) + "?email=" + urlEncode(user_email);

  Serial.println("🔌 Setting up secure WebSocket connection...");
  Serial.print("🌐 Host: ");
  Serial.println(websocket_host);
  Serial.print("🔌 Port: ");
  Serial.println(websocket_port);
  Serial.print("🔗 Path: ");
  Serial.println(fullPath);

  // IMPORTANT: Set insecure mode to bypass SSL certificate verification
  // This is required for connecting to Render.com with self-signed certificates
  webSocket.setInsecure();

  // Begin WebSocket connection with SSL
  webSocket.beginSSL(websocket_host, websocket_port, fullPath.c_str());
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(reconnectInterval);
  webSocket.enableHeartbeat(15000, 3000, 2);
}


// ----------------------------------
// WebSocket Events
// ----------------------------------
void webSocketEvent(WStype_t type, uint8_t *payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("❌ WebSocket disconnected!");
      isWebSocketConnected = false;
      break;

    case WStype_CONNECTED:
      Serial.println("✅ WebSocket connected successfully!");
      Serial.println("🎉 Connection established to server");
      isWebSocketConnected = true;
      reconnectInterval = 5000; // Reset reconnect interval
      digitalWrite(WIFI_LED, HIGH); // Turn on WiFi LED to indicate connection
      break;

    case WStype_TEXT:
      handleWebSocketMessage(payload, length);
      break;

    case WStype_ERROR:
      Serial.println("❌ WebSocket Error!");
      // Print more detailed error information if available
      if (length > 0) {
        Serial.print("Error payload: ");
        for (size_t i = 0; i < length; i++) {
          Serial.print(payload[i], HEX);
          Serial.print(" ");
        }
        Serial.println();
      }
      digitalWrite(ERROR_LED, HIGH);
      delay(500);
      digitalWrite(ERROR_LED, LOW);
      break;

    case WStype_BIN:
      Serial.println("📦 Received binary data (not handling)");
      break;

    case WStype_FRAGMENT_TEXT_START:
    case WStype_FRAGMENT_BIN_START:
    case WStype_FRAGMENT:
    case WStype_FRAGMENT_FIN:
      Serial.println("🧩 Received fragmented data (not handling)");
      break;

    case WStype_PING:
      Serial.println("📍 Received PING from server");
      break;

    case WStype_PONG:
      Serial.println("📌 Received PONG from server");
      break;

    default:
      Serial.print("⚠️ Unknown WebSocket event type: ");
      Serial.println(type);
      break;
  }
}

// ----------------------------------
// Message Handling
// ----------------------------------
void handleWebSocketMessage(uint8_t* payload, size_t length) {
  String msg = String((char*)payload);
  Serial.print("📥 Received: ");
  Serial.println(msg);

  DynamicJsonDocument doc(1024);
  auto error = deserializeJson(doc, msg);
  if (error) {
    Serial.print("❌ JSON error: ");
    Serial.println(error.c_str());
    return;
  }

  if (doc["type"] == "pong") {
    Serial.println("💓 Heartbeat acknowledged");
  } else if (doc["status"]) {
    String status = doc["status"];
    if (status == "success") {
      Serial.println("✅ Server acknowledged data");
      blinkLED(SENSOR_LED, 200);
    } else {
      Serial.print("❌ Server error: ");
      Serial.println(doc["message"].as<String>());
      blinkLED(ERROR_LED, 500);
    }
  }
}

void sendHeartbeat() {
  if (isWebSocketConnected) {
    webSocket.sendTXT("{\"type\": \"ping\"}");
    Serial.println("💓 Sent heartbeat ping");
  }
}

// ----------------------------------
// Sensor Readings and Sending
// ----------------------------------
void readAndSendSensorData() {
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  bool obs = readObstacle();

  if (isnan(temp) || isnan(hum)) {
    Serial.println("❌ Failed to read DHT sensor");
    blinkLED(ERROR_LED, 500);
    return;
  }

  Serial.printf("🌡️ %.2f °C, 💧 %.2f %%, 🚧 Obstacle: %s\n", temp, hum, obs ? "YES" : "NO");

  DynamicJsonDocument doc(256);
  doc["temperature"] = temp;
  doc["humidity"] = hum;
  doc["obstacle"] = obs;

  String jsonOut;
  serializeJson(doc, jsonOut);
  webSocket.sendTXT(jsonOut);
  blinkLED(SENSOR_LED, 100);
}

// ----------------------------------
// Ultrasonic Distance
// ----------------------------------
bool readObstacle() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH);
  int distance = duration * 0.034 / 2;

  return distance < OBSTACLE_THRESHOLD;
}

// ----------------------------------
// Helper Functions
// ----------------------------------
void blinkLED(int pin, int duration) {
  digitalWrite(pin, HIGH);
  delay(duration);
  digitalWrite(pin, LOW);
}

// URL encode for email parameter
String urlEncode(const char* str) {
  String encoded = "";
  char c;
  char code0, code1;
  for (int i = 0; i < strlen(str); i++) {
    c = str[i];
    if (isalnum(c)) {
      encoded += c;
    } else {
      code0 = (c >> 4) & 0xF;
      code1 = c & 0xF;
      encoded += '%';
      encoded += "0123456789ABCDEF"[code0];
      encoded += "0123456789ABCDEF"[code1];
    }
  }
  return encoded;
}
