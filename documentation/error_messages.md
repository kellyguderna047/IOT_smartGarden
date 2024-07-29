# Smart Garden: Error Messages

## Common Errors and Solutions

### 1. **WiFi Connection Error**
- **Message**: `Connecting to WiFi...`
- **Solution**: Ensure the correct SSID and password are entered in the ESP32 code. Check that the Wi-Fi network is available and that the      ESP32 is within range.

### 2. **DHT Sensor Reading Error**
- **Message**: `Failed to read from DHT sensor!`
- **Solution**: Verify the sensor connection and ensure it is powered correctly. Check if the sensor is functional by testing it with another microcontroller.

### 3. **HTTP Request Failure**
- **Message**: `HTTP Response code: <Error Code>`
- **Solution**: Ensure the ESP32 is connected to the internet. Check the endpoint URLs in the code. Verify that the Firebase functions are deployed and accessible.
