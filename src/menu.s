;   ----------------------------------------------------------------
;   Execution starting here, at $0200!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp nmi                 ; Jump to NMI-handler. 'jmp' instruction 4 bytes in, at $0204
;   ----------------------------------------------------------------

   .include "via.s"

start:
    sei

;   VIA setup
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00000000          ; Disable features not used
    sta ACR
    lda #%00000000          ; Set CB/CA-controls to input, negative active edge.
    sta PCR

;   LCD-display setup
    lda #%00000001          ; Clear display
    jsr lcd_command
    lda #%00000010          ; Return cursor home
    jsr lcd_command
    lda #%00000110          ; Entry mode
    jsr lcd_command
    lda #%00001111          ; Turning on display
    jsr lcd_command
    lda #%00111000          ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_command

; Print start message
    lda #'>'
    jsr lcd_print_char

main_loop:
    jmp main_loop

nmi:
    rti
