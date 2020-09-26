PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

reset:
  lda #%11111111 ; Set all pins on port b to output
  sta DDRB

  lda #%11100000 ; set top 3 pins on port A to output
  sta DDRA

  ; Init display with 8 bit mode
  lda #%00111000
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

  ; Turn display on
  lda #%00001110
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

  ; Set cursor to increment, display to not scroll
  lda #%00000110
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA


  ; Charcter data
  lda #"P"
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E) ; Sending instruction by setting E bit
  sta PORTA
  lda #RS
  sta PORTA

  ; Charcter data
  lda #"S"
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E) ; Sending instruction by setting E bit
  sta PORTA
  lda #RS
  sta PORTA

loop:
  jmp loop

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop


; # means absolute value
; $ means hex format

