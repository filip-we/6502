    .import __STACK_START__
    .import __VIA_START__

PORTB = __VIA_START__
PORTA = __VIA_START__ + 1
DDRB  = __VIA_START__ + 2
DDRA  = __VIA_START__ + 3

T1C_L = __VIA_START__ + $04      ; Timer 1 Counter Low byte
T1C_H = __VIA_START__ + $05      ; Timer 1 Counter High byte
T1L_L = __VIA_START__ + $06      ; Timer 1 Latch Low byte
T1L_H = __VIA_START__ + $07      ; Timer 1 Latch High byte

SR    = __VIA_START__ + $0A      ; Shift Register
ACR   = __VIA_START__ + $0B      ; Auxiliary Control Register (T1 x2, T2 x2, Shift Register x3, Data Latch x2)
PCR   = __VIA_START__ + $0C        ; Periferal Control Register
IFR   = __VIA_START__ + $0D        ; Interrupt Flag Register
IER   = __VIA_START__ + $0E        ; Interrupt Enable Register


E =  %10000000
RW = %01000000
RS = %00100000

BUTTON_1_PIN = 2
BUTTON_2_PIN = 3
BUTTON_3_PIN = 5

LCD_CLEAR_DISPLAY = %00000001
LCD_CURSOR_HOME   = %00000010
LCD_DISPLAY_ON    = %00001111
LCD_SECOND_LINE   = %11000000

; ----------------------------------------------------------------
lcd_command:
    jsr lcd_wait
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA
    rts

; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; Inspiration from the WOZ Monitor by Steve Wozniak
; Destroys A
lcd_print_hex_byte:
    pha
    lsr                             ; We print the MS-nibble first.
    lsr
    lsr
    lsr
    jsr lcd_print_hex_char
    pla

lcd_print_hex_char:
    and #%00001111                 ; Discard upper nibble
    ora #'0'                        ; Adding offset to get to first char, #%0011.0000
    cmp #'9' + 1                    ; If this is > 9 then add offset to a, b, c...
    bmi lcd_print_char              ; If negative we can print the value of A
    clc                             ; Add offset to get to char a, b, etc. 
    adc #$27                        ; We jump from $3a...$3f to $61..$66

; Non destructive
lcd_print_char:
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

; ----------------------------------------------------------------
; Print a null-terminated string with an address pointer at ADDR_A
; Destroys a, y
lcd_print_string:
    ldy #$00
    lda (ADDR_A), y
lcd_print_string_loop:
    jsr lcd_print_char
    iny
    lda (ADDR_A), y
    bne lcd_print_string_loop   ; If a != $00 we continue
    rts
