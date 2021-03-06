#include <Filipro.h>
const int DATA_PINS[8] = {2, 3, 4, 5, 6, 7, 8, 9};

const int WRITE_ENABLE = A0;//WE, eeprom pin 27
const int OUTPUT_ENABLE = A1;//OE, eeprom pin 22
const int CHIP_ENABLE = A2;//CE, eeprom pin 20
const int SHIFT_DATA = A3;//SER, shift-reg pin 14
const int SHIFT_LATCH = A4;//RCLK, shift-reg pin 12
const int SHIFT_CLOCK = A5;//SRCLK, shift-reg pin 11

const int baudrate = 19200;//28800;

const byte ABORT_CMD = 0x00;
const byte CONTINUE_CMD = 0x01;
const byte READ_EEPROM_CMD = 0x05;
const byte WRITE_EEPROM_CMD = 0x06;
const byte WRITE_EEPROM_ADDRESS = 0x07;
Filipro fp = Filipro();
byte cmd;
byte data[255];
byte dataLen;

void setIOPins(int mode)
{
  for (unsigned int i = 0; i < 8; i++)
  {
    pinMode(DATA_PINS[i], mode);
  }
  delay(10);
}

void setAddress(int address){
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, MSBFIRST, (address >> 8));
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, MSBFIRST, address);
  digitalWrite(SHIFT_LATCH, HIGH);
  digitalWrite(SHIFT_LATCH, LOW);
}

byte readEepromAddress(int address){
  setAddress(address);
  digitalWrite(OUTPUT_ENABLE, LOW);
  byte data = 0;
  for (int i = 7; i >= 0; i--)
  {
    data = (data << 1) + digitalRead(DATA_PINS[i]);
  }
  digitalWrite(OUTPUT_ENABLE, HIGH);
  return data;
}

void writeEepromAddress(int address, byte data)
{
  setAddress(address);
  for (int i = 0; i < 8; i++)
  {
    digitalWrite(DATA_PINS[i], (data & 1));
    data = data >> 1;
  }
  delay(5);
  digitalWrite(WRITE_ENABLE, LOW);
  delayMicroseconds(1);
  digitalWrite(WRITE_ENABLE, HIGH);
  delay(5);
}

void writeEeprom()
{  
  setIOPins(OUTPUT);
  int startAddress = (unsigned int) (data[0] << 0x08) + data[1];
  int stopAddress = (unsigned int) (data[2] << 0x08) + data[3];
  int address;
  int writeDataLen = stopAddress - startAddress;
  fp.write(WRITE_EEPROM_CMD, data, 0);

  for (address = startAddress; address < (writeDataLen / 16) * 16; address += 16)
  {
    fp.readWrite(&cmd, &data[0], &dataLen, CONTINUE_CMD, data, 0);
    for (int i = address; i < (address + 16); i++)
    {
      writeEepromAddress(i, data[i - address]);
    }
  }
  if (stopAddress % 16)
  {
    fp.readWrite(&cmd, &data[0], &dataLen, CONTINUE_CMD, data, 0);  
    for (int j = address; j < stopAddress; j++)
      {
        writeEepromAddress(j, data[j - address]);
      }
  }
  fp.readWrite(&cmd, &data[0], &dataLen, ABORT_CMD, data, 0);
}
void pageWrite()
{
  //First two bytes of message is the address. Next 16 bytes are the data.
  setIOPins(OUTPUT);
  int address = (unsigned int) (data[0] << 0x08) + data[1];
  for (int i = address; i < (address + 16); i++)
  {
    writeEepromAddress(i, data[i + 2 - address]);
  }
  fp.write(WRITE_EEPROM_ADDRESS, data, 0);
}

void writeEepromAddressCmd()
{
  setIOPins(OUTPUT);
  fp.write(WRITE_EEPROM_ADDRESS, data, 0);
  unsigned int address = (unsigned int) ((data[0] << 0x08) + data[1]);
  writeEepromAddress(address, data[2]);
  byte sendData[1];
  setIOPins(INPUT);
  sendData[0] = readEepromAddress(address);
  fp.readWrite(&cmd, &data[0], &dataLen,
      ABORT_CMD, sendData, 1);
}

void readEeprom()
{
  setIOPins(INPUT);
  int startAddress = (unsigned int) (data[0] << 0x08) + data[1];
  int stopAddress = (unsigned int) (data[2] << 0x08) + data[3];
  byte sendData[16];
  fp.readWrite(&cmd, &data[0], &dataLen, READ_EEPROM_CMD, data, 0);
  for (int i = startAddress; i <= stopAddress; i = i + 16)
  {
    fp.read(&cmd, &data[0], &dataLen);
    if (cmd == ABORT_CMD)
    {
      fp.write(ABORT_CMD, data, 0);
      break;
    }
    else
    {
      for (int address = i; address < (i + 16); address++){
        sendData[address - i] = readEepromAddress(address);
      }
      fp.write(CONTINUE, sendData, 16);
    }
  }
}

void setup()
{
  digitalWrite(WRITE_ENABLE, HIGH);
  digitalWrite(OUTPUT_ENABLE, HIGH);
  digitalWrite(CHIP_ENABLE, LOW);
  digitalWrite(SHIFT_DATA, LOW);
  digitalWrite(SHIFT_LATCH, LOW);
  digitalWrite(SHIFT_CLOCK, LOW);
  
  pinMode(WRITE_ENABLE, OUTPUT);
  pinMode(OUTPUT_ENABLE, OUTPUT);
  pinMode(CHIP_ENABLE, OUTPUT);
  pinMode(SHIFT_DATA, OUTPUT);
  pinMode(SHIFT_LATCH, OUTPUT);
  pinMode(SHIFT_CLOCK, OUTPUT);
    
  for (int i = 0; i < 8; i++)
  {
    digitalWrite(DATA_PINS[i], LOW);
    pinMode(DATA_PINS[i], INPUT);
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
  case WRITE_EEPROM_ADDRESS:
    //writeEepromAddressCmd();
    pageWrite();
    break;
  default:
    fp.write(ABORT, data, dataLen);
    break;
  }
}
