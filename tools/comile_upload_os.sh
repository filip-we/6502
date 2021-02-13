#!/bin/sh
echo "\nCompiling..."
#vasm -Fbin -dotdir $1

ca65 --cpu 65C02 $1 -o src/a.out

read -p "Press [ENTER] to link or Ctrl-C to abort." input
ld65 src/a.out -C memory_map.cfg


echo ""
read -p "Press [ENTER] to write to EEPROM or Ctrl-C to abort." input
echo "\nUploading..."
minipro -p AT28C256 -w a.out
