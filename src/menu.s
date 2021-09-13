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

    TEMP            = $0600

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

; Print start message
    lda #<test_text         ; Low byte
    sta ADDR_A
    lda #>test_text         ; Low byte
    sta ADDR_A + 1
    jsr lcd_print_string


main_loop:
    jmp main_loop

read_buttons:
; Configure VIA to interrupt at regular intervals
; On interrupt, read status of all buttons. 
;   For each button: compare state with flag in memory location. if flag 1 and  button 1 increase counter. If states are opposite zero counter and set flag.
;   Flag 1: Check if counter > 10: store key in keyboardbuffer. Reset counter.
;   Flag 0: Check if counter > 100: store release key in keyboardbuffer. Reset counter.

nmi:
    rti

test_text:
    .byte "Hejsan!", $00
