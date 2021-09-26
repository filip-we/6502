# Iroko - A 6502-based computer on a breadboard
The Iroko is a computer built on breadboads with several IC-components, with the center being the 65c02-processor from Western Design Center. It is basically the same processor used in many devices and home computers of the late 70s and the 80s. This project would not have been possible without the excelent educational videos made by Ben Eater.

# Features
## 4-key keyboard
Currently the computer has the very exciting ability to read the input of four different buttons. The button-presses are debouced and when holding a button it is repeated cirka four times per second (comparable to a normal keyboard, give or take). The output is stored in a keyboad buffer that can be consumed of whatever you'd like.

## Screen
As per the design of Ben Eater, the computer features an LCD-screen that displays characters.


# Development
## Sixty5o2
The Iroko uses the Sixty5o2 bootloader made for 6502-based systems. It uses an Arduino to upload programs into RAM for execution by the 6502.

I have modified the vector in the end of the ROM in order to use the interrupt in my own code. I let the maskable interrupt point to $0210 and put the code at $0210 in RAM.

## Compilation
I use the ca65 compiler-stack. It gives more options compared with VASM, which I used before. ca65 can handle non-hardcoded addresses through a memory-map, making porting of code easier, as well as facilitates changes in the hardware. It aslo comes with the linker ld65, allowing to connect different Assembly-files instead of keeping everything in one single monstrous file.

Compilation and uploading is done with the shell-script in `tools`. The first argument is your source code and the second one is the device-name of the Arduino. Please see the repository for Sixty5o2 for more info.

# Notes & Good to have things
## Home made protocol to talk to home made eeprom-programer
Command (1 byte), Address (2 bytes), Data length (1 byte), Data (0 to theoretically 251 bytes)

## CLI-magic
http://www.climagic.org/mirrors/VT100_Escape_Codes.html

## Connect to serial port on Linux
tio -b 19200 /dev/ttyACM0

## Compiling asm-code
I use cc65 since it has more features than VASM, which I used before. The scripts in the tools directory contains the proper command for compiling a file with ca65. 

### VASM
Compiler found here: http://www.compilers.de/vasm.html
Run the exe with argument "-Fbin -dotdir". Show output with powershell's "Format-Hex a.out"

## OpCodes
txs     ..              9A
rts                     60

lda     zeropage        A5
lda     immediate       A9
lda     absolute        Ad

sta     absolute        8D

## Memory Map Suggestion
                                                    - "RAM" --      -- VIA ---      - EEPROM -      - DECODER -
                        15 14 13 12 11 10 9  8      CS  OE  WE      CS1 CS2B        CS  OE  WE      G1  G2A G2B
0000 -> 0FFF    RAM     0  0  0  0  x  x  x  x      0   0   x       0   1           1   0   1       0   0   0
1000 -> 1FFF    RAM     0  0  0  1  x  x  x  x      0   0   x       0   1           1   0   1       0   0   0
2000 -> 2FFF    RAM     0  0  1  0  x  x  x  x      0   0   x       1   1           1   0   1       0   0   0
3000 -> 3FFF    RAM     0  0  1  1  x  x  x  x      0   0   x       1   1           1   0   1       0   0   0

4000 -> 47FF    DECODER 0  1  0  0  0  x  x  x      0   1   x       0   0           1   0   1       1   0   0
4800 -> 4FFF    DECODER 0  1  0  0  1  x  x  x      0   1   x       0   0           1   0   1       1   0   0
5000 -> 57FF    DECODER 0  1  0  1  0  x  x  x      0   1   x       0   0           1   0   1       1   0   0
5800 -> 5FFF    DECODER 0  1  0  1  1  x  x  x      0   1   x       0   0           1   0   1       1   0   0
6000 -> 67FF    DECODER 0  1  1  0  0  x  x  x      0   1   x       1   0           1   0   1       1   0   0
6800 -> 6FFF    DECODER 0  1  1  0  1  x  x  x      0   1   x       1   0           1   0   1       1   0   0
7000 -> 77FF    DECODER 0  1  1  1  0  x  x  x      0   1   x       1   0           1   0   1       1   0   0
7800 -> 7FFF    DECODER 0  1  1  1  1  x  x  x      0   1   x       1   0           1   0   1       1   0   0

8000 -> 8fff    EEPROM  1  0  0  0  x  x  x  x      1   0   x       0   1           1   0   1       0   1   0
9000 -> 9fff    EEPROM  1  0  0  1  x  x  x  x      1   0   x       0   1           1   0   1       0   1   0
a000 -> afff    EEPROM  1  0  1  0  x  x  x  x      1   0   x       1   1           1   0   1       0   1   0
b000 -> bfff    EEPROM  1  0  1  1  x  x  x  x      1   0   x       1   1           1   0   1       0   1   0

c000 -> cfff    EEPROM  1  1  0  0  x  x  x  x      1   1   x       0   1           1   0   1       1   1   0
d000 -> dfff    EEPROM  1  1  0  1  x  x  x  x      1   1   x       0   1           1   0   1       1   1   0
e000 -> efff    EEPROM  1  1  1  0  x  x  x  x      1   1   x       1   1           1   0   1       1   1   0
f000 -> ffff    EEPROM  1  1  1  1  x  x  x  x      1   1   x       1   1           1   0   1       1   1   0

RAM
    CS: NAND(NOT(A15), NOT(A14))
    OE: NOT(R/W)
    WE: NAND(NOT(R/W), PHI2)

DECODER
    G1: A14
    G2A: A15
    G2B: GND

    Adrs:   15  14  13  12  11  10  9   8       Output
    Pin:    G2A G1  C   B   A
            0   1   0   0   0   x   x   x       Y0
            0   1   0   0   1   x   x   x       Y1
            0   1   0   1   0   x   x   x       Y2
            0   1   0   1   1   x   x   x       Y3
            0   1   1   0   0   x   x   x       Y4
            0   1   1   0   1   x   x   x       Y5
            0   1   1   1   0   x   x   x       Y6
            0   1   1   1   1   x   x   x       Y7

EEPROM
    CS:     NOT(A15)
    OE:     NOT(R/W)
    WE:     NAND(NOT(R/W), PHI2)

