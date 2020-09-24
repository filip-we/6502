PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %1000000
RW = %0100000
RS = %0010000

reset:
  lda #%11111111 ; Set all pins on port b to output
  sta DDRB

  lda #%11100000 ; set top 3 pins on port A to output
  sta DDRA

  ; Display init
  lda #%00111000
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA

  ; something
  lda #%00001110
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA




loop:
  jmp loop

; # means absolute value
; $ means hex format

