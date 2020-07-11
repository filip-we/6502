#from time import sleep
from .filipro import Filipro, ABORT, CONTINUE, TEST
READ_EEPROM = 5
WRITE_EEPROM = 6
WRITE_EEPROM_ADDRESS = 7

class EepromFriend(object):
    def __init__(self, interface='/dev/ttyUSB0',
                    baudrate=19200,
                    timeout=1,
                    size_in_kbit=256):
        self.conn = Filipro(interface, baudrate, timeout)
        self.size = size_in_kbit * 1024
        self.max_address = self.size // 8 - 1

    def read_eeprom(self, start=0, end=None, surpress_print=False):
        if end == None:
            end = self.max_address
        if end > self.max_address:
            raise ValueError(f'Address cannot be larger than {self.max_address}!')
        data = bytearray()
        with self.conn as c:
            temp = (start << 16) + end
            temp = temp.to_bytes(4, byteorder='big')
            print(f'Sending data: {temp}')
            c.write_read(READ_EEPROM, temp)
            for address in range(start, end, 16):
                d = c.write_read(CONTINUE)[1]
                data += d
                if not surpress_print:
                    print(f'Address {address:04x} ',
                            ''.join([' {:02x}'.format(x) for x in d]))
            cmd = c.write_read(ABORT)[0]
            if not cmd == ABORT:
                print('Not aborted properly')
        return data

    def write_eeprom(self, data, start=0):
        if start > self.max_address:
            raise ValueError(f'Address cannot be larger than {self.max_address}!')
        if not (isinstance(data, bytes) or isinstance(data, bytearray)):
            raise TypeError('Data must be provided as bytes or bytearray!')
        end = start + len(data) - 1
        if end > self.max_address:
            raise ValueError(f'Address cannot be larger than {self.max_address}!')
        with self.conn as c:
            temp = (start << 16) + end
            temp = temp.to_bytes(4, byteorder='big')
            print(f'Writing EEPROM from {start} to {end}')
            c.write_read(WRITE_EEPROM, temp)
            for address in range(start, end, 16):
                print(f'Writing ' +  
                            ''.join([' {:02x}'.format(x) for x in data[address:address + 16]]) +
                            f' @ {address:04x}')
                d = c.write_read(CONTINUE, data[address:address + 16])[0]
                if d == ABORT:
                    print('Aborting')
                    break

    def write_eeprom_address(self, address, data):
        if address > self.max_address:
            raise ValueError(f'Address cannot be larger than {self.max_address}!')
        if isinstance(address, bytes):
            address = (int).from_bytes(address, byteorder='big')
        if isinstance(data, bytes):
            data = (int).from_bytes(data, byteorder='big')
        write_data = ((address << 8) + data).to_bytes(3, byteorder='big')
        a = ''.join(['{:02x}'.format(x) for x in write_data[0:2]])
        print(f'Writing {data:02x} @ {a}')
        with self.conn as c:
            c.write_read(WRITE_EEPROM_ADDRESS, write_data)
            result = (int).from_bytes(c.write_read(CONTINUE)[1], byteorder='big')
            print(f'Result: {result:02x}')

    def write_file(self, file_name):
        with open(file_name, 'rb') as f:
            data = f.read()
        self.write_eeprom(data)

def main():
    pass
