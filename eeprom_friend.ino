#include <Filipro.h>
const int SHIFT_DATA = 2;
const int SHIFT_LATCH = 3;//RCLK, chip pin 12
const int SHIFT_CLOCK = 4;//SRCLK, chip pin 11

const int WRITE_ENABLE = 5;
const int EEPROM_START = 6;
const int EEPROM_END = 13;
const int baudrate = 19200;//28800;

const byte ABORT_CMD = 0x00;
const byte CONTINUE_CMD = 0x01;
const byte READ_EEPROM_CMD = 0x05;
const byte WRITE_EEPROM_CMD = 0x06;
const byte SPECIAL = 0x07;
Filipro fp = Filipro();
byte cmd;
byte data[255];
byte dataLen;

void setIOPinsOutput()
{
  for (int i = EEPROM_START; i <= EEPROM_END; i++)
  {
    pinMode(i, OUTPUT);
  }
  delay(10);
}

void setIOPinsInput()
{
  for (int i = EEPROM_START; i <= EEPROM_END; i++)
  {
    pinMode(i, INPUT);
  }
  delay(10);
}

void setAddress(int address, bool outputEnable){
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, MSBFIRST, (address >> 8) | (outputEnable ? 0x00 : 0x80));
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, MSBFIRST, address);
  digitalWrite(SHIFT_LATCH, HIGH);
  digitalWrite(SHIFT_LATCH, LOW);
}

byte readEepromAddress(int address){
  setAddress(address, true);
  byte data = 0;
  for (int i = EEPROM_END; i >= EEPROM_START; i--){
    data = (data << 1) + digitalRead(i);
  }
  return data;
}

void writeEepromAddress(int address, byte data)
{
  setAddress(address, false);
  for (int i = EEPROM_START; i <= EEPROM_END; i++){
    digitalWrite(i, (data & 1));
    data = data >> 1;
  }
  delay(10);
  //Adapted to inverted signal
  digitalWrite(WRITE_ENABLE, HIGH);
  delayMicroseconds(1);
  digitalWrite(WRITE_ENABLE, LOW);
  delay(10);
}

void writeEeprom()
{
  setIOPinsOutput();
  int startAddress = (unsigned int) (data[0] << 0x08) + data[1];
  int stopAddress = (unsigned int) (data[2] << 0x08) + data[3];  
  fp.write(WRITE_EEPROM_CMD, data, 4);
  for (int i = startAddress; i <= stopAddress; i = i + 16)
  {
    fp.readWrite(&cmd, &data[0], &dataLen, CONTINUE, data, 0);
    if (cmd != CONTINUE)
    {
      return;
    }
    cmd = ABORT_CMD;
    for (int address = i; address < (i + 16); address++)
    {
      writeEepromAddress(address, data[address - i]);
    }
  }
  fp.readWrite(&cmd, &data[0], &dataLen, ABORT_CMD, data, 0);
}

void writeEepromAddressCmd()
{
  setIOPinsOutput();
  fp.write(SPECIAL, data, 0);
  unsigned int address = (unsigned int) ((data[0] << 0x08) + data[1]);
  writeEepromAddress(address, data[2]);
  byte sendData[1];
  setIOPinsInput();
  sendData[0] = readEepromAddress(address);
  fp.readWrite(&cmd, &data[0], &dataLen,
      ABORT_CMD, sendData, 1);
}

void readEeprom()
{
  setIOPinsInput();
  int startAddress = (unsigned int) (data[0] << 0x08) + data[1];
  int stopAddress = (unsigned int) (data[2] << 0x08) + data[3];
  byte sendData[16];
  fp.write(READ_EEPROM_CMD, data, 4);
  for (int i = startAddress; i <= stopAddress; i = i + 16)
  {
      for (int address = i; address < (i + 16); address++){
        sendData[address - i] = readEepromAddress(address);
      }
    cmd = ABORT_CMD;
    fp.readWrite(&cmd, &data[0], &dataLen, READ_EEPROM_CMD, sendData, 16);
    if (cmd == ABORT_CMD)
    {
      fp.readWrite(&cmd, &data[0], &dataLen, ABORT_CMD, sendData, 0);
      break;
    }
  }
}

void setup()
{
  digitalWrite(SHIFT_DATA, LOW);
  digitalWrite(SHIFT_CLOCK, LOW);
  digitalWrite(SHIFT_LATCH, LOW);//Direct
  digitalWrite(WRITE_ENABLE, LOW);//Inverted
  
  pinMode(SHIFT_DATA, OUTPUT);
  pinMode(SHIFT_CLOCK, OUTPUT);
  pinMode(SHIFT_LATCH, OUTPUT);
  pinMode(WRITE_ENABLE, OUTPUT);
  
  for (int i = EEPROM_START; i <= EEPROM_END; i++)
  {
    digitalWrite(i, LOW);
    pinMode(i, INPUT);
  }

  fp.open(baudrate);
}

void loop() {
  while(Serial.available() < 1);
  fp.read(&cmd, &data[0], &dataLen);

  switch (cmd) {
  case READ_EEPROM_CMD:
    readEeprom();
    break;
  case WRITE_EEPROM_CMD:
    writeEeprom();
    break;
  case SPECIAL:
    writeEepromAddressCmd();
    break;
  default:
    fp.write(cmd, data, dataLen);
    break;
  }
}
