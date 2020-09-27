from filiprom import EepromFriend
import logging
import sys

#logger = logging.getLogger()
#logger.addHandler(logging.StreamHandler(sys.stdout))
#logger.setLevel(logging.INFO)

ef = EepromFriend(interface='COM5', timeout=10)
ef.write_file('a.out')



#Writing reset vector to point at beginning of eeprom
ef.write_eeprom_address(int('0x7ffc', 16), int('0x00', 16))
ef.write_eeprom_address(int('0x7ffd', 16), int('0x80', 16))


print('\nContents:')
ef.read_eeprom(end=int('0x00ff', 16))

print('\nReset vector:')
ef.read_eeprom(start=int('0x7fe0', 16))# end=int('0x7fff', 16))
