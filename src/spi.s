;   Execution starting here! At first line!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp interrupt           ; Jump to interrupt. 4 bytes in, at $0204

;   Other stuff goes here
   .include "via1.s"

    SPI_PORT = PORTA
    SPI_MOSI_PORT_BIT = %01000000
    SPI_MISO_PORT_BIT = %10000000


; Variables in RAM
    SPI_MOSI_WRITE = $00
    SPI_MOSI_READ = $01
    SPI_MOSI_INCOMMING_BYTE = $02
    SPI_CURRENT_BIT = $05

    LCD_COUNT = $10

    SPI_MOSI_DATA = $1F00


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
    sta SPI_MOSI_WRITE
    sta SPI_MOSI_READ
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
    lda SPI_MOSI_READ
    cmp SPI_MOSI_WRITE
    bpl main_loop

    lda #'$'
    jsr lcd_write_char

    ldx SPI_MOSI_READ
    lda SPI_MOSI_DATA, x
    jsr print_hex_value
    inc SPI_MOSI_READ
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

shift_register_read:
    ldx SPI_MOSI_WRITE
    lda SR
    sta SPI_MOSI_DATA, x
    inc SPI_MOSI_WRITE
    rts

interrupt:
    sei
    pha
    txa
    pha

    lda IFR
    and #%00000100
    beq return_interrupt        ; Only caring about Shift Registers
    jsr shift_register_read

return_interrupt:
    pla
    tax
    pla
    cli
    rti


; Bit-banged SPI slave
    lda #$00
    sta SPI_CURRENT_BIT
    sta SPI_MOSI_INCOMMING_BYTE


spi_via_tx_rx:
; Run with every SCK-pulse
    clc
    lda SPI_PORT
    and SPI_MOSI_PORT_BIT
    beq spi_mosi_zero
    sec
spi_mosi_zero:
    rol SPI_MOSI_INCOMMING_BYTE
    lda SPI_CURRENT_BIT         ; If this is zero we have received the whole byte
    bne spi_via_tx_rx_return

    lda SPI_MOSI_INCOMMING_BYTE
    ldx SPI_MOSI_WRITE
    sta SPI_MOSI_DATA, x
    inc SPI_MOSI_WRITE
    lda #$08                    ; Next rond we start a new byte.
    sta SPI_CURRENT_BIT

spi_via_tx_rx_return:
    dec SPI_CURRENT_BIT         ; Update bit number
    rts
