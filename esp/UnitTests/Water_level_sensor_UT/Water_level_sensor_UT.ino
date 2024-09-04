
// the raw readings are not acting linearly and hence needs special mapping function.
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

void setup() {
  Serial.begin(115200);
}

// The water level sensor is built like a wire capacitore and act like a capacitive sensor
void loop() {
  int waterTankReadRaw = touchRead(WATER_LEVEL_PIN);
  int waterTankRead = waterRawToPercent(waterTankReadRaw);

  Serial.print("Water tank level at: ");
  Serial.print(waterTankRead);
  Serial.println("%");

  delay(100);
}
