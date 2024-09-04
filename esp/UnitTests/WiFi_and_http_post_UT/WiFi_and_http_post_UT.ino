#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#define WIFI_SSID "ICST"
#define WIFI_PASSWORD "arduino123"


#define FIREBASE_URL "https://set-data-from-garden-rq6iz7nr2q-uc.a.run.app"  // URL for sending data to Firebase


void setup() {
  Wire.begin();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print(".");
  }
  Serial.println(" Connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  StaticJsonDocument<200> jsonDoc; // Adjust size as needed
  float temperature = dht.readTemperature();
  // JsonArray data = jsonDoc.createNestedArray("data");
  for (int i = 0; i < 4; i++) {
    JsonObject plant = jsonDoc.createNestedObject();
    // JsonObject plant = data.createNestedObject();
    switch (i) {//fabricated 4 different sensor values
      case 0: plant["water"] = 3500; break;
      case 1: plant["water"] = 3000; break;
      case 2: plant["water"] = 2500; break;
      case 3: plant["water"] = 2000; break;
    }
    plant["light"] = 4000;
    plant["temperature"] = 25;
  }
  delay(500);
  int waterTankRead = 50;
  String jsonString;
  serializeJson(jsonDoc, jsonString);
  jsonString = "{\"data\": " + jsonString + ", \"water_tank\": " + std::to_string(waterTankRead).c_str() + "}";
  HTTPClient http;
  http.begin(FIREBASE_URL);
  http.addHeader("Content-Type", "application/json");
  int httpResponseCode = http.POST(jsonString);
  if (httpResponseCode > 0) {
    String payload = http.getString();
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.print("Payload: ");
    Serial.println(payload);
  } else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  http.end();
}
