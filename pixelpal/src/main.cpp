#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <time.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define TOUCH_PIN 23   // TTP22 touch sensor input pin

const unsigned char wifi_icon [] PROGMEM = {
  0x1C, 0x00,
  0x22, 0x00,
  0x41, 0x00,
  0x94, 0x80,
  0x22, 0x40,
  0x41, 0x20,
  0x80, 0x10,
  0x00, 0x00
};

// ===== Mochi Face State =====
float faceLookOffset = 0.0;
float targetLookOffset = 0.0;
float currentBlink = 0.0;
float targetBlink = 0.0;
bool isSmiling = false;
unsigned long nextActionTime = 0;
unsigned long blinkEndTime = 0;
unsigned long nextBlinkTime = 0;

void drawDashaiFace(float lookOffset, float bobY, bool smiling, float blinkProgress) {
  int faceCenterX = 64;
  int faceCenterY = 32 + bobY;
  int baseEyeW = 20;
  int baseEyeH = 28;
  
  // Calculate eye height for blinking (smooth shrink)
  int currentEyeH = baseEyeH * (1.0 - blinkProgress);
  if (currentEyeH < 4) currentEyeH = 4; // Min height 4px to look like a line
  
  int eyeY = (faceCenterY - 14) + ((baseEyeH - currentEyeH) / 2);
  int leftEyeX = faceCenterX - 34;
  int rightEyeX = faceCenterX + 14;

  if (smiling) {
    // Smiling eyes (curved)
    int topBarY = eyeY;
    int legH = currentEyeH / 2;
    if (legH < 4) legH = 4;
    
    // Left eye
    display.fillRect(leftEyeX + lookOffset, topBarY, baseEyeW, 6, WHITE); 
    display.fillRect(leftEyeX + lookOffset, topBarY + 6, 6, legH, WHITE); 
    display.fillRect(leftEyeX + baseEyeW - 6 + lookOffset, topBarY + 6, 6, legH, WHITE); 
    // Right eye
    display.fillRect(rightEyeX + lookOffset, topBarY, baseEyeW, 6, WHITE);
    display.fillRect(rightEyeX + lookOffset, topBarY + 6, 6, legH, WHITE);
    display.fillRect(rightEyeX + baseEyeW - 6 + lookOffset, topBarY + 6, 6, legH, WHITE);
  } else {
    // Normal eyes
    int radius = currentEyeH / 4;
    if (radius > 6) radius = 6;
    display.fillRoundRect(leftEyeX + lookOffset, eyeY, baseEyeW, currentEyeH, radius, WHITE);
    display.fillRoundRect(rightEyeX + lookOffset, eyeY, baseEyeW, currentEyeH, radius, WHITE);
  }

  // Mouth (sways with face)
  int mouthY = faceCenterY + 18;
  if (smiling) {
    // Smiling mouth (U shape)
    display.fillRect(faceCenterX - 10 + lookOffset, mouthY + 4, 20, 4, WHITE); // bottom bar
    display.fillRect(faceCenterX - 14 + lookOffset, mouthY, 4, 8, WHITE); // left leg
    display.fillRect(faceCenterX + 10 + lookOffset, mouthY, 4, 8, WHITE); // right leg
  } else {
    // Normal small mouth
    display.fillRect(faceCenterX - 4 + lookOffset, mouthY, 8, 4, WHITE);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(TOUCH_PIN, INPUT);

  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.display();

  // Ready Screen
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(10, 25);
  display.print("Ready to use!");
  display.display();
  delay(1000);
}

void loop() {
  display.clearDisplay();

  // ===== Mochi Face Animation =====
    unsigned long currentMillis = millis();

    // 1. Blink Logic
    if (currentMillis >= nextBlinkTime) {
      targetBlink = 1.0; // Close eyes
      blinkEndTime = currentMillis + 100; // Hold closed for 100ms
      nextBlinkTime = currentMillis + random(2000, 6000); 
    }
    if (targetBlink > 0.5 && currentMillis >= blinkEndTime) {
      targetBlink = 0.0; // Open eyes
    }

    // 2. Expression & Look Direction Logic
    if (currentMillis >= nextActionTime) {
      int action = random(0, 5); // 0: center, 1: left, 2: right, 3: smile, 4: normal
      if (action == 0 || action == 4) {
        targetLookOffset = 0;
        isSmiling = false;
      } else if (action == 1) {
        targetLookOffset = -22;
        isSmiling = false;
      } else if (action == 2) {
        targetLookOffset = 22;
        isSmiling = false;
      } else if (action == 3) {
        targetLookOffset = 0;
        isSmiling = true;
      }
      nextActionTime = currentMillis + random(1500, 4000); // Change action every 1.5-4s
    }

    // 3. Easing & Interpolation (Fluid Motion)
    faceLookOffset += (targetLookOffset - faceLookOffset) * 0.15; // Smooth pan
    currentBlink += (targetBlink - currentBlink) * 0.3; // Fast but smooth blink

    // 4. Breathing Effect (Slow vertical bobbing)
    float bobY = sin(currentMillis / 400.0) * 2.0; 

    drawDashaiFace(faceLookOffset, bobY, isSmiling, currentBlink);

    display.display();
    delay(20);


}