import argparse

from filiprom import EepromFriend

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--interface', required=True, type=str, help='Port to use, eg. COM5')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--read', nargs=2, help='Supply start and stop as hex.')
    group.add_argument('--write', nargs=2, help='Supply start and file name.')
    group.add_argument('--clear', nargs=3, default=None, help='Supply start, stop and byte to fill, all as hex strings.')

    args = parser.parse_args()
    ef = EepromFriend(interface=args.interface, timeout=10)

    if args.read:
        start = int(args.read[0], 16)
        stop = int(args.read[1], 16)
        ef.read_eeprom(start=start, end=stop)
    if args.write:
        start = int(args.write[0], 16)
        ef.selective_write_eeprom(file_name=args.write[1], start=start)
    if args.clear:
        start = int(args.clear[0], 16)
        stop = int(args.clear[1], 16)
        char = bytes.fromhex(args.clear[2])
        ef.clear_eeprom(start, stop, char)

