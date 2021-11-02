; Keys from the keyboard are put in the kb-buffer.
; The terminal-buffer contains the text currently editable. The terminal consumes keys from the kb-buffer and adjusts the terminal-buffer accordingly. 
; The terminal also updates the lcd_buffer at the same time,


enter_key:
; Increase lcd_buff_write to beginning of next line
; print #' ' until lcd_buff_write is dividable with LCD_SIZE
    pla                         ; Better now than later.
    clc
    lda lcd_buff_end
    adc #(LCD_WIDTH * 2)
    and #%11110000              ; We want to clear the next row in the lcd-buffer.
    tax
    lda #' '
enter_key_loop:
    dex
    sta lcd_buff, x
    cpx lcd_buff_end
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

    lda term_buff_write         ; Make the buffer cleared to recieve new input.
    sta term_buff_read
    sta term_buff_end

    jmp update_viewing_window

bspc_and_left_key:
    sec
    lda term_buff_write
    sbc term_buff_read          ; The user is not allowed to remove more than the current 
    beq parse_key_return        ; command prompt.
    dec lcd_buff_write
    dec term_buff_write
    jsr update_lcd
    pla
    cmp #KC_LEFT
    beq parse_key_return_direct

; Move all chars after lcd_buff_write one step down.
    ldx lcd_buff_write
bspc_move_buff:
    inx
    lda lcd_buff, x
    dex
    sta lcd_buff, x
    inx
    cpx lcd_buff_end
    bne bspc_move_buff

    lda #' '
    ldx lcd_buff_end
    sta lcd_buff, x
    dec lcd_buff_end            ; The buffer have decreased in length.
    dec term_buff_end
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
    cmp kb_buff_write
    cli
    bpl parse_key_return_direct
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

    pla
    ldx lcd_buff_write
    sta lcd_buff, x
    inc lcd_buff_write

    ldy term_buff_write
    sta term_buff, y
    inc term_buff_write

    lda lcd_buff_write
    sec
    cmp lcd_buff_end
    bmi continue_parse_key
    sta lcd_buff_end
continue_parse_key:
; if term_buff_write > term_buff_end
; then update term_buff_end
    lda term_buff_write
    sec
    cmp term_buff_end
    bmi update_viewing_window
    sta term_buff_end
update_viewing_window:
    sec
    lda lcd_buff_write
    sbc lcd_buff_read
    cmp #(LCD_WIDTH + 1)
    bmi call_lcd_update         ; We span more than one row and need to scroll

    lda lcd_buff_write
    and #((LCD_WIDTH - 1) ^ $FF)
    sec
    sbc #(LCD_WIDTH - 0)
    sta lcd_buff_read

    ;lda lcd_buff_write
    lda lcd_buff_end
    clc
    adc #LCD_WIDTH
    tax
    lda #' '
clear_next_line:
    dex
    sta lcd_buff, x
    ;cpx lcd_buff_write
    cpx lcd_buff_end
    bne clear_next_line

call_lcd_update:
    jsr update_lcd
    rts

down_key:
    lda lcd_buff_read
    clc
    adc #LCD_WIDTH
    sta lcd_buff_read
    jsr update_lcd
    jmp parse_key_return

up_key:
    lda lcd_buff_read
    sec
    sbc #LCD_WIDTH
    sta lcd_buff_read
    jsr update_lcd
    jmp parse_key_return

right_key:
    inc lcd_buff_write
;    lda lcd_buff_write
;    cmp #LCD_SIZE
;    bne main_loop
;    lda #$00
;    sta lcd_buff_write
    jmp parse_key_return


parse_command:
; Print #' ' and advance lcd one line.
; Empty term_buff by advancing term_buff_read


