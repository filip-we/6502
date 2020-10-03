const int DATA_PINS[16] = {A0, A1, A2, A3, A4, A5, 2, 3, 4, 5, 6, 7, 8, 9};

const int SHIFT_DATA = 13;//SER, shift-reg pin 14
const int SHIFT_LATCH = 12;//RCLK, shift-reg pin 12
const int SHIFT_CLOCK = 11;//SRCLK, shift-reg pin 11

const byte segmentTable[16] = {
      B11101110,
      B00101000,
      B11001101,
      B01101101,
      B00101011,
      B01100111,
      B11100111,
      B00101100,
      B11101111,
      B01101111,
      B10101111,
      B11100011,
      B11000110,
      B11101001,
      B11000111,
      B10000111,
};

void setup()
{
  digitalWrite(SHIFT_DATA, LOW);
  digitalWrite(SHIFT_LATCH, HIGH);
  digitalWrite(SHIFT_CLOCK, LOW);
  pinMode(SHIFT_DATA, OUTPUT);
  pinMode(SHIFT_LATCH, OUTPUT);
  pinMode(SHIFT_CLOCK, OUTPUT);
    
  for (int i = 0; i < 8; i++)
  {
    digitalWrite(DATA_PINS[i], LOW);
    pinMode(DATA_PINS[i], INPUT);
  }
  setDisplay(segmentTable[10]);

}

void setDisplay(int data){
  digitalWrite(SHIFT_LATCH, LOW);
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, LSBFIRST, segmentTable[data >> 4]);
  shiftOut(SHIFT_DATA, SHIFT_CLOCK, LSBFIRST, segmentTable[data & 0x0f]);
  digitalWrite(SHIFT_LATCH, HIGH);
}

int readData(){
  int data = 0;
  for (int i = 15; i >= 0; i--)
  {
    data = (data << 1) + digitalRead(DATA_PINS[i]);
  }
  return data;
}

void loop() {
  //int data = readData();
  for (int i = 9; i < 35; i++){
    setDisplay(i);
    delay(600);
  }

}
