import logging
import sys

from mcp2210 import Mcp2210, Mcp2210GpioDesignation, Mcp2210GpioDirection

def main(data):
    log = logging.getLogger()
    log.setLevel(logging.INFO)
    stdout_handler = logging.StreamHandler(sys.stdout)
    log.addHandler(stdout_handler)

    chip = get_chip()
    if len(sys.argv) > 3:
        delay = int(sys.argv[3])
    else:
        delay = 200
    chip.configure_spi_timing(delay_between_bytes=delay)
    chip.set_gpio_designation(4, Mcp2210GpioDesignation.CHIP_SELECT)
    rx_data = chip.spi_exchange(data, cs_pin_number=4)
    print(f'Sending {len(data)} data:')
    print(data)
    print('\nReceiving data:')
    print(rx_data)

def diverse(chip):
    print(chip._spi_settings.mode)

    chip.set_gpio_designation(4, Mcp2210GpioDesignation.CHIP_SELECT)
    tx_data = bytes(range(8))
    rx_data = chip.spi_exchange(tx_data, cs_pin_number=4)
    print(tx_data)
    print(rx_data)
    assert rx_data == tx_data

def get_chip():
    return Mcp2210(serial_number='0001101309')

if __name__ == '__main__':
    try:
        action = sys.argv[1]
    except IndexError:
        print('Supply "file" or "testdata"!')
        sys.exit()

    if action == 'file':
        with open(sys.argv[2], 'rb') as f:
            data = f.read()
        main(data)
    elif action == 'test':
        data = bytes(range(int(sys.argv[2])))
        main(data)
    elif action == 'zeros':
        data = bytes(b'\x00' * int(sys.argv[2]))
        main(data)
    else:
        print('No such option')
