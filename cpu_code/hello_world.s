PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E =  %10000000
RW = %01000000
RS = %00100000

DEBUG_IRQ =   %00000001
DEBUG_1 =     %00000010
DEBUG_2 =     %00000100
DEBUG_3 =     %00001000

LCD_SECOND_LINE = $40

; ACIA
ACIA_DATA = $7000
ACIA_STATUS = ACIA_DATA + 1
ACIA_COMMAND = ACIA_DATA + 2
ACIA_CONTROL = ACIA_DATA + 3

; Communication buffer
COM_MODE =        $00       ; 0=read/write to terminal
COM_BUF_START =   $01
COM_BUF_END =     $02
COM_PRINT_START = $03
COM_BUF =       $0200

    .org $8000              ; Tells compiler where the ROM is located in the address space.

reset:
    ldx #$ff                ; Initialize stack pointer
    txs
    lda #$00                ; Initialize CLI-buffer pointer
    sta COM_MODE            ; Initialize communication mode
    sta COM_BUF_START
    sta COM_BUF_END
    sta COM_PRINT_START

; VIA setup
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11111111          ; Set all pins on port A to output
    sta DDRA


; LCD-display setup
    lda #%00000001        ; Clear display
    jsr lcd_send_command
    lda #%00000010        ; Return cursor home
    jsr lcd_send_command
    lda #%00000110        ; Entry mode
    jsr lcd_send_command
    lda #%00001111        ; Turning on display
    jsr lcd_send_command
    lda #%00111000        ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_send_command

; ACIA setup
;         ppmeTTRd
    lda #%00001001        ;Odd parity, parity mode disabled, no echo, tx interrupt disabled, rx interrupt disabled
    sta ACIA_COMMAND
    lda #%00011111
    sta ACIA_CONTROL


print_welcome:            ; Print welcome message
    ldx #$00
print_loop:
    lda string_welcome,x
    beq init_lcd_cursor
    jsr acia_send_char
    jsr lcd_write_char
    inx
    jmp print_loop
init_lcd_cursor:
    lda #$0d                ; Send \r and \n
    jsr acia_send_char
    lda #$0a
    jsr acia_send_char
    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    lda #">"
    jsr lcd_write_char

    lda #$0a
    jsr lcd_write_char
    lda #$0c
    jsr lcd_write_char
    lda #$0d
    jsr lcd_write_char

    cli                   ; Clear Interrupt disable (i.e. listen for interrupt requests)



; ----------------------------------------
; ----- Main -----------------------------
; ----------------------------------------
main:
    lda COM_MODE
    cmp #$00
    bne main                ; Only handle buffer if we are in command-mode
    jsr print_new_chars     ; Check and print any new chars.
    jsr check_cli_cmd_ready ; If we have recevied an enter/newline we interpret a command
    bcs execute_cli_cmd
    jmp main

; When an acia interrupt is triggered we save the byte to the buffer
; All bytes are written into a circular buffer. We update the pointer and the length when reading/handling bytes. Also check for overflow.

; In the main function we print to LCD and to ACIA. We keep track on where in the buffer we have printed with another pointer. We can disable printing by changing COM_MODE.
; In the main function we also check if a command is ready. It is detected by checking if the last byte is a newline.

print_new_chars:
    lda COM_PRINT_START
    cmp COM_BUF_END
    beq print_new_chars_return ; If buffer length is zero we don't print. Overflow-safe if COM_BUF_END is not increased all the way up to COM_PRINT_START.
print_new_chars_loop:
    ldx COM_PRINT_START
    lda COM_BUF,x
    jsr acia_send_char
    cmp #$0a            ; Ignore [return]
    beq print_new_chars_loop_check
    cmp #$0d            ; Execute command if [newline]
    beq print_new_chars_loop_check
    jsr lcd_write_char
print_new_chars_loop_check:
; check if LCD end of line
    inx
    stx COM_PRINT_START
    cpx COM_BUF_END
    bne print_new_chars_loop    ; Loop until buffer is empty
print_new_chars_return:
    rts

check_cli_cmd_ready:
    ldx COM_BUF_END
    lda COM_BUF,x
    cmp #$0a            ; Ignore [return]
    beq check_cli_cmd_ready_return_not_ready
    cmp #$0d            ; Execute command if [newline]
    beq check_cli_cmd_ready_return_ready
check_cli_cmd_ready_return_not_ready:
    clc
    rts
check_cli_cmd_ready_return_ready:
    sec
    rts


execute_cli_cmd:
    lda #%00000001        ; Clear display
    jsr lcd_send_command
    lda #%00000010        ; Return cursor home
    jsr lcd_send_command
    lda #$0d                ; Send \r and \n
    jsr acia_send_char
    lda #$0a
    jsr acia_send_char
    ldx COM_BUF_START
execute_cli_cmd_print_buffer_loop:
    lda COM_BUF, x
    jsr lcd_write_char
    inx
    cpx COM_BUF_END
    bne execute_cli_cmd_print_buffer_loop

    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    lda #">"
    jsr lcd_write_char

    ldx COM_BUF_START
    stx COM_BUF_END
    rts


interrupt:
    pha
    txa
    pha
    tya
    pha

    lda #DEBUG_IRQ
    sta PORTA
    jsr acia_receive_char         ; Read char if available
    bcc return_from_interrupt     ; Return if no char available
    jsr acia_interrupt
return_from_interrupt:
    pla
    tay
    pla
    tax
    pla
    rti


acia_receive_char:                ; Reads a char from ACIA if there is one
    clc
    lda ACIA_STATUS
    and #%00001000                ; Check if ReceiverDataRegisterFull
    beq acia_receive_char_return  ; Move if ReceiverDataRegisterFull was not set
    lda ACIA_DATA
    sec
acia_receive_char_return:
    rts


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


acia_interrupt:
    ldx COM_BUF_END         ; Store all incomming bytes in the buffer.
    sta COM_BUF,x
    inx
    stx COM_BUF_END
    rts


lcd_send_command:
    jsr lcd_wait
    sta PORTB
    lda #0
    sta PORTA
    lda #E
    sta PORTA
    lda #0
    sta PORTA
    rts


lcd_write_char:
    jsr lcd_wait
    sta PORTB
    pha
    lda #RS
    sta PORTA
    lda #(RS | E) ; Sending instruction by toggling E bit
    sta PORTA
    lda #RS
    sta PORTA
    pla
    rts


lcd_wait:
    pha
    lda #$00
    sta DDRB
lcd_wait_loop:
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000        ; Check BusyFlag bit. Will set the Z flag if the result is zero, ie lcd is not busy
    bne lcd_wait_loop

    lda #RW
    sta PORTA
    lda #$ff
    sta DDRB
    pla
    rts

delay_x_y:
delay_loop_x:
    dex
    bne delay_loop_x
delay_loop_y:
    dey
    bne delay_loop_y
    rts


string_welcome:
    .byte "== Iroko v0.1 ==", $00

cmd_test:
    .byte "hej", $00

    .org $fffa
    .word interrupt
    .word reset
    .word interrupt
