# README

# CLI-magic
http://www.climagic.org/mirrors/VT100_Escape_Codes.html

# Connect to serial port on Linux
tio -b 19200 /dev/ttyACM0

# EEPROM
I've changed wiring compared with Ben's programmer.

# Compiling asm-code
Compiler found here:
http://www.compilers.de/vasm.html
Run the exe with argument "-Fbin -dotdir".
Show output with powershell's "Format-Hex a.out"

# RAM-boot mode
RAM is between 0 and 3fff.
00 to ff is ZP, 0100 to 01ff is the hardware stack. Let 0200 to 0fff be reserved to variables.
Then bootable code can start at 1000, nice and even. Page write will be done in slices of 16 bytes, for example between 1000 and 10ff.


# OpCodes
txs     ..              9A
rts                     60

lda     zeropage        A5
lda     immediate       A9
lda     absolute        Ad

sta     absolute        8D

# More custom stack
; Put address of the array in the stack
; Goto subroutine
;   Read first byte
;   Increase low byte by one.
;   Check overflow: if yes inc high byte
;   Loop

lda #$01
sta $0200
lda #$03
sta $0201
lda #$04
sta $0202

lda #$10    ; Initialize stack-pointer
tax

lda #$02    ; Push array pointer to stack
dex
sta 0,x
lda #$00
dex
sta 0,x

lda #$00
tay
print_array:
  lda ($00, x)  ; Load accumulator with value from an address found at ($00 + x)
  sta $0300,y   ; Print
  iny
  inc $00, x    ; Increase low byte
  bne print_array   ; Check overflow
  inc $01, x



/// January 2021
Two types of interractions with the computer is desired:
1. Communication between a PC and the computer via a UART
2. Flash or read the RAM from a PC


The 6502 can only communicate in parallell. Can I use a 6522 to implement any serial protocols?
Yes, I can implement both UART and ISP on a 6522. However, the 6551 does most of the stuff already and it's bug can be fixed using a 6522 as well.

Idea: Native Bootloader




/// October 2020
--- Terminal Connection ---
AICA: Data + address -> UART
USB-chip: UART -> USB


--- Keyboard ---
VIA

--- Notes EEPROM ---
It's size is 256 kbit but we only use 32 kbit (up to address 7fff).

The first byte of the eeprom will have address 8000. The resetvector is located at address fffc and fffd, i.e. eeproms internal address 7ffc and 7ffd. 

--- Memory Map v 1---

                                                    -- RAM ---      -- VIA ---      - EEPROM -
                        15 14 13 12 11 10 9  8      CS  OE  WE      CS1 CS2B        CS  OE  WE
0000 -> 0FFF    RAM     0  0  0  0  x  x  x  x      0   0   x       0   1           1   0   1
1000 -> 1FFF    RAM     0  0  0  1  x  x  x  x      0   0   x       0   1           1   0   1
2000 -> 2FFF    RAM     0  0  1  0  x  x  x  x      0   0   x       1   1           1   0   1
3000 -> 3FFF    RAM     0  0  1  1  x  x  x  x      0   0   x       1   1           1   0   1

4000 -> 4FFF    -       0  1  0  0  x  x  x  x      0   1   x       0   0           1   0   1
5000 -> 5FFF    -       0  1  0  1  x  x  x  x      0   1   x       0   0           1   0   1
6000 -> 6FFF    VIA     0  1  1  0  x  x  x  x      0   1   x       1   0           1   0   1
7000 -> 7FFF    -       0  1  1  1  x  x  x  x      0   1   x       1   0           1   0   1

8000 -> 8fff    EEPROM  1  0  0  0  x  x  x  x      1   0   x       0   1           1   0   1
9000 -> 9fff    EEPROM  1  0  0  1  x  x  x  x      1   0   x       0   1           1   0   1
a000 -> afff    EEPROM  1  0  1  0  x  x  x  x      1   0   x       1   1           1   0   1
b000 -> bfff    EEPROM  1  0  1  1  x  x  x  x      1   0   x       1   1           1   0   1

c000 -> cfff    EEPROM  1  1  0  0  x  x  x  x      1   1   x       0   1           1   0   1
d000 -> dfff    EEPROM  1  1  0  1  x  x  x  x      1   1   x       0   1           1   0   1
e000 -> efff    EEPROM  1  1  1  0  x  x  x  x      1   1   x       1   1           1   0   1
f000 -> ffff    EEPROM  1  1  1  1  x  x  x  x      1   1   x       1   1           1   0   1

RAM
    CS:     NAND(NOT(A15), PHI2)
    OE:     A14
    WE:     R/W

VIA
    CS1 =   A13
    CS2B =  NAND(NOT(A15), A14)

EEPROM
    CS:     NOT(A15)
    OE:     0
    WE:     1


--- Memory Map v2 ---
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



--- Notes ----
NAND gate

    A   B   Output
    0   0   1
    0   1   1
    1   0   1
    1   1   0

AND gate
    A   B   Output
    0   0   0
    0   1   0
    1   0   0
    1   1   1


"EEPROM as RAM" was wired like this
    CE: NAND(NOT(A15), NOT(A14))
    OE: NOT(R/W)
    WE: NAND(NOT(R/W), PHI2)

    NAND gates required:
        NOT(A15)
        NOT(A14)
        NOT(R/W)
        NAND(NOT(R/W), PHI2)

