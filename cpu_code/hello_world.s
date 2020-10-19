PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

; ACIA
ACIA_DATA = $7000
ACIA_STATUS = ACIA_DATA + 1
ACIA_COMMAND = ACIA_DATA + 2
ACIA_CONTROL = ACIA_DATA + 3

; Tells compiler where the ROM is located in the address space.
  .org $8000

reset:
  ldx #$ff
  txs

; VIA setup
  lda #%11111111        ; Set all pins on port B to output
  sta DDRB
  lda #%11100000        ; set top 3 pins on port A to output
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
  lda #%00001011
  sta ACIA_COMMAND
  lda #%00011111
  sta ACIA_CONTROL

; "I'm alive" printing
  lda #">"
  jsr write_char_lcd
  lda #">"
  jsr write_char_lcd
  lda #">"
  jsr write_char_lcd
  lda #" "
  jsr write_char_lcd



read_next_rx:
  lda ACIA_STATUS
  and #%00001000        ; Check if ReceiverDataRegister is full
  beq read_next_rx

  lda ACIA_DATA
  jsr write_char_lcd

  jmp read_next_rx


send_lcd_command:
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA
  rts

write_char_lcd:
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
