PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E =  %10000000
RW = %01000000
RS = %00100000

DEBUG_IRQ =   %00000001
DEBUG_1 =     %00000010
DEBUG_2 =     %00000100
DEBUG_3 =     %00001000

LCD_SECOND_LINE = $40

; ACIA
ACIA_DATA = $7000
ACIA_STATUS = ACIA_DATA + 1
ACIA_COMMAND = ACIA_DATA + 2
ACIA_CONTROL = ACIA_DATA + 3

; CLI buffer
CLI_LEN = $0200
CLI_BUF = $0201


; Tells compiler where the ROM is located in the address space.
    .org $8000

reset:
    ldx #$ff              ; Initialize stack pointer
    txs

    lda #$00              ; Initialize CLI-buffer pointer
    sta CLI_LEN

; VIA setup
    lda #%11111111        ; Set all pins on port B to output
    sta DDRB
    ;lda #%11100000        ; set top 3 pins on port A to output
    lda #%11111111
    sta DDRA


; LCD-display setup
    lda #%00000001        ; Clear display
    jsr send_lcd_command
    lda #%00000010        ; Return cursor home
    jsr send_lcd_command
    lda #%00000110        ; Entry mode
    jsr send_lcd_command
    lda #%00001111        ; Turning on display
    jsr send_lcd_command
    lda #%00111000        ; Set to 8 bit mode, 1 line display, standard font
    jsr send_lcd_command

; ACIA setup
;         ppmeTTRd
    lda #%00001001        ;Odd parity, parity mode disabled, no echo, tx interrupt disabled, rx interrupt disabled
    sta ACIA_COMMAND
    lda #%00011111
    sta ACIA_CONTROL


print_welcome:            ; Print welcome message
    ldx #$00
print_loop:
    lda string_welcome,x
    beq init_lcd_cursor
    jsr acia_send_char
    jsr write_char_lcd
    inx
    jmp print_loop
init_lcd_cursor:
    lda #(%10000000 | LCD_SECOND_LINE)
    jsr send_lcd_command
    lda #">"
    jsr write_char_lcd

    lda #$0a
    jsr write_char_lcd
    lda #$0c
    jsr write_char_lcd
    lda #$0d
    jsr write_char_lcd

    cli                   ; Clear Interrupt disable (i.e. listen for interrupt requests)


main:
    lda #DEBUG_1
    sta PORTA
    jmp main


interrupt:
    pha
    txa
    pha
    tya
    pha

    lda #DEBUG_IRQ
    sta PORTA
    jsr acia_receive_char         ; Read char if available
    bcc return_from_interrupt     ; Return if no char available
    jsr write_char_lcd
    jsr acia_send_char            ; Echo back to sender
    jsr save_char_to_buffer
return_from_interrupt:
    pla
    tay
    pla
    tax
    pla
    rti


acia_receive_char:                ; Reads a char from ACIA if there is one
    clc
    lda ACIA_STATUS
    and #%00001000                ; Check if ReceiverDataRegisterFull
    beq acia_receive_char_return  ; Move if ReceiverDataRegisterFull was not set
    lda ACIA_DATA
    sec
acia_receive_char_return:
    rts


acia_send_char:
    pha
    txa
    pha
    tya
    pha
    lda ACIA_STATUS               ; For good measure
    ldx #$ff
    ldy #$03
    jsr delay_x_y
    pla
    tay
    pla
    tax
    pla
    sta ACIA_DATA
    rts


send_lcd_command:
    jsr lcd_wait
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA
    rts


write_char_lcd:
    jsr lcd_wait
    sta PORTB
    pha
    lda #RS
    sta PORTA
    lda #(RS | E) ; Sending instruction by toggling E bit
    sta PORTA
    lda #RS
    sta PORTA
    pla
    rts


lcd_wait:
    pha
    lda #$00
    sta DDRB
lcd_wait_loop:
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000        ; Check BusyFlag bit. Will set the Z flag if the result is zero, ie lcd is not busy
    ;cmp #%10000000        ; Compare with A by pretending to subtract the value from A
    bne lcd_wait_loop

    lda #RW
    sta PORTA
    lda #$ff
    sta DDRB
    pla
    rts

delay_x_y:
delay_loop_x:
    dex
    bne delay_loop_x
delay_loop_y:
    dey
    bne delay_loop_y
    rts


save_char_to_buffer:
    pha
    lda #DEBUG_1
    sta PORTA
    pla

    ldx CLI_LEN
    sta CLI_BUF,x
    inx
    stx CLI_LEN
    cmp #$0d              ; Compare with char [newline]
    ;cmp #$23              ; Compare with char # (confirmed to work)
    bne save_char_to_buffer_return
    jsr cli_cmd_ready
save_char_to_buffer_return:
    rts

; Searching for predefined commands
; Not finished
parse_cmd:
    ldx CLI_LEN
    dex                   ; Skip the [ENTER]
parse_cmd_loop:
    dex
    beq parse_cmd_return
    jmp parse_cmd_loop
parse_cmd_return:
    pha
    lda #$00              ; Reset cmd-buffer
    sta CLI_LEN
    pla
    rts


cli_cmd_ready:
    lda #%00000001        ; Clear display
    jsr send_lcd_command
    lda #%00000010        ; Return cursor home
    jsr send_lcd_command
cli_cmd_ready_print_buffer:
    ldx #$ff
cli_cmd_ready_print_buffer_loop:
    inx
    lda CLI_BUF, x
    jsr write_char_lcd
    cpx CLI_LEN
    bne cli_cmd_ready_print_buffer_loop

    lda #(%10000000 | LCD_SECOND_LINE)
    jsr send_lcd_command
    lda #">"
    jsr write_char_lcd

    ldx #$00
    stx CLI_LEN
    rts


string_welcome:
    .byte "== Iroko v0.1 ==", $00

cmd_test:
    .byte "hej", $00

    .org $fffa
    .word interrupt
    .word reset
    .word interrupt
