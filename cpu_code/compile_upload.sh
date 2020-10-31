#!/bin/sh
echo "\nCompiling..."
vasm -Fbin -dotdir $1
echo ""
read -p "Press [ENTER] to write to EEPROM or Ctrl-C to abort." input
echo "\nUploading..."
minipro -p AT28C256 -w a.out
