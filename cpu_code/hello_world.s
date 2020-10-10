PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

; Tells compiler where the ROM is located in the address space.
  .org $8000

reset:
  ldx #$ff
  txs


  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100000 ; set top 3 pins on port A to output
  sta DDRA

; Clear display
  lda #%00000001
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

; Return cursor home
  lda #%00000010
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

; Entry mode
  lda #%00000110
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

; Turning on display
  lda #%00001111
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

; Set to 8 bit mode, 1 line display, standard font
  lda #%00111000
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

  ; Printing text
  lda #"&"
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E) ; Sending instruction by toggling E bit
  sta PORTA
  lda #RS
  sta PORTA


  lda #" "
  jsr lcd_send_char

  lda #"J"
  jsr lcd_send_char

  lda #"S"
  jsr lcd_send_char

  lda #"R"
  jsr lcd_send_char


loop:
  jmp loop

lcd_command:
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA
  rts

lcd_send_char:
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E) ; Sending instruction by toggling E bit
  sta PORTA
  lda #RS
  sta PORTA
  rts

interrupt:
  jmp interrupt

  .org $fffa
  .word interrupt
  .word reset
  .word interrupt
