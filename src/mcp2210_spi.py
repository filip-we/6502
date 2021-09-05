import logging
import sys

from mcp2210 import Mcp2210, Mcp2210GpioDesignation, Mcp2210GpioDirection

log = logging.getLogger()
log.setLevel(logging.DEBUG)
stdout_handler = logging.StreamHandler(sys.stdout)
log.addHandler(stdout_handler)

chip = Mcp2210(serial_number='0001101309')



