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

  ; Clear display
  lda #%00000001
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0

  ; Return cursor home
  lda #%00000010
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0

  ; Entry mode
  lda #%00000110
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0

  ; Turning on display
  lda #%00001111
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0

  ; Function set to 4 bit mode, 1 line display, standard font
  lda #%00111000
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0

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


; # means absolute value
; $ means hex format

