#include <SPI.h>
#include <MFRC522.h>
#include <LiquidCrystal.h>

LiquidCrystal lcd(7, 6, 5, 4, 3, 2);

MFRC522 mfrc522(10, 9);

MFRC522::MIFARE_Key key;

String card_uid[10] = {""};

String last_card_data[10] = {""};
String card_data[10] = {""};

int current_card_index = 0;

void dump_byte_array(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}

String card_buffer_to_string(byte *buffer, byte bufferSize) {
  String ret = "";
  for (byte i = 0; i < bufferSize; i++) {
    ret.concat(String(buffer[i] < 0x10 ? " 0" : " "));
    ret.concat(String(buffer[i], HEX));
  }
  return ret;
}

bool read_from_card(byte *buffer, byte size) {
  MFRC522::StatusCode status = (MFRC522::StatusCode) mfrc522.MIFARE_Read(4, buffer, &size);
  if (status != MFRC522::STATUS_OK) {
    return false;
  }
  
  //dump_byte_array(buffer, size);
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

bool store_card(String uid, String data) {
  for(int i = 0; i < 10; i++) {
    if (card_uid[i] == "") {
      card_uid[i] = uid;
      card_data[i] = data;
      return true;
    }
  }
  return false;
}

bool update_card_data(String uid, String data) {
  for (int i = 0; i < 10; i++) {
    if (card_uid[i] == uid) {
      card_data[i] = data;
      return true; 
    }
  }
  return false;
}

bool is_card_stored(String uid) {
  for(int i = 0; i < 10; i++) {
    if (card_uid[i] == uid) {
      return true;
    }
  }
  return false;
}

bool is_card_data_updated() {
  for (int i = 0; i < 10; i++) {
    if (card_data[i] != last_card_data[i]) {
      for (int j = 0; j < 10; j++) {
        last_card_data[j] = card_data[j];
      }
      
      return true;
    }
  }
  
  return false;
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
    current_card_index++;
    if (current_card_index >= 10) {
      current_card_index = 0;
    }
    lcd.clear();
    Serial.println(current_card_index);
    delay(500);
  }
  
  if (card_uid[0] == "") {
    lcd.setCursor(0, 0);
    lcd.print("0 cards stored.");
  }
  else {
    if (is_card_data_updated()) {
      Serial.println("hit");
      lcd.clear(); 
    }
    if (card_uid[current_card_index] == "") {
      lcd.setCursor(0, 0);
      lcd.print("Card ");
      lcd.print(current_card_index + 1);
      lcd.print(" empty.");
    }
    else {
      lcd.setCursor(0, 0);
      lcd.print(card_uid[current_card_index]);

      lcd.setCursor(0, 1);
      lcd.print(card_data[current_card_index].substring(0, 20)); 
    }
//    delay(500);
  }
  
  if ( ! mfrc522.PICC_IsNewCardPresent())
    return;

  if ( ! mfrc522.PICC_ReadCardSerial())
    return;

  Serial.print(F("Card UID:"));
//  dump_byte_array(mfrc522.uid.uidByte, mfrc522.uid.size);
//  Serial.println();
  String card_uid = card_buffer_to_string(mfrc522.uid.uidByte, mfrc522.uid.size);
  Serial.println(card_uid);

  MFRC522::StatusCode status = (MFRC522::StatusCode) mfrc522.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, 7, &key, &(mfrc522.uid));
  if (status != MFRC522::STATUS_OK) {
    Serial.println(mfrc522.GetStatusCodeName(status));
    return;
  }

  byte card_data_buffer[18];
  byte card_data_size = 18;
  read_from_card(card_data_buffer, card_data_size);
  String card_data = card_buffer_to_string(card_data_buffer, card_data_size);
  Serial.print("Card data: ");
  Serial.println(card_data);
  Serial.println();

  if (!is_card_stored(card_uid)) {
    store_card(card_uid, card_data);
  }
  
  
//  read_from_card();
//  Serial.println();
//  write_to_card();
//  Serial.println();
//  read_from_card();
//  Serial.println();
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();

//  delay(2000);
}
