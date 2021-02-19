import sys
import re
from serial import Serial
from time import sleep

def read_data(port):
    print('Reading...')
    data = port.read(1024)
    data = data.split(b'\x1b[2J\x1b[;f')
    data = (b'\x0d\x0a').join(data)
    data = data.split(b'\x0d\x0a')
    if isinstance(data, list):
        for d in data:
            print(d)
    else:
        print(data)

print("Opening port...")
port = Serial(port="/dev/ttyACM0", baudrate=19200, timeout=1)
i = 0
while True:
    input("Start new message!")
    read_data(port)
    data = bytearray([i+1, i+2, i+3, i] + [127]*i)
    print(f"Writing {data}")
    port.write(data)
    read_data(port)
    print('\n')
    i += 1
port.close()

