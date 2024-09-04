#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#define WIFI_SSID "ICST"
#define WIFI_PASSWORD "arduino123"


#define PUMP_COMMANDS_URL "https://get-pump-command-rq6iz7nr2q-uc.a.run.app" // URL to get pump commands


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
  delay(1000);
  http.begin(pumpCommendsUrl);
  httpResponseCode = http.GET();
  if (httpResponseCode > 0) {
  String payload = http.getString();
  Serial.print("HTTP Response code: ");
  Serial.println(httpResponseCode);
  Serial.print("Payload: ");
  Serial.println(payload);
  http.end();

  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, payload);

  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.f_str());
    return;
  }
  // Access the JSON data
  JsonArray plants = doc["array_pumps"].as<JsonArray>();
  Serial.print("pump 1 command: ");
  Serial.println(plants[0]);
  Serial.print("pump 2 command: ");
  Serial.println(plants[1]);
  Serial.print("pump 3 command: ");
  Serial.println(plants[2]);
  Serial.print("pump 4 command: ");
  Serial.println(plants[3]);
}
