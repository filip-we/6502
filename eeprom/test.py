import logging
import sys
from eeprom_friend import EepromFriend as EF
logger = logging.getLogger()

logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.INFO)

ef = EF(interface='COM5')
start = 0
end = 32
ef.read_eeprom(start=start, end=end, surpress_print=False)
