#ifndef Filipro_h
#define Filipro_h

#include <Arduino.h>

//Protocol commands
const byte ABORT = 0x00;
const byte CONTINUE = 0x01;
const byte RESEND = 0x02;
const byte TEST = 0x03;

//Header: 4 (pclCmd) + 1 (anyData) + 1 (parity)
//Size: 7 (dataLength) + 1 (parity)
//Checksum: 7 + (parity)

//Initial response
const byte HANDSHAKE = 0x81;

class Filipro
{
    public:
        Filipro();
        void open(int);
        void write(byte, byte[], byte);
        void read(byte*, byte[], byte*);
        void readWrite(byte*, byte[], byte*, byte, byte[], byte);
    private:
        byte getParity(byte);
        byte checksum(byte[], byte);
};

#endif
