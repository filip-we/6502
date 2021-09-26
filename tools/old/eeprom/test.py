import logging
import sys
from filiprom import EepromFriend as EF

logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.INFO)

ef = EF(interface='COM5')

data = [
        bytearray(b'\xff' * 48),
        bytearray(b'\xaa' * 5),
        bytearray(b'\xbb' * 16),
        bytearray(b'\xcc' * 17)
]
content = []

for d in data:
    ef.write_eeprom(data=d, surpress_print=True)
    content.append(ef.read_eeprom(start=0, end=(len(d) + 16), surpress_print=True))

