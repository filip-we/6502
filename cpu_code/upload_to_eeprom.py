from filiprom import EepromFriend
import logging
import sys

logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.INFO)

ef = EepromFriend(interface='COM5', timeout=10)
#print('Uploading...')
ef.write_file('a.out')

#print('Reading contents...')
#ef.read_eeprom(end=256)
