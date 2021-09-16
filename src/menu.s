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

    KB_BUFF_WRITE   = ZP_START + $2a
    KB_BUFF_READ    = ZP_START + $2a

    KB_BUFF         = $1200

; Constants
    KB_POLL         = $ffff

start:
    sei

;   VIA setup
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00000000          ; Set CB/CA-controls to input, negative active edge.
    sta PCR                 ; Load T1-counter
    lda #%01000000          ; Enable T1 continous interrupts
    sta ACR
    lda #<KB_POLL
    sta T1C_L
    sta T1L_L
    lda #>KB_POLL
    sta T1C_H
    sta T1L_H
    lda #%11000000          ; Enable T1-interrupts
    sta IER

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

; Reset variables
    ldx ZP_START
reset_loop:
    sta $00, x
    inx
    bne reset_loop

    ldx #0
reset_kb:
    sta KB_BUFF, x
    inx
    bne reset_kb

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
;   For each button: compare state with flag in memory location.
;   If Flag==1 and  button==1: increase counter.
;   If Flag==1 and  button==0: reset counter.
;   (If Flag==0 and  button==0: increase counter.)
;   If Flag==0 and  button==1: reset counter.
;   Flag 1: Check if counter > 10: store key in keyboardbuffer. Reset counter.
;   (Flag 0: Check if counter > 100: store release key in keyboardbuffer. Reset counter.) Can be done later
;
;   Byte: flag, nnn nnnn
;   Flag not needed now since we dont count non-button-presses
;   Garth says: BIT puts bit 7's value in the N flag
    lda PORTA
    and #BUTTON_1_PIN
    bne button_not_pressed          ; We don't care if the button is not pressed
    inc BUTTON_1
    lda #$f0
    cmp BUTTON_1
    bne button_return
    ldx KB_BUFF_WRITE
    lda #'A'
    sta KB_BUFF, x
    inc KB_BUFF_WRITE
    jsr lcd_print_char
    rts

button_not_pressed:
    lda #0                          ;   We don't count how long the button is NOT pressed. Just reset the counter.
    sta BUTTON_1
button_return:
    rts

nmi:
    ;jsr read_buttons
    lda #'P'
    jsr lcd_print_char
    lda #<KB_POLL
    ;sta T1C_L
    sta T1L_L
    lda #>KB_POLL
    sta T1C_H
    ;sta T1L_H
    rti

test_text:
    .byte "Hejsan!", $00
