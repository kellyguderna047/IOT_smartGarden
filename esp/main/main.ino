#include <Wire.h>
#include <DHT.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "SECRETS.h"
#include "parameters.h"

// Adafruit_ADS1115 ads;
DHT dht(DHTPIN, DHTTYPE);

int waterRawToPercent(int raw){
  int percent = 0;
  Serial.print("water level sensor:");
  Serial.println(raw);
  if(raw >= 25) return 0;
  if(raw >= 17) return 25;
  if(raw >= 12) return 50;
  if(raw >= 10) return 75;
  return 100;

}

void setup(void) {
  Serial.begin(115200);
  pinMode(PUMP_PIN_NO_1, OUTPUT);
  pinMode(PUMP_PIN_NO_2, OUTPUT);
  pinMode(PUMP_PIN_NO_3, OUTPUT);
  pinMode(PUMP_PIN_NO_4, OUTPUT);
  digitalWrite(PUMP_PIN_NO_1, HIGH);
  digitalWrite(PUMP_PIN_NO_2, HIGH);
  digitalWrite(PUMP_PIN_NO_3, HIGH);
  digitalWrite(PUMP_PIN_NO_4, HIGH);
  Wire.begin();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print(".");
  }
  Serial.println(" Connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  dht.begin();
}

void loop(void) {
  String stopPumpUrl = STOP_PUMP_URL;
  String pumpCommendsUrl = PUMP_COMMANDS_URL;
  String firebaseUrl = FIREBASE_URL;
  StaticJsonDocument<200> jsonDoc; // Adjust size as needed
  float temperature = dht.readTemperature();
  // JsonArray data = jsonDoc.createNestedArray("data");
  for (int i = 0; i < 4; i++) {
    JsonObject plant = jsonDoc.createNestedObject();
    // JsonObject plant = data.createNestedObject();
    switch (i) {
      case 0: plant["water"] = analogRead(MOISTURE_SENSOR_PIN_1); break;
      case 1: plant["water"] = analogRead(MOISTURE_SENSOR_PIN_2); break;
      case 2: plant["water"] = analogRead(MOISTURE_SENSOR_PIN_3); break;
      case 3: plant["water"] = analogRead(MOISTURE_SENSOR_PIN_4); break;
    }
    plant["light"] = analogRead(LIGHT_SENSOR_PIN);
    plant["temperature"] = temperature;
  }
  delay(500);
  int waterTankReadRaw = touchRead(WATER_LEVEL_PIN);
  int waterTankRead = waterRawToPercent(waterTankReadRaw);
  String jsonString;
  serializeJson(jsonDoc, jsonString);
  jsonString = "{\"data\": " + jsonString + ", \"water_tank\": " + std::to_string(waterTankRead).c_str() + "}";
  HTTPClient http;
  http.begin(firebaseUrl);
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

  http.begin(pumpCommendsUrl);
  httpResponseCode = http.GET();
  if (httpResponseCode > 0) {
    String payload = http.getString();
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.print("Payload: ");
    Serial.println(payload);
    // Create a DynamicJsonDocument to parse the JSON payload
    DynamicJsonDocument doc(1024); // Adjust size as needed
    DeserializationError error = deserializeJson(doc, payload);
    if (error) {
      Serial.print("deserializeJson() failed: ");
      Serial.println(error.f_str());
      return;
    }
    // Access the JSON data
    JsonArray plants = doc["array_pumps"].as<JsonArray>();
    if (plants[0]){
        digitalWrite(PUMP_PIN_NO_1, LOW);
    }
    if (plants[1]){
        digitalWrite(PUMP_PIN_NO_2, LOW);
    }
    if (plants[2]){
        digitalWrite(PUMP_PIN_NO_3, LOW);
    }
    if (plants[3]){
        digitalWrite(PUMP_PIN_NO_4, LOW);
    }
    delay(1000);
    if (plants[0]){
        digitalWrite(PUMP_PIN_NO_1, HIGH);
    }
    if (plants[1]){
        digitalWrite(PUMP_PIN_NO_2, HIGH);
    }
    if (plants[2]){
        digitalWrite(PUMP_PIN_NO_3, HIGH);
    }
    if (plants[3]){
        digitalWrite(PUMP_PIN_NO_4, HIGH);
    }
  } else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  http.end();


  http.begin(stopPumpUrl);
  httpResponseCode = http.POST("{}");
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

  delay(1000);
}

