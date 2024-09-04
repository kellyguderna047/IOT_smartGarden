#define LIGHT_SENSOR_PIN 36

int light_sensor_reading;
void setup() {
  Serial.begin(115200);

}

void loop() {
  light_sensor_reading = analogRead(LIGHT_SENSOR_PIN);

  Serial.print("light sensor value (raw): ");
  Serial.println(light_sensor_reading);

  delay(10);
}
