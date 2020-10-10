#define CLOCK 2
#define READ_WRITE 3

//Reading only address
const char ADDR[] = {A0, A1, A2, A3, A4, A5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
const unsigned int addrLen = 16;
const char DATA[] = {};
const unsigned int dataLen = 0;

//Reading both data and address
//const char DATA[] = {5, 4, A5, A4, A3, A2, A1, A0};
//const char ADDR[] = {13, 12, 11, 10, 9, 8, 7, 6};

void setup() {
  for (int n = 0; n < addrLen; n += 1) {
    pinMode(ADDR[n], INPUT);
  }
  for (int n = 0; n < dataLen; n += 1) {
    pinMode(DATA[n], INPUT);
  }
  pinMode(CLOCK, INPUT);
  pinMode(READ_WRITE, INPUT);

  attachInterrupt(digitalPinToInterrupt(CLOCK), onClock, FALLING);
  
  //Serial.begin(57600);
  Serial.begin(19200);
}

void onClock() {
  char rwStr[8];
  char addressStr[32];
  char dataStr[15];
  char output[15];

  sprintf(rwStr, "%s ADDR ", digitalRead(READ_WRITE) ? "READ:  " : "WRITE: ");
  Serial.print(rwStr);
  
  unsigned int address = 0;
  //for (int n = 0; n < addrLen; n += 1) {
  for (int n = addrLen - 1; n >= 0; n -= 1) {
    int bit = digitalRead(ADDR[n]) ? 1 : 0;
    Serial.print(bit);
    address = (address << 1) + bit;
  }
  if (dataLen > 0){
    sprintf(addressStr, " (%02x),    DATA ", address);
    Serial.print(addressStr);
    unsigned int data = 0;
    for (int n = 0; n < 8; n += 1) {
      int bit = digitalRead(DATA[n]) ? 1 : 0;
      Serial.print(bit);
      data = (data << 1) + bit;
    }
    sprintf(dataStr, " (%02x)    ", data);
    Serial.println(dataStr);
  }
  else{
    sprintf(addressStr, " (%04x)", address);
    Serial.println(addressStr);
  }
  //sprintf(output, "   %02x  %c %02x", address, digitalRead(READ_WRITE) ? 'r' : 'W', data);
  //Serial.println(output);  
}

void loop() {
}
