; Keep a pointer on where to start printing.
; Do linebreak when we have printed LCD_SIZE/2 chars
; Fill row with spaces when encountering an enter.

; Cmd-parsing saved as start and end pointer

update_lcd:
    txa
    pha
    tya
    pha

    lda #LCD_CURSOR_HOME
    jsr lcd_command

    ldy #$00                            ; Keep track on how many chars we have printed
    ldx lcd_buff_read                   ; so we can fill spaces when encountering enter.
update_lcd_loop:
    lda lcd_buff, x
    cmp #KC_ENTER
    beq update_lcd_enter

    jsr lcd_print_char
    inx
    iny
    cpy #(LCD_SIZE / 2)
    beq update_lcd_advance_line
    cpy #LCD_SIZE
    bne update_lcd_loop
    pla
    tay
    pla
    tax
    rts

update_lcd_enter:
    inx
    lda #' '
update_lcd_enter_loop:
    jsr lcd_print_char
    iny
    cpy #(LCD_SIZE / 2)
    beq update_lcd_advance_line
    cpy #LCD_SIZE
    bne update_lcd_enter_loop
    pla
    tay
    pla
    tax
    rts

update_lcd_advance_line:
    lda #LCD_SECOND_LINE
    jsr lcd_command
    jmp update_lcd_loop


