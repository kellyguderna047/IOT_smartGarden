
#define MOISTURE_SENSOR_PIN_1 32        // Analog pin connected to the first moisture sensor
#define MOISTURE_SENSOR_PIN_2 39        // Analog pin connected to the second moisture sensor
#define MOISTURE_SENSOR_PIN_3 34        // Analog pin connected to the third moisture sensor
#define MOISTURE_SENSOR_PIN_4 35        // Analog pin connected to the fourth moisture sensor

int sensor_reading = 0;


void setup(void) {
  Serial.begin(115200);
}

void loop(void) {
  sensor_reading = analogRead(MOISTURE_SENSOR_PIN_1);
  Serial.print("moisture sensor #1: ");
  Serial.println(sensor_reading);
  sensor_reading = analogRead(MOISTURE_SENSOR_PIN_2);
  Serial.print("moisture sensor #1: ");
  Serial.println(sensor_reading);
  sensor_reading = analogRead(MOISTURE_SENSOR_PIN_3);
  Serial.print("moisture sensor #1: ");
  Serial.println(sensor_reading);
  sensor_reading = analogRead(MOISTURE_SENSOR_PIN_4);
  Serial.print("moisture sensor #1: ");
  Serial.println(sensor_reading);
  delay(100);
}