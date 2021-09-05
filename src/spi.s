;   Execution starting here! At first line!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp interrupt           ; Jump to interrupt. 4 bytes in, at $0204

;   Other stuff goes here
   .include "via1.s"

    SPI_DATA = $1F00

    SPI_WRITE = $00
    SPI_READ = $01
    LCD_COUNT = $02

string_s:
    .byte "=== SPI  ===", $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

start:
    sei                     ; Set interrupt flag (== interrupts ignored)

; VIA setup
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%00001100          ; Set Shift Register to shift in with external clock
    sta ACR
    lda #%00000000          ; Set CB2-controls to input, negative active edge.
    sta PCR
    lda #%10000100          ; Enable SR-interrupt
    sta IER
    lda SR                  ; Clear content of SR


; LCD-display setup
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

; Reset variables
    lda $00
    sta SPI_WRITE
    sta SPI_READ
    sta LCD_COUNT

; Print a string
    lda #'!'
    jsr lcd_write_char
; Finishing reset
    cli                     ; Clear Interrupt disable (i.e. listen for interrupts)

main_lcd_first_line:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command

    lda #$00
    sta LCD_COUNT

main_loop:
    lda SPI_READ
    cmp SPI_WRITE
    bpl main_loop

    lda #'$'
    jsr lcd_write_char

    ldx SPI_READ
    lda SPI_DATA, x
    jsr print_hex_value
    inc SPI_READ
    inc LCD_COUNT

    lda #' '
    jsr lcd_write_char

    lda LCD_COUNT
    cmp #$03
    beq main_lcd_second_line
    lda LCD_COUNT
    cmp #$06
    beq main_lcd_first_line
    jmp main_loop               ; Else continue

main_lcd_second_line:
    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    jmp main_loop

interrupt:
    sei
    pha
    txa
    pha

    lda IFR
    and #%00000100
    beq return_interrupt        ; Only caring about Shift Registers

    ldx SPI_WRITE
    lda SR
    sta SPI_DATA, x
    inc SPI_WRITE

return_interrupt:
    pla
    tax
    pla
    cli
    rti

