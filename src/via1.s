    .import __VIA1_START__

PORTB = __VIA1_START__
PORTA = __VIA1_START__ + 1
DDRB  = __VIA1_START__ + 2
DDRA  = __VIA1_START__ + 3

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

