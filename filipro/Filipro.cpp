#include "Arduino.h"
#include "Filipro.h"

Filipro::Filipro()
{
}

void Filipro::open(int baudrate=9600)
{
  Serial.begin(baudrate);
  while(!Serial){};
  while (Serial.available() < 0){};
  Serial.read();
  Serial.write(HANDSHAKE);
}

byte Filipro::getParity(byte n)
{
  unsigned int count = 0;
  byte temp = n;
  while (temp >= 0x02){
    if (temp & 0x01 == 0x01){
      count++;
    }
    temp = temp >> 0x01;
  }
  return (byte) count % 2;
}

byte Filipro::checksum(byte data[], byte dataLen)
{
  int cksm = 0;
  for (int i = 0; i < (unsigned int) dataLen; i++){
    cksm = cksm + (unsigned int) data[i];
  }
  return (byte) (cksm & 127);
}

void Filipro::write(byte pclCmd, byte data[], byte dataLen)
{
  byte header = (pclCmd << 0x01) + ((dataLen > 0x00) ? 0x01 : 0x00);
  Serial.write((header << 0x01) + getParity(header));
  if (dataLen > 0x00){
    Serial.write((dataLen << 0x01) + getParity(dataLen));
    byte cksm = checksum(data, dataLen);
    Serial.write((cksm << 0x01) +  getParity(cksm));
    Serial.write(data, (unsigned int) dataLen);
  }
}

void Filipro::read(byte *pclCmd, byte data[], byte *dataLen)
{
  byte msg[1];
  Serial.readBytes(msg, 1);
  pclCmd[0] = (msg[0] >> 0x02) & 0xff;
  bool anyData = ((msg[0] >> 0x01) & 0x01) == 0x01 ? true: false;
  if (anyData)
  {
    Serial.readBytes(dataLen, 1);
    dataLen[0] = (dataLen[0] >> 0x01);
    byte cksm[1];
    Serial.readBytes(cksm, 1);
    Serial.readBytes(data, (unsigned int) dataLen);
  }
  else
  {
    dataLen[0] = 0x00;
  }
}

void Filipro::readWrite(
            byte *readCmd,
            byte readData[],
            byte *readDataLen,
            byte writeCmd,
            byte writeData[],
            byte writeDataLen)
{
    read(readCmd, readData, readDataLen);
    write(writeCmd, writeData, writeDataLen);
}
