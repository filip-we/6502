from time import sleep
from .filipro import Filipro, CONTINUE, TEST
READ_EEPROM = 5
WRITE_EEPROM = 6

class EepromFriend(object):
    def __init__(self, interface='/dev/ttyUSB0', baudrate=9600, timeout=1):
        self.conn = Filipro(interface, baudrate, timeout)

    def readEeprom(self, start, end=65535):
        data = bytearray()
        with self.conn as c:
            temp = start + (end << 8)
            temp = temp.to_bytes(4, byteorder='big')# + end.to_bytes(2, byteorder='big') 
            print(f'W-R addresses {temp}')
            print(c.write_read(READ_EEPROM, temp))
            for address in range(start, end, 16):
                print(f'Address {address}')
                print('W-R', c.write_read(CONTINUE))
                print()
        return data
