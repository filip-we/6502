import serial
import logging
from time import sleep

ABORT = 0
CONTINUE = 1
RESEND = 2
TEST = 3
STATUS = 4

HANDSHAKE = 129

class Filipro(object):
    def __init__(self, interface='/dev/ttyUSB0', baudrate=9600, timeout=1):
        self.interface = interface
        self.baudrate = baudrate
        self.timeout = timeout
        self.max_retries = 3
        self.logger = logging.getLogger('EF')

    def open(self):
        self.conn = serial.Serial(self.interface,
                    self.baudrate,
                    timeout=self.timeout)
        sleep(1)
        self.conn.write(HANDSHAKE.to_bytes(1, byteorder='big'))
        data = self.conn.read()
        if data != HANDSHAKE.to_bytes(1, byteorder='big'):
            raise ValueError('Error with handshake.')
    
    def close(self):
        self.conn.close()

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        self.close()

    def get_parity(self, n): 
        count = 0
        temp = n
        while temp >= 2:
            if temp & 1 == 1:
                count += 1
            temp = temp >> 1
        return count % 2

    def test_connection(self):
        test_data = [b'', b'', b'\x12\xac', b'\xcb\x23\x45', b'\x03\xbb\x34\xcc', b'']
        with self as c:
            for i, b in enumerate(test_data):
                c.write(TEST, b)
                print(f'Test {i}')
                print(f'Test W: Cmd {TEST}, data {b}')
                response = c.read()
                print(f'Test R: Cmd {response[0]}, data {response[1]}')

    def _checksum(self, data):
        '''Takes data as a bytearray.'''
        #return (sum(data) & 255).to_bytes(1, byteorder='big')
        return (sum(data) & 127)

    def read(self):
        def read_next_byte():
            response = int.from_bytes(self.conn.read(1), byteorder='big')
            self.logger.info(f'READ {response}')
            if response == b'':
                raise TimeoutError
            if self.get_parity(response) == 1:
                raise ValueError('Parity error!')
            else:
                return response >> 1

        head = read_next_byte()
        pcl_cmd = head >> 1
        any_data = head & 1
        if any_data:
            data_length = read_next_byte()
            checksum = read_next_byte()
            data = self.conn.read(data_length)
        else: 
            checksum = 0
            data_length = 0
            data = bytes()
        self.logger.info(f'READ Checksum: {checksum}')
        if self._checksum(data) != checksum:
            raise ValueError('Checksum wrong!')
        self.logger.info(f'READ {pcl_cmd}, {data} ({len(data)})')
        return pcl_cmd, data

    def write(self, pcl_cmd, data=bytearray()):
        def write_byte(b):
            b = (b << 1) + self.get_parity(b)
            self.logger.info(f'WRITE {b}')
            self.conn.write(b.to_bytes(1, byteorder='big'))

        '''Writes a pcl_cmd and data to the Arduino, togeather with checksum.'''
        if len(data) > 255:
            raise ValueError('Data cannot be larger than 255 bytes.')
        msg = (pcl_cmd << 1) + (1 if (len(data) > 0) else 0)
        par = self.get_parity(msg)
        msg = (msg << 1) + par 
        self.logger.info(f'WRITE {msg}')
        self.conn.write(msg.to_bytes(1,  byteorder='big'))
        if len(data) > 0:
            write_byte(len(data))
            write_byte(self._checksum(data))
            self.conn.write(data)

    def write_read(self, cmd, data=bytearray()):
        self.write(cmd, data)
        sleep(0.5)
        return self.read()
