read_buttons:
    ldx #5
    lda #%00100000                  ; Buttons are at PBA1-PBA4
    sta button_pin_nr
read_buttons_loop:
    dex
    lda button_pin_nr
    clc
    ror
    sta button_pin_nr
    txa
    beq button_return

    lda button_pin_nr
    and VIA1_PORTA
    beq button_not_pressed          ; We don't care if the button is not pressed

    inc button_counters, x
    lda button_counters, x
    cmp #$20                        ; Count triggering threshold
    bne read_buttons_loop

    ldy kb_buff_write
    lda char_map, x
    sta kb_buff, y
    inc kb_buff_write
    jmp read_buttons_loop

button_not_pressed:
    lda #0                          ; We don't count how long the button is NOT pressed. Just reset the counter.
    sta button_counters, x
    jmp read_buttons_loop
button_return:
    rts


