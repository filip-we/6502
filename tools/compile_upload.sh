#!/bin/sh
CURRENT_DIR=$(pwd)

echo "\n>>> Compiling <<<"
ca65 --cpu 65C02 $1 -o bin/_segment.bin

echo "\n>>> Linking <<<"
cd ~/code/6502/bin
ld65 _segment.bin -C ../src/memory_map.cfg -vm --mapfile ../etc/map_file.txt

echo "\n>>> Sending file to Sixty5o2 <<<"
cd ~/code/sixty5o2
node Sender.js ~/code/6502/bin/ram.bin $2

cd $CURRENT_DIR
