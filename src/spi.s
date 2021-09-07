; This is work in progress and a bit of copy paste from other files
   .import __ZP_START__

    SPI_PORT = PORTA
    SPI_MOSI_PORT_BIT = %10000000
    SPI_MISO_PORT_BIT = %00000010

; Variables in RAM
    SPI_MOSI_CURRENT_BIT    = __ZP_START__ + 0
    SPI_MOSI_WRITE          = __ZP_START__ + 1
    SPI_MOSI_READ           = __ZP_START__ + 2
    SPI_MOSI_INCOMMING_BYTE = __ZP_START__ + 3

    SPI_MISO_CURRENT_BIT    = __ZP_START__ + 4
    SPI_MISO_WRITE          = __ZP_START__ + 5
    SPI_MISO_READ           = __ZP_START__ + 6

    LCD_COUNT               = __ZP_START__ + 7

    SPI_MOSI_DATA = $1F00
    SPI_MISO_DATA = $2000

interrupt:
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
