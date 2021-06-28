PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000
LED_ON =      %00000001
LED_OFF =     %00000000
BUTTON_ON =   %00000010
BUTTON_OFF =  %00000100
BUTTON_MASK = %00000110

  .org $8000

reset:
  ldx #$FF
  txs

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100001 ; Set top 3 pins and last on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction  

  lda #%00000001 ; Clear display
  jsr lcd_instruction

  lda #"R"
  jsr print_char
  lda #"e"
  jsr print_char
  lda #"a"
  jsr print_char
  lda #"d"
  jsr print_char
  lda #"y"
  jsr print_char

  lda #LED_OFF
  sta PORTA

loop:
  jsr test_button_on
  jsr test_button_off
  jmp loop

test_button_on:
  lda PORTA
  and #BUTTON_MASK
  cmp #BUTTON_ON
  beq set_led_on
  rts

test_button_off:
  lda PORTA
  and #BUTTON_MASK
  cmp #BUTTON_OFF
  beq set_led_off
  rts

set_led_on:
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  lda #"O"
  jsr print_char
  lda #"N"
  jsr print_char

  lda #LED_ON
  sta PORTA
  rts

set_led_off:
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  
  lda #"O"
  jsr print_char
  lda #"F"
  jsr print_char
  lda #"F"
  jsr print_char

  lda #LED_OFF
  sta PORTA
  rts

lcd_instruction:
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
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
  .org $fffc
  .word reset
  .word $0000
