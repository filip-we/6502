; Keys from the keyboard are put in the kb-buffer.
; The terminal consumes keys from the kb-buffer and adjusts the cmd-pointers accordingly. 
; The terminal updates the lcd_buffer at the same time,

enter_key:
    pla                         ; Better now than later.
    clc
    lda lcd_buff_cmd_end
    adc #(LCD_WIDTH * 2)
    and #%11110000              ; We want to clear the next row in the lcd-buffer.
    tax
    lda #' '
enter_key_loop:
    dex
    sta lcd_buff, x
    cpx lcd_buff_cmd_end
    bne enter_key_loop

    txa
    clc
    adc #LCD_WIDTH
    and #%11110000
    sta lcd_buff_write          ; Update lcd_buff_write

; Parse command and print output

    ldx lcd_buff_write          ; Parsing command may destroy a, x or y
    lda #'>'
    sta lcd_buff, x
    inc lcd_buff_write

    lda lcd_buff_write          ; Make the buffer cleared to recieve new input.
    sta lcd_buff_cmd_start
    sta lcd_buff_cmd_end

    jmp update_viewing_window

bspc_and_left_key:
    sec
    lda lcd_buff_write
    sbc lcd_buff_cmd_start      ; The user is not allowed to remove more than the current 
    beq parse_key_return        ; command prompt.
    dec lcd_buff_write
    jsr update_lcd
    pla
    cmp #KC_LEFT
    beq parse_key_return_direct

    ldx lcd_buff_write          ; Move all chars after lcd_buff_write one step down.
bspc_move_buff:
    inx
    lda lcd_buff, x
    dex
    sta lcd_buff, x
    inx
    cpx lcd_buff_cmd_end
    bne bspc_move_buff

    lda #' '
    ldx lcd_buff_cmd_end
    sta lcd_buff, x
    dec lcd_buff_cmd_end        ; The buffer have decreased in length.
    jsr update_lcd
    jmp parse_key_return_direct

parse_key_return:
    pla
    rts

parse_key_return_direct:
    rts

parse_key:
    sei
    lda kb_buff_read
    sec
    sbc kb_buff_write
    cli
    bcs parse_key_return_direct
    sei

    ldx kb_buff_read
    lda kb_buff, x
    inc kb_buff_read

    pha
    cmp #KC_ENTER
    beq enter_key
    cmp #KC_BSPC                ; Check all keys which require special treatment in either
    beq bspc_and_left_key       ; of term_buff, lcd_buff or both
    cmp #KC_LEFT
    beq bspc_and_left_key
    cmp #KC_RIGHT
    beq right_key
    cmp #KC_DOWN
    beq down_key
    cmp #KC_UP
    beq up_key
    jmp normal_key

right_key:
    sec
    lda lcd_buff_write
    sbc lcd_buff_cmd_end
    beq parse_key_return
    inc lcd_buff_write
    jmp parse_key_return

down_key:
    lda lcd_buff_display        ; We only want to shift the display if we end up
    clc                         ; before the cursor.
    adc #(LCD_HEIGHT * LCD_WIDTH)
    cmp lcd_buff_write
    bcs down_key_stop

    lda lcd_buff_display
    clc
    adc #LCD_WIDTH
    sta lcd_buff_display
down_key_stop:
    jsr update_lcd
    jmp parse_key_return

up_key:
    lda lcd_buff_display        ; Skip scroll if lcd_buff_display - lcd_buff_start
    sec                         ; < LCD_WIDTH
    sbc lcd_buff_start
    cmp #LCD_WIDTH
    bcc up_key_stop

    lda lcd_buff_display
    sec
    sbc #LCD_WIDTH
    sta lcd_buff_display
up_key_stop:
    jsr update_lcd
    jmp parse_key_return

normal_key:
;    lda lcd_buff_write              ; If we are about to wrap around lcd_buff we need 
;    and #((LCD_WIDTH - 1) ^ $FF)    ; to increase the start pointer.
;    clc
;    adc #(LCD_HEIGHT * LCD_WIDTH)
;    sec
;    sbc lcd_buff_start
;    bcc focus_display

    lda lcd_buff_start
    sec
    sbc #((LCD_HEIGHT + 1) * LCD_WIDTH)
    sec
    cmp #lcd_buff_write
    bcs start_shift_chars       ; Skip update if result >= lcd_buff_write

    lda lcd_buff_start
    clc
    adc #LCD_WIDTH
    sta lcd_buff_start

start_shift_chars:
    lda lcd_buff_cmd_end        ; If the user is typing anywhere but the end of the buffer
    cmp lcd_buff_write          ; we need to shift the characters after the cursor 
    beq push_key                ; to the right.

    ldx lcd_buff_cmd_end
shift_chars:
    lda lcd_buff, x
    inx
    sta lcd_buff, x
    dex
    dex
    sec
    cpx lcd_buff_write
    bcs shift_chars
    inc lcd_buff_cmd_end

push_key:
    pla
    ldx lcd_buff_write
    sta lcd_buff, x
    inc lcd_buff_write

    lda lcd_buff_write          ; Update lcd_buff_cmd_key to cover all printed chars.
    sec
    cmp lcd_buff_cmd_end
    bcc update_viewing_window

    sta lcd_buff_cmd_end
update_viewing_window:
    sec
    lda lcd_buff_write
    sbc lcd_buff_display
    cmp #(LCD_WIDTH + 1)
    bcc call_lcd_update         ; We span more than one row and need to scroll

    lda lcd_buff_write
    and #((LCD_WIDTH - 1) ^ $FF)
    sec
    sbc #LCD_WIDTH
    sta lcd_buff_display

    lda lcd_buff_cmd_end
    clc
    adc #LCD_WIDTH
    tax
    lda #' '
clear_next_line:
    dex
    sta lcd_buff, x
    cpx lcd_buff_cmd_end
    bne clear_next_line

call_lcd_update:
    jsr update_lcd
    rts

