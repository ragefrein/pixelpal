#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <time.h>
#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define TOUCH_PIN 23 // TTP22 touch sensor input pin

// ===== WiFi & BLE Setup =====
const char *ssid = "PixelPal_ESP32";
const char *password = "pixelpal_pass"; // For WiFi AP
WebServer server(80);

// ===== Mochi Face State =====
float faceLookOffset = 0.0;
float targetLookOffset = 0.0;
float currentBlink = 0.0;
float targetBlink = 0.0;
bool isSmiling = false;
unsigned long nextActionTime = 0;
unsigned long blinkEndTime = 0;
unsigned long nextBlinkTime = 0;
bool isAutoMode = true; // True if random, False if controlled by Mobile App
bool isBootScreen = true; // Keep IP on screen until a command is received
bool isInfoMode = false;
String currentWeather = "Loading...";
unsigned long lastWeatherUpdate = 0;
bool lastTouchState = LOW;
unsigned long lastTouchTime = 0;

void handleCommand(String cmd)
{
  cmd.trim();
  isBootScreen = false; // Hide IP and start face animation on any command
  
  if (cmd.startsWith("wifi:")) {
    // Expected format: "wifi:SSID:PASSWORD"
    int firstColon = cmd.indexOf(':');
    int secondColon = cmd.indexOf(':', firstColon + 1);
    if (firstColon != -1 && secondColon != -1) {
      String newSsid = cmd.substring(firstColon + 1, secondColon);
      String newPass = cmd.substring(secondColon + 1);
      
      display.clearDisplay();
      display.setCursor(0, 10);
      display.println("Connecting to WiFi:");
      display.println(newSsid);
      display.display();

      WiFi.mode(WIFI_AP_STA); // Keep AP alive but also connect to Station
      WiFi.begin(newSsid.c_str(), newPass.c_str());
      
      int attempts = 0;
      while (WiFi.status() != WL_CONNECTED && attempts < 15) {
        delay(500);
        attempts++;
      }
      
      display.clearDisplay();
      display.setCursor(0, 10);
      if(WiFi.status() == WL_CONNECTED) {
        display.println("WiFi Connected!");
        display.println(WiFi.localIP());
        isBootScreen = true; // Keep the IP on screen until next command
      } else {
        display.println("WiFi Failed!");
        delay(3000); // Only delay if failed, then return to normal
      }
      display.display();
    }
    return;
  }

  isAutoMode = false; // Override auto mode when command received

  if (cmd == "smile")
  {
    isSmiling = true;
    targetLookOffset = 0;
  }
  else if (cmd == "normal")
  {
    isSmiling = false;
    targetLookOffset = 0;
  }
  else if (cmd == "left")
  {
    isSmiling = false;
    targetLookOffset = -22;
  }
  else if (cmd == "right")
  {
    isSmiling = false;
    targetLookOffset = 22;
  }
  else if (cmd == "info")
  {
    isInfoMode = true;
  }
  else if (cmd == "face")
  {
    isInfoMode = false;
  }
  else if (cmd == "blink")
  {
    targetBlink = 1.0;
    blinkEndTime = millis() + 150;
  }
  else if (cmd == "auto")
  {
    isAutoMode = true;
  }
}

void handleRoot()
{
  server.send(200, "text/plain", "PixelPal is ready!");
}

void handleApi()
{
  if (server.hasArg("cmd"))
  {
    String cmd = server.arg("cmd");
    handleCommand(cmd);
    server.send(200, "text/plain", "Command executed: " + cmd);
  }
  else
  {
    server.send(400, "text/plain", "Missing cmd argument");
  }
}

void drawDashaiFace(float lookOffset, float bobY, bool smiling, float blinkProgress)
{
  int faceCenterX = 64;
  int faceCenterY = 32 + bobY;
  int baseEyeW = 20;
  int baseEyeH = 28;

  int currentEyeH = baseEyeH * (1.0 - blinkProgress);
  if (currentEyeH < 4)
    currentEyeH = 4;

  int eyeY = (faceCenterY - 14) + ((baseEyeH - currentEyeH) / 2);
  int leftEyeX = faceCenterX - 34;
  int rightEyeX = faceCenterX + 14;

  if (smiling)
  {
    int topBarY = eyeY;
    int legH = currentEyeH / 2;
    if (legH < 4)
      legH = 4;
    display.fillRect(leftEyeX + lookOffset, topBarY, baseEyeW, 6, WHITE);
    display.fillRect(leftEyeX + lookOffset, topBarY + 6, 6, legH, WHITE);
    display.fillRect(leftEyeX + baseEyeW - 6 + lookOffset, topBarY + 6, 6, legH, WHITE);
    display.fillRect(rightEyeX + lookOffset, topBarY, baseEyeW, 6, WHITE);
    display.fillRect(rightEyeX + lookOffset, topBarY + 6, 6, legH, WHITE);
    display.fillRect(rightEyeX + baseEyeW - 6 + lookOffset, topBarY + 6, 6, legH, WHITE);
  }
  else
  {
    int radius = currentEyeH / 4;
    if (radius > 6)
      radius = 6;
    display.fillRoundRect(leftEyeX + lookOffset, eyeY, baseEyeW, currentEyeH, radius, WHITE);
    display.fillRoundRect(rightEyeX + lookOffset, eyeY, baseEyeW, currentEyeH, radius, WHITE);
  }

  int mouthY = faceCenterY + 18;
  if (smiling)
  {
    display.fillRect(faceCenterX - 10 + lookOffset, mouthY + 4, 20, 4, WHITE);
    display.fillRect(faceCenterX - 14 + lookOffset, mouthY, 4, 8, WHITE);
    display.fillRect(faceCenterX + 10 + lookOffset, mouthY, 4, 8, WHITE);
  }
  else
  {
    display.fillRect(faceCenterX - 4 + lookOffset, mouthY, 8, 4, WHITE);
  }
}

void updateWeather() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin("http://wttr.in/?format=%t+%C");
    http.setUserAgent("curl/7.68.0");
    int httpCode = http.GET();
    if (httpCode > 0) {
      currentWeather = http.getString();
      currentWeather.trim();
    }
    http.end();
  } else {
    currentWeather = "No WiFi";
  }
}

void drawInfoMode(unsigned long currentMillis) {
  if (currentWeather == "Loading..." || (currentMillis - lastWeatherUpdate > 1800000)) { // 30 mins
    updateWeather();
    lastWeatherUpdate = currentMillis;
  }

  struct tm timeinfo;
  if (!getLocalTime(&timeinfo, 50)) {
    display.setTextSize(1);
    display.setCursor(0, 20);
    display.println("Syncing Time...");
    return;
  }

  char timeStr[10];
  strftime(timeStr, sizeof(timeStr), "%H:%M", &timeinfo); // Just hours and minutes is nicer
  
  char dayStr[10];
  strftime(dayStr, sizeof(dayStr), "%A", &timeinfo);
  
  char dateStr[20];
  strftime(dateStr, sizeof(dateStr), "%d %b %Y", &timeinfo);

  display.setTextSize(3);
  int16_t x1, y1;
  uint16_t w, h;
  display.getTextBounds(timeStr, 0, 0, &x1, &y1, &w, &h);
  display.setCursor((128 - w) / 2, 5);
  display.println(timeStr);

  display.setTextSize(1);
  display.setCursor(0, 35);
  display.print(dayStr);
  display.print(", ");
  display.println(dateStr);

  display.setCursor(0, 50);
  display.print("Weather: ");
  display.println(currentWeather);
}

void setup()
{
  Serial.begin(115200);
  pinMode(TOUCH_PIN, INPUT);

  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();

  // Show init screen
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 25);
  display.println("Starting PixelPal...");
  display.display();

  // Setup WiFi AP
  WiFi.softAP(ssid, password);
  server.on("/", handleRoot);
  server.on("/api", handleApi);
  server.begin();

  // Setup NTP
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // GMT+7

  display.clearDisplay();
  display.setCursor(0, 10);
  display.println("PixelPal Ready!");
  display.print("AP IP: ");
  display.println(WiFi.softAPIP());
  display.display();
}

void loop()
{
  server.handleClient(); // Handle WiFi HTTP requests
  unsigned long currentMillis = millis();

  // Touch Handling
  bool touchState = digitalRead(TOUCH_PIN);
  if (touchState == HIGH && lastTouchState == LOW && (currentMillis - lastTouchTime > 500)) {
    isInfoMode = !isInfoMode;
    isBootScreen = false;
    lastTouchTime = currentMillis;
  }
  lastTouchState = touchState;

  if (isBootScreen) {
    return; // Don't clear display until a command/touch is received
  }

  display.clearDisplay();

  if (isInfoMode) {
    drawInfoMode(currentMillis);
  } else {
    // 1. Blink Logic (always runs so it looks alive even when controlled)
    if (currentMillis >= nextBlinkTime)
  {
    targetBlink = 1.0;
    blinkEndTime = currentMillis + 100;
    nextBlinkTime = currentMillis + random(2000, 6000);
  }
  if (targetBlink > 0.5 && currentMillis >= blinkEndTime)
  {
    targetBlink = 0.0;
  }

  // 2. Expression & Look Direction Logic (Auto Mode)
  if (isAutoMode && currentMillis >= nextActionTime)
  {
    int action = random(0, 5);
    if (action == 0 || action == 4)
    {
      targetLookOffset = 0;
      isSmiling = false;
    }
    else if (action == 1)
    {
      targetLookOffset = -22;
      isSmiling = false;
    }
    else if (action == 2)
    {
      targetLookOffset = 22;
      isSmiling = false;
    }
    else if (action == 3)
    {
      targetLookOffset = 0;
      isSmiling = true;
    }
    nextActionTime = currentMillis + random(1500, 4000);
  }

  // 3. Easing & Interpolation
  faceLookOffset += (targetLookOffset - faceLookOffset) * 0.15;
  currentBlink += (targetBlink - currentBlink) * 0.3;

  // 4. Breathing Effect
  float bobY = sin(currentMillis / 400.0) * 2.0;

    drawDashaiFace(faceLookOffset, bobY, isSmiling, currentBlink);

    // Optional: Show tiny indicator if not auto
    if (!isAutoMode)
    {
      display.fillRect(124, 0, 4, 4, WHITE);
    }
  }

  display.display();
  delay(20);
}