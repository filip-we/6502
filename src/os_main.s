    .include "acia.s"
    .include "via1.s"

    .import __STACK_START__
    ;.import __RAMPROG_LOAD__

; ----------------------------------------
; ----- CONSTANTS ------------------------
; ----------------------------------------
COMMAND_RDRAM = $01
COMMAND_WRRAM = $02
COMMAND_BOOT = $ff

; ----------------------------------------
; ----- ADDRESSES ------------------------
; ----------------------------------------
STACK = __STACK_START__

COMMAND = $00
COMMAND_ADDRESS = $01
;RAM_BOOT_COMMAND_BOOT_NOW = $0f

; Communication buffer
COM_MODE =        $0200       ; 0=read/write to terminal
COM_BUF_START =   $0201
COM_BUF_END =     $0202
COM_PRINT_START = $0203
COM_BUF =       $0300

BOOT_MODE = $0210
;RAM_BOOT_COMMAND = $0211
;RAM_BOOT_ADDRESS = $0212

    .segment "CODE"

;push_axy:
;.macro
;    pha
;    txa
;    pha
;    tya
;    pha
;.endmacro

; ----------------------------------------
; ----- Reset ----------------------------
; ----------------------------------------
reset:
    sei
    ldx #$ff                ; Initialize stack pointers for data and hardware stacks
    txs
    lda #$00                ; Initialize CLI-buffer pointer
    sta COM_MODE            ; Initialize communication mode
    sta COM_BUF_START
    sta COM_BUF_END
    sta COM_PRINT_START

    sta BOOT_MODE           ; Set boot mode to standard (=0)

; VIA setup
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
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
    lda #%00011111          ; No stop bit, 8 bit word, Baud-generator, 19,200 bit/s
    sta ACIA_CONTROL

; Send clear-terminal command
    jsr send_clear_terminal_cmd

; Boot mode selection
    lda PORTA               ; Read Port A
    and #%00000001          ; Get least significant bit of Port A
    ;cmp #%00000000          ; Compare with 0
    beq ram_boot_mode; Branch if result is zero (i.e. boot mode)
    jmp standard_boot_mode

; ----------------------------------------
; ----- RAM-boot mode --------------------
; ----------------------------------------
ram_boot_mode:
    lda #$01
    sta BOOT_MODE                   ; RAM-write boot-mode is $01
    dex
    dex
    lda #>string_ram_boot_mode      ; High byte
    sta 1, x
    lda #<string_ram_boot_mode      ; Low byte
    sta 0, x
    jsr print_string
    inx                             ; Free up data stack
    inx
    cli
    ;jmp RAMPROG
    jmp $1000

;ram_boot_loop:
;    jmp ram_boot_loop
;    cmp RAM_BOOT_COMMAND_BOOT_NOW
;    bne ram_boot_loop
;    jmp $1000

; ----------------------------------------
; ----- Normal boot-mode -----------------
; ----------------------------------------
standard_boot_mode:
    dex
    dex
    lda #>string_standard_boot_mode ; High byte
    sta 1, x
    lda #<string_standard_boot_mode ; Low byte
    sta 0, x
    jsr print_string
    inx                             ; Free up data stack
    inx

    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    lda #'>'
    jsr lcd_write_char
    jsr acia_send_char
    lda #$00                        ; Initialize communication counter
    tay
    cli                             ; Clear Interrupt disable (i.e. listen for interrupt requests)

main:
    lda COM_BUF_START
    cmp COM_BUF_END
    bpl main                        ; Branch if COM_BUF_START >= COM_BUF_END

    ; y=0: store byte in COMMAND_ADDRESS
    ; 0<y<=2: store byte in COMMAND
    ; y>3:  store byte in memory COMMAND_ADDRESS, y
    tya
    cmp #$00
    beq main_store_command
    cmp #$03
    bmi main_store_address
main_handle_data:
    lda COMMAND
    cmp #COMMAND_RDRAM
    beq command_rdram

main_loop:
    inc COM_BUF_START               ; Update COM_BUF_START
    iny
    cmp #$12
    bmi main
    lda #$00                        ; If y > 12 we roll around to #$00
    tay
    jmp main

main_store_command:
    lda #%00000001        ; Clear display
    jsr lcd_send_command
    lda #%00000010        ; Return cursor home
    jsr lcd_send_command
    lda #'C'
    jsr lcd_write_char
    lda #'M'
    jsr lcd_write_char
    lda #'D'
    jsr lcd_write_char
    lda #':'
    jsr lcd_write_char

    lda COM_BUF_START
    tax
    lda COM_BUF, x
    sta COMMAND
    jsr print_hex_value
    lda #'@'
    jsr lcd_write_char
    jmp main_loop

main_store_address:
    dey                             ; y is either 1 or 2, but offset should be 0 or 1
    lda COM_BUF_START
    tax
    lda COM_BUF, x
    sta COMMAND_ADDRESS, y          ; Store acc in COMMAND_ADDRESS + y - #$01 (Does this work on ZP?)
    jsr print_hex_value
    iny
    jmp main_loop

command_rdram:
    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command

    lda #$00
    tax
    lda (COMMAND_ADDRESS, x)
    jsr print_hex_value
    jsr acia_send_char
    jmp main_loop

nl_char_detected:
    lda #$0d
    jsr acia_send_char
    lda #$0a
    jsr acia_send_char
    lda #' '
    jsr lcd_write_char
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
    lda #'>'
    jsr lcd_write_char

    ldx COM_BUF_START
    stx COM_BUF_END
    rts

; ----------------------------------------
; ----- Subroutines & interrupts ---------
; ----------------------------------------
interrupt:
    rti

non_maskable_interrupt:
    sei
    pha
    txa
    pha
    ;lda BOOT_MODE                       ; Check if we are in RAM-boot mode
    ;cmp #$01
    ;beq ram_boot_interrupt
;standard_interrupt:
    tya
    pha
    jsr acia_receive_char               ; Read char if available
    bcc return_from_standard_interrupt  ; Return if no char available
    ldx COM_BUF_END
    sta COM_BUF,x                       ; Store received byte in the buffer.
    inc COM_BUF_END
return_from_standard_interrupt:
    pla
    tay
    pla
    tax
    pla
    cli
    rti

;return_from_ram_boot_interrupt:
;    iny
;    cmp #$12                    ; Reset y if y > 12
;    bmi return_from_ram_boot_interrupt_no_overflow
;    lda #$00
;    tay
;return_from_ram_boot_interrupt_no_overflow:
;    pla
;    tax
;    pla
;    cli
;    rti

; Read three incomming bytes as an instruction.
; Instruction: "page write", "boot/done" or "unknown"
; We send the bytes in the order they are saved in the memory, staring at $00
;ram_boot_interrupt:
;    jsr acia_receive_char       ; Read char if available
;    bcc return_from_ram_boot_interrupt ; Return if no char available
;    pha
;    tya                         ; y stores the counter for the data
;
;    ;cmp #$01
;    ;bmi ram_boot_command        ; First byte is the command
;    ;cmp #$02
;    ;bmi ram_boot_low_address    ; Second and third bytes are the address
;    ;cmp #$03
;    ;bmi ram_boot_high_address   ; Second and third bytes are the address
;    ;cmp #$14
;    ;bmi ram_boot_data           ; Third up to and including 13th byte is data
;
;    cmp #$12
;    bpl ram_boot_high_address   ; Branch if y >= $12
;    cmp #$11
;    bpl ram_boot_low_address    ; Branch if y = $11
;    cmp #$10
;    bpl ram_boot_command        ; Branch if y = $10
;    ; If we got this far y > $10
;    jmp ram_boot_data
;
;ram_boot_command:
;    pla
;    sta RAM_BOOT_COMMAND
;    jmp return_from_ram_boot_interrupt
;
;ram_boot_low_address:
;    pla
;    sta RAM_BOOT_ADDRESS
;    jmp return_from_ram_boot_interrupt
;
;ram_boot_high_address:
;    pla
;    sta RAM_BOOT_ADDRESS + 1
;    jmp return_from_ram_boot_interrupt
;
;ram_boot_data:
;    tya
;    tax                         ; x is not used in the boot interrupt
;    pla                         ; retreive the data from acc.
;    sta ($00, x)                ; (Store data in RAM_BOOT_ADDRESS + x)
;    jmp return_from_ram_boot_interrupt

; ----------------------------------------
; ----- Strings & Tables -----------------
; ----------------------------------------
string_standard_boot_mode:
    .byte "== Iroko v0.5 ==", $00

string_ram_boot_mode:
    .byte "Booting from RAM", $00

table_byte_to_char:
    .byte "0123456789abcdef"

; ----------------------------------------
; ----- Common Subroutines ---------------
; ----------------------------------------
    .segment "SUBROUTINES"

print_string:
    lda ($00, x)  ; Finds the address at top of the data stack and loads the accumulator with value from that address
    cmp #$00
    beq print_string_return
    jsr lcd_write_char
    jsr acia_send_char
    inc $00, x
    bne print_string
    inc $01, x
    bne print_string
print_string_return:
    rts

send_clear_terminal_cmd:
    lda #$1b
    jsr acia_send_char
    lda #$5b
    jsr acia_send_char
    lda #$32
    jsr acia_send_char
    lda #$4a
    jsr acia_send_char
    rts

print_hex_value:
    pha
    txa
    pha
    tya
    pha

    lda #'$'
    jsr lcd_write_char
;    jsr acia_send_char

    tsx
    inx
    inx
    lda STACK, x            ; Get back accumulator
    lsr
    lsr
    lsr
    lsr
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr lcd_write_char
;    jsr acia_send_char

    lda STACK, x            ; Get back accumulator
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr lcd_write_char
;    jsr acia_send_char

    pla
    tay
    pla
    tax
    pla
    rts

; ----------------------------------------
; ----- Address Vectors ------------------
; ----------------------------------------
    .segment "VECTORS"
    .word interrupt
    .word reset
    .word non_maskable_interrupt

