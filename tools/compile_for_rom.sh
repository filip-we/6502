#!/bin/sh
CURRENT_DIR=$(pwd)

echo "\n>>> Compiling <<<"
ca65 --cpu 65C02 $1 -o bin/_segment.bin

echo "\n>>> Linking <<<"
cd ~/code/6502/bin
ld65 _segment.bin -C ../src/memory_map_for_rom.cfg -vm --mapfile ../etc/map_file.txt

echo "\n>>> Sending file to EEPROM-programmer <<<"
minipro -p AT28C256 -w ../bin/rom.bin

cd $CURRENT_DIR
