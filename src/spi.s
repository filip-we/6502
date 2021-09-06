;   Execution starting here! At first line!
    .segment "CODE"
    jmp start               ; Jump to main code
    jmp interrupt           ; Jump to interrupt. 4 bytes in, at $0204

;   Other stuff goes here
   .include "via1.s"

    SPI_PORT = PORTA
    SPI_MOSI_PORT_BIT = %10000000
    SPI_MISO_PORT_BIT = %00000010

    BOOT_LABEL = $03a0

; Variables in RAM
    SPI_MOSI_CURRENT_BIT = $00
    SPI_MOSI_WRITE = $01
    SPI_MOSI_READ = $02
    SPI_MOSI_INCOMMING_BYTE = $03

    SPI_MISO_CURRENT_BIT = $05
    SPI_MISO_WRITE = $06
    SPI_MISO_READ = $07

    LCD_COUNT = $10
    temp = $11
    RAM_ADDRESS = $12       ; 2 bytes long

    SPI_MOSI_DATA = $1F00
    SPI_MISO_DATA = $2000



start:
    sei                     ; Set interrupt flag (== interrupts ignored)

; VIA setup
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
    sta SPI_MOSI_CURRENT_BIT
    sta SPI_MOSI_WRITE
    sta SPI_MOSI_READ
    sta SPI_MOSI_INCOMMING_BYTE
    sta SPI_MISO_CURRENT_BIT
    sta SPI_MISO_WRITE
    sta SPI_MISO_READ

    sta LCD_COUNT

    lda $00                 ; Low address
    sta RAM_ADDRESS
    lda $06                 ; High address
    sta RAM_ADDRESS + 1

    lda #'a'
    sta temp

; Print a string
    lda #'!'
    jsr lcd_write_char

; Prime MISO-buffer
    lda #18
    lda SPI_MISO_WRITE

; Finishing reset
    cli                     ; Clear Interrupt disable (i.e. listen for interrupts)


                            ; Count down until booting into $0200
                            ; Poll IFR if data in SR
                            ; When we have data in SR: Write data to current RAM address
main_first:
    lda #$ee
    ldy #0
    sta (RAM_ADDRESS), y
    iny
    sta (RAM_ADDRESS), y
    iny
    sta (RAM_ADDRESS), y
    iny
    sta (RAM_ADDRESS), y
    iny
    sta (RAM_ADDRESS), y
    iny
    sta (RAM_ADDRESS), y
    
    sta $05fa
    sta $05fb
    sta $05fc
    sta $05fd
    sta $05fe
    sta $05ff

    lda PORTA               ; Click button to enter RAM-load
    and #%00010000          ; Checking rightmost button
    beq fake_start          ; Button not pressed - is low - equal to 0
    
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
    lda IFR
    and #%00000100
    bne write_ram
    jmp main_loop

fake_start:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command
    lda #'H'
    jsr lcd_write_char

inf:
    jmp inf


write_ram:
    lda #%00000010 | LCD_CLEAR_DISPLAY      ; Return cursor home
    jsr lcd_send_command
    lda #'$'
    jsr lcd_write_char

    lda RAM_ADDRESS
    jsr print_hex_value
    tay
    lda SR
    sta (RAM_ADDRESS), y
    inc RAM_ADDRESS
    bne main_loop
    inc RAM_ADDRESS + 1
    jmp main_loop


interrupt:
    rti


    sei
    pha
    txa
    pha

    ;lda temp
    ;jsr print_hex_value
    ;inc temp

check_spi_miso:
    lda IFR
    pha
    jsr print_hex_value

    tsx
    inx
    lda __STACK_START__, x
    jsr print_hex_value
    and #%00000010              ; Checking CA1 Interrupts first to do some things every SPI-clock cycle
    beq return_interrupt        ; If not CA1 we cannot have received any MOSI, so quit

    lda #'>'
    jsr lcd_write_char

    inc SPI_MOSI_CURRENT_BIT
    lda SPI_MOSI_CURRENT_BIT
    cmp $08
    bne check_if_miso_data
    lda $00
    sta SPI_MOSI_CURRENT_BIT

check_if_miso_data:
    lda SPI_MISO_WRITE
    cmp SPI_MISO_READ
    beq spi_miso_clear_flag     ; If they are equal we have nothing to send
; Check if it is OK to start a new byte (ie SPI_MISO_CURRENT_BIT + 1 == SPI_MOSI_CURRENT_BIT )
    lda #'I'
    jsr lcd_write_char

    lda SPI_MISO_CURRENT_BIT
    adc #$01                    ; We are one byte ahead because it needs to be ready when the next clock pulse comes
    and #%00000111              ; To catch $08
    cmp SPI_MOSI_CURRENT_BIT
    bne spi_miso_clear_flag     ; Cannot send

    ldx SPI_MISO_READ
    lda SPI_MISO_DATA, x
    and SPI_MOSI_CURRENT_BIT         ; Acc now has next bit to send
    beq spi_miso_send_zero
    lda SPI_MISO_PORT_BIT
    sta SPI_PORT
spi_miso_send_zero:
    lda $00
    sta SPI_PORT
    inc SPI_MISO_READ

    lda #'W'
    jsr lcd_write_char

spi_miso_clear_flag:
    ;lda IFR                     ; Clear IFR CA1 by writing that bit
    ;and #%11111100
    ;sta IFR

check_spi_mosi:
    tsx
    inx
    lda __STACK_START__, x
    and #%00000100              ; Shift Register Interrupt
    beq return_interrupt

    lda #'O'
    jsr lcd_write_char

    ldx SPI_MOSI_WRITE
    lda SR
    sta SPI_MOSI_DATA, x
    inc SPI_MOSI_WRITE

return_interrupt:
    pla
    tax
    pla
    cli
    rti


spi_via_tx_rx:
; NOT TESTED
    clc
    lda SPI_PORT
    and SPI_MOSI_PORT_BIT
    beq spi_mosi_zero
    sec
spi_mosi_zero:
    rol SPI_MOSI_INCOMMING_BYTE
    lda SPI_MOSI_CURRENT_BIT         ; If this is zero we have received the whole byte
    bne spi_via_tx_rx_return

    lda SPI_MOSI_INCOMMING_BYTE
    ldx SPI_MOSI_WRITE
    sta SPI_MOSI_DATA, x
    inc SPI_MOSI_WRITE
    lda #$08                    ; Next rond we start a new byte.
    sta SPI_MOSI_CURRENT_BIT

spi_via_tx_rx_return:
    dec SPI_MOSI_CURRENT_BIT         ; Update bit number
    rts

    .org SPI_MISO_DATA          ; Priming some data to send
string_s:
    .byte "=== Iroko 0.2  ===", $00
