import logging
import sys

from mcp2210 import Mcp2210, Mcp2210GpioDesignation, Mcp2210GpioDirection

log = logging.getLogger()
log.setLevel(logging.DEBUG)
stdout_handler = logging.StreamHandler(sys.stdout)
log.addHandler(stdout_handler)

chip = Mcp2210(serial_number='0001101309')

print('\n')
print(chip._spi_settings.mode)

chip.set_gpio_designation(4, Mcp2210GpioDesignation.CHIP_SELECT)
tx_data = bytes(range(16))
rx_data = chip.spi_exchange(tx_data, cs_pin_number=4)
assert rx_data == tx_data
print(tx_data)
print(rx_data)

#chip.transfer(data)



