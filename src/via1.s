    .import __STACK_START__
    .import __VIA1_START__

PORTB = __VIA1_START__
PORTA = __VIA1_START__ + 1
DDRB  = __VIA1_START__ + 2
DDRA  = __VIA1_START__ + 3

SR    = __VIA1_START__ + $0A      ; Shift Register
ACR   = __VIA1_START__ + $0B      ; Auxiliary Control Register (T1 x2, T2 x2, Shift Register x3, Data Latch x2)
PCR   = __VIA1_START__ + $0C        ; Periferal Control Register
IFR   = __VIA1_START__ + $0D        ; Interrupt Flag Register
IER   = __VIA1_START__ + $0E        ; Interrupt Enable Register


E =  %10000000
RW = %01000000
RS = %00100000

LCD_CLEAR_DISPLAY = %00000001
LCD_CURSOR_HOME = %00000010
LCD_SECOND_LINE = $40


lcd_send_command:
    jsr lcd_wait
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA
    rts

lcd_write_char:
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
    bne lcd_wait_loop

    lda #RW
    sta PORTA
    lda #$ff
    sta DDRB
    pla
    rts

table_hex_print:
    .byte "0123456789abcdef"

print_hex_value:
    pha
    txa
    pha
    tya
    pha
    tsx
    inx
    inx
    inx
    lda __STACK_START__, x                    ; Get back accumulator
    lsr
    lsr
    lsr
    lsr                                       ; Get high address byte
    and #%00001111                  ; Print only ascii-chars??
    tay
    lda table_hex_print, y
    jsr lcd_write_char

    lda __STACK_START__, x                    ; Get back accumulator
    and #%00001111
    tay
    lda table_hex_print, y
    jsr lcd_write_char

    pla
    tay
    pla
    tax
    pla
    rts
