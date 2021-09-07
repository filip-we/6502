;   ----------------------------------------------------------------
;   Execution starting here, at $0200!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp interrupt           ; Jump to interrupt. 4 bytes in, at $0204
;   ----------------------------------------------------------------

   .include "via1.s"

    RAM_ADDRESS             = $fb                   ; 2 bytes
    RAM_BOOT_ADDRESS        = $fd                   ; 2 bytes
    temp                    = $ff

start:
    sei                     ; Set interrupt flag (== interrupts ignored)

;   VIA setup
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00001100          ; Set Shift Register to shift in with external clock
    sta ACR
    lda #%00000000          ; Set CB/CA-controls to input, negative active edge.
    sta PCR
    lda #%10000100          ; Enable SR Interrupt
    sta IER
    lda SR                  ; Clear content of SR

;   LCD-display setup
    lda #%00000001          ; Clear display
    jsr lcd_send_command
    lda #%00000010          ; Return cursor home
    jsr lcd_send_command
    lda #%00000110          ; Entry mode
    jsr lcd_send_command
    lda #%00001111          ; Turning on display
    jsr lcd_send_command
    lda #%00111000          ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_send_command

;   Reset variables
    lda #$00
    ldx #$f0
reset_ram:
    sta $0f, x
    dex
    bne reset_ram

    lda #$00                 ; Low address
    sta RAM_ADDRESS
    sta RAM_BOOT_ADDRESS
    lda #$06                 ; High address
    sta RAM_ADDRESS + 1
    sta RAM_BOOT_ADDRESS + 1

main_first:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command
    lda #'W'
    jsr lcd_write_char
    lda #'a'
    jsr lcd_write_char
    lda #'i'
    jsr lcd_write_char
    lda #'t'
    jsr lcd_write_char
    lda #'i'
    jsr lcd_write_char
    lda #'n'
    jsr lcd_write_char
    lda #'g'
    jsr lcd_write_char


main_loop:
    ldy #$00
    lda IFR
    and #%00000100
    bne write_ram

    lda PORTA               ; Click button to boot
    and #%00000100          ; Checking leftmost button
    bne boot                ; Button not pressed - is low - equal to 0
    jmp main_loop

boot:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command
    lda #'B'
    jsr lcd_write_char
    lda #'o'
    jsr lcd_write_char
    lda #'o'
    jsr lcd_write_char
    lda #'t'
    jsr lcd_write_char
    jmp (RAM_BOOT_ADDRESS)

write_ram:
    lda SR
    sta (RAM_ADDRESS), y
    inc RAM_ADDRESS
    bne main_loop
    inc RAM_ADDRESS + 1
    jmp main_loop

interrupt:
    inc temp
    rti
