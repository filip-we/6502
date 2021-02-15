import sys
from serial import Serial
from time import sleep

if len(sys.argv) < 2:
    print("Require at least one argument")
    sys.exit()

port = Serial(port=sys.argv[1], baudrate=19200, timeout=1)

COMMAND_RDRAM = b'\x01'#(1).to_bytes(1, 'little')

addresses = [b'\x12\x34', b'\xff\xfb', b'\xff\xfc', b'\xff\xfd', b'\xff\xfe', b'\xff\xff']
#addresses = [b'0x6000', b'0x6001', b'0x6002', b'0x6003', b'0x6004', b'0x6005']
#addresses = ["01", "23"]
#addresses = [x.encode("ascii") for x in addresses]

data = bytearray([0] * 16)

resp = []
for a in addresses:
    input(f"\nWrite {COMMAND_RDRAM}, {len(COMMAND_RDRAM)}")
    port.write(COMMAND_RDRAM)

    input(f"Write {a[1:2]}, {len(a[1:2])}")
    port.write(a[1:2])
    input(f"Write {a[0:1]}, {len(a[0:1])}")
    port.write(a[0:1])

    print(f"Read: {port.read(16)}")
    #i = 16
    #while i>0:
    #    input(f"Reading byte nr {16-i}")
    #    print(f"Read: {port.read(1)}")

#print(f"\n{addresses[0]}: {resp}")
port.close()

