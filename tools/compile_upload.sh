#!/bin/sh
CURRENT_DIR=$(pwd)

echo "\nCompiling..."
ca65 --cpu 65C02 $1 -o bin/_segment.bin

echo "\nLinking...\n"
ld65 bin/_segment.bin -C src/memory_map.cfg -o bin/program.bin -vm --mapfile etc/map_file.txt

echo "\nSending file to Sixty5o2..."
echo "\nUploading..."
cd /home/filip/code/sixty5o2
node Sender.js /home/filip/code/6502/bin/program.bin $2

cd $CURRENT_DIR
