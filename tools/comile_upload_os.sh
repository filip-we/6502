#!/bin/sh
echo "\nCompiling..."
#vasm -Fbin -dotdir $1

ca65 --cpu 65C02 $1 -o bin/_segment.bin

read -p "Press [ENTER] to link or Ctrl-C to abort." input
ld65 bin/_segment.bin -C memory_map.cfg -o bin/program.bin


echo ""
read -p "Press [ENTER] to write to EEPROM or Ctrl-C to abort." input
echo "\nUploading..."
minipro -p AT28C256 -w bin/program.bin
