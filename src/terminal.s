; Keys from the keyboard are put in the kb-buffer.
; The terminal-buffer contains the text currently editable. The terminal consumes keys from the kb-buffer and adjusts the terminal-buffer accordingly. 
; The terminal also updates the lcd_buffer at the same time,

bspc_key:
    sec
    lda term_buff_write
    sbc term_buff_read
    beq parse_key_return        ; The user is not allowed to remove more than the current 
                                ; command prompt.
    dec lcd_buff_write
    ldx lcd_buff_write
    lda #' '
    sta lcd_buff, x
    jsr update_lcd
    txa
    cmp #$FF
    bne main_loop
    lda #(LCD_SIZE - 1)
    sta lcd_buff_write

    dec term_buff_write
    rts

down_key:
    lda lcd_buff_read
    clc
    adc #LCD_SIZE / 2
    sta lcd_buff_read
    jsr update_lcd
    rts

up_key:
    lda lcd_buff_read
    sec
    sbc #LCD_SIZE / 2
    sta lcd_buff_read
    jsr update_lcd
    rts

left_key:
    dec lcd_buff_write
    lda lcd_buff_write
    cmp #$FF
    bne main_loop
    lda #(LCD_SIZE - 1)
    sta lcd_buff_write
    rts

right_key:
    inc lcd_buff_write
    lda lcd_buff_write
    cmp #LCD_SIZE
    bne main_loop
    lda #$00
    sta lcd_buff_write
    rts

parse_key_return:
    rts

parse_key:
    sei
    lda kb_buff_read
    cmp kb_buff_write
    cli
    bpl parse_key_return
    sei

    ldx kb_buff_read
    lda kb_buff, x
    inc kb_buff_read

    pha
    cmp #KC_BSPC                ; Check all keys which require special treatment in either
    beq bspc_key                ; of term_buff, lcd_buff or both
    cmp #KC_LEFT
    beq left_key
    cmp #KC_RIGHT
    beq right_key
    cmp #KC_DOWN
    beq down_key
    cmp #KC_UP
    beq up_key

    pla
    ldx lcd_buff_write
    sta lcd_buff, x

    ldy term_buff_write
    sta term_buff, y
    inc term_buff_write

    sec
    lda lcd_buff_write
    sbc lcd_buff_read
    cmp #LCD_SIZE / 2
    bmi call_lcd_update         ; We span more than one row and need to scroll

    lda lcd_buff_write
    and #%11110000
    sec
    sbc #16
    sta lcd_buff_read

call_lcd_update:
    jsr update_lcd
    inx
    stx lcd_buff_write
    jmp main_loop

parse_command:
; Print #' ' and advance lcd one line.
; Empty term_buff by advancing term_buff_read


; Keep a pointer on where to start printing.
; Do linebreak when we have printed LCD_SIZE/2 chars
; Fill row with spaces when encountering an enter.

; Cmd-parsing saved as start and end pointer

;update_lcd:                            ; Commented because we do the lcd-printing the
;    txa                                ; simpler way
;    pha
;    tya
;    pha
;
;    lda #LCD_CURSOR_HOME
;    jsr lcd_command
;
;    ldy #$00                            ; Keep track on how many chars we have printed
;    ldx lcd_buff_read                   ; so we can fill spaces when encountering enter.
;update_lcd_loop:
;    lda lcd_buff, x
;    cmp #KC_ENTER
;    beq update_lcd_enter
;
;    jsr lcd_print_char
;    inx
;    iny
;    cpy #(LCD_SIZE / 2)
;    beq update_lcd_advance_line
;    cpy #LCD_SIZE
;    bne update_lcd_loop
;    pla
;    tay
;    pla
;    tax
;    rts
;
;update_lcd_enter:
;    lda lcd_buff_read
;    and #%11110000
;    sec
;    sbc #16
;    sta lcd_buff_read
;
;    inx
;    lda #' '
;update_lcd_enter_loop:
;    jsr lcd_print_char
;    iny
;    cpy #(LCD_SIZE / 2)
;    beq update_lcd_advance_line
;    cpy #LCD_SIZE
;    bne update_lcd_enter_loop
;    pla
;    tay
;    pla
;    tax
;    rts
;
;update_lcd_advance_line:
;    lda #LCD_SECOND_LINE
;    jsr lcd_command
;    jmp update_lcd_loop


