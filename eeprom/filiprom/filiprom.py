#from time import sleep
from .filipro import Filipro, ABORT, CONTINUE, TEST
READ_EEPROM = 5
WRITE_EEPROM = 6
WRITE_EEPROM_ADDRESS = 7

class EepromFriend(object):
    def __init__(self, interface='/dev/ttyUSB0',
                    baudrate=19200,
                    timeout=3,
                    size_in_kbit=256):
        self.conn = Filipro(interface, baudrate, timeout)
        self.size = size_in_kbit * 1024
        self.max_address = self.size // 8 - 1

    def _check_limits(self, start, end=None):
        if start > self.max_address:
            raise ValueError(f'Address \"start\" cannot be larger than {self.max_address}!')
        if end:
            if end > self.max_address + 1:
                raise ValueError(f'Address \"end\" cannot be larger than {self.max_address + 1}!')

    def read_eeprom(self, start=0, end=None, surpress_print=False):
        if end == None:
            end = self.max_address
        self._check_limits(start, end)
        data = bytearray()
        print(f'>>> Reading EEPROM {start} to {end} <<<')
        with self.conn as c:
            temp = (start << 16) + end
            temp = temp.to_bytes(4, byteorder='big')
            c.write_read(READ_EEPROM, temp)
            for address in range(start, end, 16):
                d = c.write_read(CONTINUE)[1]
                data += d
                if not surpress_print:
                    print(f'Address {address:04x} ',
                            ''.join([' {:02x}'.format(x) for x in d]))
            cmd = c.write_read(ABORT)[0]
            if not cmd == ABORT:
                self.logger.error('Not aborted properly')
        return data

    def write_eeprom(self, data, start=0, surpress_print=False):
        self._check_limits(start)
        if not (isinstance(data, bytes) or isinstance(data, bytearray)):
            raise TypeError('Data must be provided as bytes or bytearray!')
        end = start + len(data)# - 1
        if end > self.max_address + 1:
            raise ValueError(f'Address cannot be larger than {self.max_address}; \"end\" was {end}!')
        with self.conn as c:
            temp = (start << 16) + end
            temp = temp.to_bytes(4, byteorder='big')
            print(f'>>> Writing EEPROM from {start} to {end} <<<')
            c.write_read(WRITE_EEPROM, temp)
            for address in range(start, end, 16):
                if not surpress_print:
                    print(f'Address {address:04x} ' + 
                                ''.join([' {:02x}'.format(x) for x in data[address - start:address - start + 16]]))
                d = c.write_read(CONTINUE, data[address - start:address - start + 16])[0]
            d = c.write_read(ABORT)

    def write_eeprom_address(self, data, address):
        self._check_limits(address)
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

    def page_write(self, data, address, surpress_print=False):
        '''Writes 16 bytes of data to the given address.'''
        self._check_limits(address, address + 16)
        bin_address = bytearray(address.to_bytes(2, byteorder='big'))
        data = bytearray(data)
        if address % 16 != 0:
            raise ValueError('Address must be a multiple of 16 when doing a page write.')
        if len(data) != 16:
            raise ValueError('Data must be exactly 16 bytes long when doing a page write.')
        data = bin_address + data
        if not surpress_print:
            print(f'Address {address:04x} ' + 
                                ''.join([' {:02x}'.format(x) for x in data[2:]]))
        with self.conn as c:
            c.write_read(WRITE_EEPROM_ADDRESS, data)

    def clear_eeprom(self, start, stop, byte=b'0xff', surpress_print=False):
        data = bytearray(byte * 16)
        for address in range(start, stop, 16):
            self.page_write(data, address, surpress_print=surpress_print)

    def write_file(self, file_name):
        with open(file_name, 'rb') as f:
            data = f.read()
        self.write_eeprom(data)

    def selective_write_eeprom(self, file_name, start=0, surpress_print=False, skip_pattern=bytearray([0]*16)):
        def _loop_chunks(data, chunk_size):
            return (data[i:i + chunk_size] for i in range(0, len(data), chunk_size))
        with open(file_name, 'rb') as f:
            data = f.read()
        for nr, chunk in enumerate(_loop_chunks(bytearray(data), 16)):
            address = nr * 16 + start
            if chunk != skip_pattern:
                self.page_write(data=chunk, address=address, surpress_print=surpress_print)

