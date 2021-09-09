    .import __ACIA_START__

ACIA_DATA = __ACIA_START__
ACIA_STATUS = ACIA_DATA + 1
ACIA_COMMAND = ACIA_DATA + 2
ACIA_CONTROL = ACIA_DATA + 3

acia_send_char:
    pha
    txa
    pha
    tya
    pha
    lda ACIA_STATUS               ; For good measure
    ldx #$ff
    ldy #$03
    jsr delay_x_y
    pla
    tay
    pla
    tax
    pla
    sta ACIA_DATA
    rts

acia_receive_char:                ; Reads a char from ACIA if there is one
    clc
    lda ACIA_STATUS
    and #%00001000                ; Check if ReceiverDataRegisterFull
    beq acia_receive_char_return  ; Move if ReceiverDataRegisterFull was not set
    lda ACIA_DATA
    sec
acia_receive_char_return:
    rts

acia_send_string:
    lda ($00, x)  ; Finds the address at top of the data stack and loads the accumulator with value from that address
    cmp #$00
    beq acia_send_string_return
    jsr acia_send_char
    inc $00, x
    bne acia_send_string
    inc $01, x
    bne acia_send_string
acia_send_string_return:
    rts

delay_x_y:
delay_loop_x:
    dex
    bne delay_loop_x
delay_loop_y:
    dey
    bne delay_loop_y
    rts
