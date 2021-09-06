import logging
import sys

from mcp2210 import Mcp2210, Mcp2210GpioDesignation, Mcp2210GpioDirection

log = logging.getLogger()
log.setLevel(logging.INFO)
stdout_handler = logging.StreamHandler(sys.stdout)
log.addHandler(stdout_handler)

chip = Mcp2210(serial_number='0001101309')

print(chip._spi_settings.mode)

chip.set_gpio_designation(4, Mcp2210GpioDesignation.CHIP_SELECT)
tx_data = bytes(range(3))
rx_data = chip.spi_exchange(tx_data, cs_pin_number=4)
print(tx_data)
print(rx_data)

assert rx_data == tx_data



