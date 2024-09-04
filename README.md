# Smart Garden Project

## Project Overview

The Smart Garden project utilizes an ESP32 microcontroller connected to various sensors (soil moisture, light, temperature, and water level) to monitor garden conditions. Data collected by these sensors is sent to Firebase, where it is stored and processed. We have developed a Flutter application that allows users to:

- Monitor garden properties
- View statistics
- Control the watering system manually or automatically based on environmental factors
- Monitor plant health by uploading images of plants, which are analyzed using a deep learning model

## Team Members

- **Kelly Guderna**
- **Yakir Biton**
- **Alon Orian Dean**

## Project Structure

- **esp/**: Source code for the ESP32 microcontroller.
- **flutter/smart_garden/**: Flutter app code, written in Dart.
- **functions/**: Cloud functions for Firebase.
- **documentation/**: Additional documentation for setup, monitoring, and troubleshooting.
- **tests/**: Unit tests for the ESP32 code and other components of the project.

## Libraries and Versions

### ESP32 Libraries

- **Wire**: Standard library for I2C communication.
- **DHT**: Version 1.4.0 for interfacing with the DHT11 temperature and humidity sensor.
- **WiFi**: Standard library for WiFi communication.
- **HTTPClient**: Version 1.2.0 for sending HTTP requests.
- **ArduinoJson**: Version 6.18.5 for parsing and generating JSON data.

## Hardware List

| Item                                    | Quantity |
|-----------------------------------------|----------|
| Capacitive Soil Moisture Sensor v1.2    | 4        |
| DHT11 Temperature and Humidity Sensor   | 1        |
| Custom Power Distribution Unit (PDU)    | 1        |
| Light Sensor                             | 1        |
| ESP32 (30 pins)                         | 1        |
| Jumper Wires                            | 20+      |
| 5V 4-channel Relay Module                | 1        |
| Capacitive Water Level               | 1        |
| Water Pumps                             | 4        |

## Connection Diagram
![electrical diagram](https://github.com/user-attachments/assets/b3a0b57c-aa14-4a35-9b67-ce32c08bfb01)



## GitHub Repository Structure

- **esp/**: Contains the code for the ESP32 microcontroller.
- **flutter/smart_garden/**: The Flutter app providing the user interface for monitoring and controlling the garden.
- **functions/**: Contains Firebase Cloud Functions for data processing, controlling the watering system, and integrating with external APIs.

## Additional Files

- **Poster**: ![Poster](https://github.com/user-attachments/assets/a955e805-6278-41c9-8c50-790348a25ae5)
- ![image](https://github.com/user-attachments/assets/e6bcae2c-aad0-4df1-a17a-d646bebfecef)



