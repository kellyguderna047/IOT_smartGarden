## Setting Up the System
1. **ESP32 Setup**:
    - Connect the ESP32 to your computer via USB.
    - Flash the ESP32 with the code in the `esp/` directory.
    - Ensure the ESP32 is connected to the correct sensors and actuators as per the connection diagram, which you can view in the README file.

2. **Flutter App Setup**:
    - Install Flutter on your development machine.
    - Navigate to the `flutter/smart_garden/` directory.
    - Run `flutter pub get` to install dependencies.
    - Connect your mobile device or emulator and run `flutter run`.

3. **Firebase Setup**:
    - Deploy the cloud functions in the `functions/` directory to your Firebase project.
    - Ensure the Firebase project is linked to your Flutter app.

## Monitoring the Garden
- Use the Flutter app to monitor soil moisture, light, temperature, and water levels.
- Access real-time data and historical statistics.
- Use the app's manual control feature to water plants or switch to automatic mode.
- Upload images of plants through the app to check their health using a deep learning model.

## Troubleshooting
- If the ESP32 fails to connect to Wi-Fi, check the credentials in the code.
- Ensure all sensors are properly connected and functional.
- Refer to the [Error Messages](error_messages.md) document for specific error codes.
