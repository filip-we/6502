;   ----------------------------------------------------------------
;   Execution starting here, at $0200!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp nmi                 ; Jump to NMI-handler. 'jmp' instruction 4 bytes in, at $0204
;   ----------------------------------------------------------------
    .include "via.s"

    ZP_START        = $10
    ADDR_A          = ZP_START + $10
    ADDR_B          = ZP_START + $12

    BUTTON_1        = ZP_START + $20
    BUTTON_2        = ZP_START + $21
    BUTTON_3        = ZP_START + $22

    KB_BUFF_WRITE   = ZP_START + $d0
    KB_BUFF_READ    = ZP_START + $d1

    KB_BUFF         = $0600

; Constants
    KB_POLL         = $0340

start:
    sei                     ; Only needed since we get here from other code, not a hardware reset

;   LCD-display setup
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

;   VIA setup
    lda #%11100000          ; Set PA0 to PA4 to input, PA5 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00000000          ; Set CB/CA-controls to input, negative active edge.
    sta PCR
    lda #%01000000          ; Enable T1 continous interrupts without PB7-pulsing
    sta ACR

    lda #<KB_POLL           ; Load T1-counter
    sta T1L_L
    lda #>KB_POLL
    sta T1L_H
    sta T1C_H

    lda T1C_L               ; Clear Interrupt-bit
    lda #%11000000          ; Enable T1-interrupts
    sta IER

; Reset variables
    lda #0
    ldx ZP_START
reset_loop:
    sta $00, x
    inx
    bne reset_loop

    ldx #0
reset_kb:                   ; For easier debugging
    sta KB_BUFF, x
    inx
    bne reset_kb

; Print start message
    lda #<test_text         ; Low byte
    sta ADDR_A
    lda #>test_text         ; Low byte
    sta ADDR_A + 1
    jsr lcd_print_string

; Reset stops here

main_loop:
    lda KB_BUFF_READ
    cmp KB_BUFF_WRITE
    bpl main_loop

    ldx KB_BUFF_READ
    lda KB_BUFF, x
    inc KB_BUFF_READ
    jsr lcd_print_char
    jmp main_loop

read_buttons:
    lda PORTA
    and #BUTTON_1_PIN
    beq button_not_pressed          ; We don't care if the button is not pressed

    inc BUTTON_1
    lda #$20
    cmp BUTTON_1
    bne button_return

    ldx KB_BUFF_WRITE
    lda #'A'
    sta KB_BUFF, x
    inc KB_BUFF_WRITE
    rts

button_not_pressed:
    lda #0                          ;   We don't count how long the button is NOT pressed. Just reset the counter.
    sta BUTTON_1
button_return:
    rts

nmi:
    pha
    txa
    pha
    tya
    pha

    jsr read_buttons
    lda T1C_L                       ; Reset Interrupt-flag

    pla
    tay
    pla
    tax
    pla
    rti

test_text:
    .byte "Hejsan!", $00
