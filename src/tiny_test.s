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

    .org $0600
main:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command
    lda #'C'
    jsr print_char
    lda #'o'
    jsr print_char
    lda #'o'
    jsr print_char
    lda #'l'
    jsr print_char
    lda #'t'
    jsr print_char
lp:
    jmp lp

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

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
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
 
