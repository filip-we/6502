    .include "via1.s"

    .segment "CODE"

reset:
;    sei                     ; Set interrupt flag (== interrupts ignored)
    cld                     ; Clear decimal flag (== integer mode)

; VIA setup
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11110000          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA

; LCD-display setup
    lda #%00000001          ; Clear display
    jsr lcd_send_command
    lda #%00000010          ; Return cursor home
    jsr lcd_send_command
    lda #%00000110          ; Entry mode
    jsr lcd_send_command
    lda #%00001111          ; Turning on display
    jsr lcd_send_command
    lda #%00111000          ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_send_command

main:
    lda #'H'
    jsr lcd_write_char
    lda #'e'
    jsr lcd_write_char
    lda #'j'
    jsr lcd_write_char
    lda #'!'
    jsr lcd_write_char
loop:
    jmp loop

