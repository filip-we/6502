;   ----------------------------------------------------------------
;   Execution starting here, at $0200!
    .segment "CODE"
    jmp start               ; Jump to main code. Instrction is 3 bytes long.
    jmp nmi                 ; Jump to NMI-handler. Instruction is 3 bytes long and starts 3 bytes in, at $0203.
;   ----------------------------------------------------------------
    .include "via.s"
    .include "ps2_keyboard.s"

; Variables
    ZP_START        = $10
    ADDR_A          = ZP_START + $10
    ADDR_B          = ZP_START + $12

    BUTTON_COUNTERS = ZP_START + $20        ; 4 bytes long
    BUTTON_PIN_NR   = ZP_START + $2a

    KB_BUFF_WRITE   = ZP_START + $30
    KB_BUFF_READ    = ZP_START + $31
    LCD_BUFF_WRITE  = ZP_START + $32
    LCD_BUFF_READ   = ZP_START + $33
    TEMP            = ZP_START + $34

    pulse_counter   = $05ff
    KB_BUFF         = $1000                 ; $ff bytes long
    LCD_BUFF        = $1100                 ; 2x16 bytes, ending at $110f

; Constants
    KB_POLL         = $0340

start:
    sei                     ; Only needed since we get here from other code, not a hardware reset
; Reset variables
    lda #0
    ldx ZP_START
reset_loop:
    sta $00, x
    inx
    bne reset_loop

    sta pulse_counter

    ldx #33
lcd_ram_init:
    dex
    lda welcome_msg, x
    sta LCD_BUFF, x
    cpx #$00
    bne lcd_ram_init

; IRQ setup
    lda #<isr
    sta $04
    lda #>isr
    sta $05

; VIA-1 setup
    lda #%00000001          ; Disable shift-register output
    sta PORTA
    lda #%11100001          ; Set PA1 to PA4 to input, PA0, PA5 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00000001          ; Set CB/CA-controls to input, positive active edge.
    sta PCR
    lda #%01000000          ; Enable T1 continous interrupts without PB7-pulsing
    sta ACR

    lda #<KB_POLL           ; Load T1-counter
    sta T1L_L
    lda #>KB_POLL
    sta T1L_H
    sta T1C_H

    lda T1C_L               ; Clear Interrupt-bit
    lda #%11000010          ; Enable T1-interrupts and CA1
    sta IER

; LCD-display setup
    lda #LCD_CLEAR_DISPLAY
    jsr lcd_command
    lda #LCD_CURSOR_HOME
    jsr lcd_command
    lda #%00000110              ; Entry mode
    jsr lcd_command
    lda #%00111000              ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_command
    lda #LCD_DISPLAY_ON
    jsr lcd_command
    jsr update_lcd

; VIA-2 setup
    jsr setup_via_2

    cli                     ; Ready to receive interrupts
    jmp main

temp_main:
    ldx #64
temp_main_1:
    ldy #0
temp_main_2:
    dey
    bne temp_main_2
    dex
    bne temp_main_1

    lda #LCD_CLEAR_DISPLAY
    jsr lcd_command
    lda #LCD_CURSOR_HOME
    jsr lcd_command

    lda #'$'
    jsr lcd_print_char
    lda pulse_counter
    jsr lcd_print_hex_byte

    jmp temp_main

main:
;start_loop:
;    lda KB_BUFF_READ        ; We want to keep the start message until user starts to type
;    cmp KB_BUFF_WRITE
;    bpl start_loop
;    ldx #33
;    lda #' '
;start_clear_lcd:
;    dex
;    sta LCD_BUFF, x
;    cpx #0
;    bne start_clear_lcd

main_loop:
    lda KB_BUFF_READ
    cmp KB_BUFF_WRITE
    bpl main_loop

    ldx KB_BUFF_READ
    lda KB_BUFF, x
    inc KB_BUFF_READ

    ldx LCD_BUFF_WRITE
    sta LCD_BUFF, x
    jsr update_lcd
    inx
    stx LCD_BUFF_WRITE
    cpx #33
    bne main_loop
    lda #0
    sta LCD_BUFF_WRITE
    jmp main_loop

read_buttons:
    ldx #5
    lda #%00100000                  ; Buttons are at PBA1-PBA4
    sta BUTTON_PIN_NR
read_buttons_loop:
    dex
    lda BUTTON_PIN_NR
    clc
    ror
    sta BUTTON_PIN_NR
    txa
    beq button_return

    lda BUTTON_PIN_NR
    and PORTA
    beq button_not_pressed          ; We don't care if the button is not pressed

    inc BUTTON_COUNTERS, x
    lda BUTTON_COUNTERS, x
    cmp #$20                        ; Count triggering threshold
    bne read_buttons_loop

    ldy KB_BUFF_WRITE
    lda char_map, x
    sta KB_BUFF, y
    inc KB_BUFF_WRITE
    jmp read_buttons_loop

button_not_pressed:
    lda #0                          ; We don't count how long the button is NOT pressed. Just reset the counter.
    sta BUTTON_COUNTERS, x
    jmp read_buttons_loop
button_return:
    rts

update_lcd:                         ; Destructive on A
    txa
    pha
    tya
    pha
    lda #LCD_CURSOR_HOME
    jsr lcd_command

    ldx #0
update_lcd_loop:
    lda LCD_BUFF, x
    jsr lcd_print_char
    inx
    cpx #16
    beq update_lcd_advance_line
    cpx #32
    bne update_lcd_loop
    pla
    tay
    pla
    tax
    rts

update_lcd_advance_line:
    lda #LCD_SECOND_LINE
    jsr lcd_command
    jmp update_lcd_loop


temp_isr:
    pha

    inc pulse_counter
    lda PORTA                       ; Clear CA1-interrupt

    pla
    rti

isr:
    pha
    txa
    pha
    tya
    pha

    lda IFR
    asl                             ; T1
    bmi isr_T1
    asl                             ; T2
    asl                             ; CB1
    asl                             ; CB2
    asl                             ; SR
    asl                             ; CA1
    bmi isr_CA1
    asl                             ; CA2
return_isr:
    pla
    tay
    pla
    tax
    pla
    rti

isr_T1:
    jsr read_buttons
    lda T1C_L                       ; Reset Interrupt-flag
    jmp return_isr

isr_CA1:
    jsr read_scan_code
    lda PORTA                       ; Clear CA1-interrupt, last thing to do
    jmp return_isr

nmi:
    rti

test_text:
    .byte "Hejsan!", $00

welcome_msg:
    .byte "0123456789abcdef", "0123456789abcdef", $00

char_map:
    .byte 0, "UDLR", 0
