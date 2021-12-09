#include <SPI.h>
#include <MFRC522.h>
#include <LiquidCrystal.h>

LiquidCrystal lcd(7, 6, 5, 4, 3, 2);

MFRC522 mfrc522(10, 9);

MFRC522::MIFARE_Key key;

void dump_byte_array(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}

bool read_from_card() {
  byte buffer[18];
  byte size = sizeof(buffer);
  MFRC522::StatusCode status = (MFRC522::StatusCode) mfrc522.MIFARE_Read(4, buffer, &size);
  if (status != MFRC522::STATUS_OK) {
    return false;
  }
  
  dump_byte_array(buffer, size);
  return true;
}

bool write_to_card() {
  byte buffer[16] = {};
  for (byte i = 0; i < 16; i++) {
    buffer[i] = random(0x0, 0xff);
  }
  
  MFRC522::StatusCode status = (MFRC522::StatusCode) mfrc522.MIFARE_Write(4, buffer, 16);
  if (status != MFRC522::STATUS_OK) {
    return false;
  }
  return true;
}

bool compare_cards(byte *buffer1, byte *buffer2, byte bufferSize){
  for (byte i = 0; i < bufferSize; i++) {
    if (buffer1[i] != buffer2[i]) {
      return false;
    }
  }
  return true;
}

void setup() {
  Serial.begin(9600);

  pinMode(A5, INPUT);

  lcd.begin(16, 2);
  
  SPI.begin();
  mfrc522.PCD_Init();

  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
}

void loop() {
  int button = digitalRead(A5);
  if (button == HIGH) {
    Serial.print("high");
  }
  else {
    Serial.print("low");
  }
  
  if ( ! mfrc522.PICC_IsNewCardPresent())
    return;

  if ( ! mfrc522.PICC_ReadCardSerial())
    return;

  Serial.print(F("Card UID:"));
  dump_byte_array(mfrc522.uid.uidByte, mfrc522.uid.size);
  Serial.println();

  MFRC522::StatusCode status = (MFRC522::StatusCode) mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, 7, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    Serial.println(mfrc522.GetStatusCodeName(status));
    return;
  }
  
//  read_from_card();
//  Serial.println();
//  write_to_card();
//  Serial.println();
//  read_from_card();
//  Serial.println();
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();

  delay(2000);
}
