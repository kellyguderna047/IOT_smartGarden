#ifndef PARAMETERS_H
#define PARAMETERS_H

// WiFi Credentials
#define WIFI_CHANNEL 6             // WiFi Channel

// Sensor Pins
#define LIGHT_SENSOR_PIN 36        // Pin connected to the light sensor
#define DHTPIN 23                  // Pin connected to the DHT11 sensor
#define WATER_LEVEL_PIN T8         // Pin used for the water level sensor

// Moisture Sensor Pins
#define MOISTURE_SENSOR_PIN_1 32   // Analog pin connected to the first moisture sensor
#define MOISTURE_SENSOR_PIN_2 39   // Analog pin connected to the second moisture sensor
#define MOISTURE_SENSOR_PIN_3 34   // Analog pin connected to the third moisture sensor
#define MOISTURE_SENSOR_PIN_4 35   // Analog pin connected to the fourth moisture sensor

// Pump Control Pins
#define PUMP_PIN_NO_1 16           // Pin controlling the first water pump
#define PUMP_PIN_NO_2 17           // Pin controlling the second water pump
#define PUMP_PIN_NO_3 18           // Pin controlling the third water pump
#define PUMP_PIN_NO_4 19           // Pin controlling the fourth water pump

// DHT Sensor Type
#define DHTTYPE DHT11              // DHT11 sensor type

// URLs for Server Communication
#define STOP_PUMP_URL "https://stop-pump-rq6iz7nr2q-uc.a.run.app"           // URL to stop the pump
#define PUMP_COMMANDS_URL "https://get-pump-command-rq6iz7nr2q-uc.a.run.app" // URL to get pump commands
#define FIREBASE_URL "https://set-data-from-garden-rq6iz7nr2q-uc.a.run.app"  // URL for sending data to Firebase

#endif // PARAMETERS_H
