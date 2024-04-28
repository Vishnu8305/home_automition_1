#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <PubSubClient.h>

// Define the GPIO pins for the LEDs
#define LED1 15
#define LED2 2
#define LED3 0
#define LED4 4

// WiFi and MQTT Configuration
const char* apSSID = "ESP32_Setup_Network1";
const char* apPassword = "123456789";
const char* mqttBroker = "192.168.0.5";  // MQTT broker IP address

WiFiClient espClient;
PubSubClient mqttClient(espClient);
AsyncWebServer server(80);

// Device ID based on the ESP32's MAC address for unique identification
String deviceID = String("ESP32_") + WiFi.macAddress();
String topic = "device/" + WiFi.macAddress();  // MQTT topic

void setupWiFiAP() {
    WiFi.softAP(apSSID, apPassword);
    Serial.print("AP IP address: ");
    Serial.println(WiFi.softAPIP());
}

void setupWebServer() {
    server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
        String html = "<!DOCTYPE html><html><head><title>ESP32 Setup</title></head><body>"
                      "<h2>ESP32 WiFi Setup</h2>"
                      "<p>MQTT Topic: " + topic + "</p>"
                      "<form action='/setup' method='post'>"
                      "SSID:<br><input type='text' name='ssid'><br>"
                      "Password:<br><input type='password' name='password'><br><br>"
                      "<input type='submit' value='Connect'>"
                      "</form>"
                      "<p>Device ID: " + deviceID + "</p>"
                      "</body></html>";
        request->send(200, "text/html", html);
    });

    server.on("/setup", HTTP_POST, [](AsyncWebServerRequest *request) {
        if (request->hasParam("ssid", true) && request->hasParam("password", true)) {
            String ssid = request->getParam("ssid", true)->value();
            String pass = request->getParam("password", true)->value();
            connectToWiFi(ssid, pass);
            request->send(200, "text/plain", "Connecting to " + ssid + "...");
        } else {
            request->send(400, "text/plain", "Please provide both SSID and password.");
        }
    });

    server.begin();
}

void connectToWiFi(const String &ssid, const String &pass) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("Connected to WiFi");
    connectToMQTT();
}

void connectToMQTT() {
    mqttClient.setServer(mqttBroker, 1883);
    mqttClient.setCallback(mqttCallback);
    while (!mqttClient.connected()) {
        Serial.print("Attempting MQTT connection...");
        if (mqttClient.connect(deviceID.c_str())) {
            Serial.println("Connected to MQTT broker");
            mqttClient.subscribe(topic.c_str());
        } else {
            Serial.print("Failed, rc=");
            Serial.print(mqttClient.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}
void mqttCallback(char* topic, byte* payload, unsigned int length) {
    payload[length] = '\0';  // Ensure null-termination for proper string conversion
    String message = String((char*)payload);
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("]: ");
    Serial.println(message);

    // Parse the incoming message into LED number and state
    int separatorIndex = message.indexOf(':');
    if (separatorIndex == -1) {
        Serial.println("Invalid message format.");
        return;
    }

    int ledNumber = message.substring(0, separatorIndex).toInt();
    int ledState = message.substring(separatorIndex + 1).toInt();

    // Determine which LED to control
    int ledPin = -1;
    switch (ledNumber) {
        case 1:
            ledPin = LED1;
            break;
        case 2:
            ledPin = LED2;
            break;
        case 3:
            ledPin = LED3;
            break;
        case 4:
            ledPin = LED4;
            break;
        default:
            Serial.println("Invalid LED number.");
            return;
    }

    // Set the LED state
    digitalWrite(ledPin, ledState == 1 ? HIGH : LOW);
    Serial.print("LED ");
    Serial.print(ledNumber);
    Serial.print(" turned ");
    Serial.println(ledState == 1 ? "ON" : "OFF");
}

void setup() {
    Serial.begin(115200);
    pinMode(LED1, OUTPUT);
    pinMode(LED2, OUTPUT);
    pinMode(LED3, OUTPUT);
    pinMode(LED4, OUTPUT);
    setupWiFiAP();
    setupWebServer();
}

void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        if (!mqttClient.connected()) {
            connectToMQTT();
        }
        mqttClient.loop();
    }
}
