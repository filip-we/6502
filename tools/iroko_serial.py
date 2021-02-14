import sys
from serial import Serial
from time import sleep

if len(sys.argv) < 2:
    print("Require at least one argument")
    sys.exit()

port = Serial(port=sys.argv[1], baudrate=19200, timeout=1)

COMMAND_RDRAM = b'0x01'
addresses = [b'0xfffa', b'0xfffb', b'0xfffc', b'0xfffd', b'0xfffe', b'0xffff']
#addresses = [b'0x6000', b'0x6001', b'0x6002', b'0x6003', b'0x6004', b'0x6005']

resp = []
for a in addresses:
    port.write(COMMAND_RDRAM)
    sleep(1)
    port.write(a)
    sleep(1)
    resp.append(port.read(1))
    sleep(1)

print(f"{addresses[0]}: {resp}")
port.close()

