    .include "acia.s"
    .include "via1.s"

    .import __STACK_START__
    .import __ROM_START__
    ;.import __RAMPROG_LOAD__

; ----------------------------------------
; ----- CONSTANTS ------------------------
; ----------------------------------------
COMMAND_RDRAM = $01
COMMAND_WRRAM = $02
COMMAND_BOOT = $ff

PROTOCOL_HEADER_LEN = $04
; ----------------------------------------
; ----- ADDRESSES ------------------------
; ----------------------------------------
STACK = __STACK_START__

COMMAND =             $00
COMMAND_ADDRESS =     $01
COMMAND_DATALEN =     $03     ; 2 bytes

PRINT_HEX_TO_ACIA =   $04
TEMP =                $05
TEMP_ADDRESS =        $06     ; 2 bytes

COM_BUF_START =     $0200
COM_BUF_END =       $0201
BOOT_MODE =         $0210

COM_BUF =           $0300

COMMAND_DATA =      $0400

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
    sei                     ; Set interrupt flag (== interrupts ignored)
    cld                     ; Clear decimal flag (== integer mode)
    ldx #$ff                ; Initialize stack pointers for data and hardware stacks
    txs
    lda #$00
    inx
reset_loop:
    dex
    sta $00, x
    sta $0200, x
    bne reset_loop

; VIA setup
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11111110          ; Set PA0 to input, PA1 to PA7 to output
    sta DDRA

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

; ACIA setup
;         ppmeTTRd
    lda #%00001001          ;Odd parity, parity mode disabled, no echo, tx interrupt disabled, rx interrupt disabled
    sta ACIA_COMMAND
    lda #%00011111          ; No stop bit, 8 bit word, Baud-generator, 19,200 bit/s
    sta ACIA_CONTROL

    jsr send_clear_terminal_cmd

; Boot mode selection
    lda PORTA               ; Read Port A
    and #%00000001          ; Get least significant bit of Port A
    beq ram_boot_mode       ; Branch if result is zero (i.e. boot mode)
    jmp standard_boot_mode

; ----------------------------------------
; ----- RAM-boot mode --------------------
; ----------------------------------------
ram_boot_mode:
    lda #$01
    sta BOOT_MODE                   ; RAM-write boot-mode is $01
    lda #<string_ram_boot_mode      ; Low byte
    sta TEMP_ADDRESS
    lda #>string_ram_boot_mode      ; High byte
    sta TEMP_ADDRESS + 1
    jsr print_string
    cli
ram_boot_loop:
    jmp ram_boot_loop
;    cmp RAM_BOOT_COMMAND_BOOT_NOW
;    bne ram_boot_loop
;    jmp $1000
;    jmp RAMPROG

; ----------------------------------------
; ----- Normal boot-mode -----------------
; ----------------------------------------
standard_boot_mode:
    inc PRINT_HEX_TO_ACIA           ; Will also send to ACIA
    lda #<string_standard_boot_mode ; Low byte
    sta TEMP_ADDRESS
    lda #>string_standard_boot_mode ; High byte
    sta TEMP_ADDRESS + 1
    ldy #$00
    jsr print_string

    ;lda #(%10000000 | LCD_SECOND_LINE)
    lda #%00000010                  ; Return cursor home
    jsr lcd_send_command
    lda #$00                        ; Initialize communication counter
    tay
    cli                             ; Clear Interrupt disable (i.e. listen for interrupt requests)

main:
    jsr print_com_status
    jsr send_mem_report
main_loop:
    lda COM_BUF_START
    cmp COM_BUF_END
    bpl main_loop
    jsr print_com_status

    jsr read_command
    jsr print_com_status
    jsr send_mem_report
    jsr write_command

    jsr print_com_status
    jsr send_mem_report
    jmp main

;    ldx #$00
;main_loop_2:
;    lda COMMAND, x
;    jsr acia_send_char
;    inx
;    cpx #$03
;    bne main_loop_2
;    lda #$0d
;    jsr acia_send_char
;    lda #$0a
;    jsr acia_send_char


send_mem_report:
    jsr send_clear_terminal_cmd
    lda #'Z'
    jsr acia_send_char
    lda #'P'
    jsr acia_send_char
    lda #':'
    jsr acia_send_char

    ldx #$00
send_mem_report_zp:
    lda $00, x
    jsr send_hex_value
    lda #$20
    jsr acia_send_char
    inx
    cpx #$10
    bne send_mem_report_zp

    lda #$0d
    jsr acia_send_char
    lda #$0a
    jsr acia_send_char

    lda #'B'
    jsr acia_send_char
    lda #'F'
    jsr acia_send_char
    lda #':'
    jsr acia_send_char

    ldx #$00
send_mem_report_buffer:
    lda COM_BUF, x
    jsr send_hex_value
    lda #$20
    jsr acia_send_char
    inx
    cpx #$10
    bne send_mem_report_buffer
    rts

; ----------------------------------------
; ----- Interrupts -----------------------
; ----------------------------------------
interrupt:
    rti

non_maskable_interrupt:
    sei
    pha
    txa
    pha
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
; ----- Subroutines ----------------------
; ----------------------------------------
    .segment "SUBROUTINES"

read_command:
    pha
    txa
    pha
read_command_wait_for_cmd:
    lda COM_BUF_END
    sec
    sbc COM_BUF_START
    sec
    sbc #PROTOCOL_HEADER_LEN
    bmi read_command_wait_for_cmd       ; Seems to work in emulator
    jsr print_com_status                ; Debug
    lda COM_BUF_START
    clc
    adc #PROTOCOL_HEADER_LEN
    sta COM_BUF_START
    tax
    ldy #PROTOCOL_HEADER_LEN
read_command_store_header:
    dex
    dey
    lda COM_BUF, x
    sta COMMAND, y
    cpx #$00
    bne read_command_store_header
    jsr print_com_status                ; Debug
read_command_wait_for_data:
    lda COM_BUF_END
    sec
    sbc COM_BUF_START
    sec
    sbc COMMAND_DATALEN
    bmi read_command_wait_for_data
    jsr print_com_status                ; Debug
    lda COM_BUF_START
    clc
    adc COMMAND_DATALEN
    sta COM_BUF_START
    tay
    ldx COMMAND_DATALEN
    beq read_command_return             ; Branch if COMMAND_DATALEN = 0
    jsr print_com_status                ; Debug
read_command_store_data:
    dey
    dex
    lda COM_BUF, y
    sta COMMAND_DATA, x
    bne read_command_store_data
read_command_return:
    pla
    tax
    pla
    rts

write_command:
    pha
    txa
    pha
    ldx #$00
write_command_to_acia:
    lda COMMAND, x
    jsr acia_send_char
    inx
    cpx PROTOCOL_HEADER_LEN
    bne write_command_to_acia
    lda COMMAND_DATALEN
    beq write_command_return
    ldx #$00
write_command_data_to_acia:
    lda COMMAND_DATA, x
    jsr acia_send_char
    inx
    cpx COMMAND_DATALEN
    bne write_command_data_to_acia
write_command_return:
    pla
    tax
    pla
    rts

print_com_status:
    lda #LCD_CURSOR_HOME
    jsr lcd_send_command

    lda #'$'
    jsr lcd_write_char
    lda COM_BUF_START
    clc                                 ;clear carry bit to not send to acia
    jsr print_hex_value
    lda #'$'
    jsr lcd_write_char
    lda COM_BUF_END
    clc                                 ;clear carry bit to not send to acia
    jsr print_hex_value
    lda #' '
    jsr lcd_write_char

    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    lda #'$'
    jsr lcd_write_char
    ldx #$00
print_com_status_loop:
    lda COMMAND, x
    clc                                 ;clear carry bit to not send to acia
    jsr print_hex_value
    inx
    cpx #$04
    bne print_com_status_loop
    lda #' '
    jsr lcd_write_char
    rts

print_string:
; Prints a string whose pointer is located in address TEMP_ADDRESS. y is where to start printing. Currently uses both a, x and y
    ldx PRINT_HEX_TO_ACIA
print_string_loop:
    lda (TEMP_ADDRESS), y
    cmp #$00
    beq print_string_return
    cpx #$00
    beq print_string_no_acia
    jsr acia_send_char
print_string_no_acia:
    jsr lcd_write_char
    iny
    jmp print_string_loop
print_string_return:
    rts

send_clear_terminal_cmd:
    lda #$1b
    jsr acia_send_char
    lda #'['
    jsr acia_send_char
    lda #'2'
    jsr acia_send_char
    lda #'J'
    jsr acia_send_char
    lda #$1b
    jsr acia_send_char
    lda #'['
    jsr acia_send_char
    lda #';'
    jsr acia_send_char
    lda #'f'
    jsr acia_send_char
    rts

print_hex_value:
    pha
    txa
    pha
    tya
    pha
    tsx
    inx
    inx
    inx
    lda STACK, x                    ; Get back accumulator
    lsr
    lsr
    lsr
    lsr
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr lcd_write_char
    ldy PRINT_HEX_TO_ACIA
    beq print_hex_value_no_acia_1   ; If carry bit is set we send to ACIA
    ;jsr acia_send_char
print_hex_value_no_acia_1:
    lda STACK, x                    ; Get back accumulator
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr lcd_write_char
    ldy PRINT_HEX_TO_ACIA
    beq print_hex_value_no_acia_2   ; If carry bit is set we send to ACIA
    ;jsr acia_send_char
    sec
    jmp print_hex_value_acia_2
print_hex_value_no_acia_2:
    clc                             ; Restore carry-bit
print_hex_value_acia_2:
    pla
    tay
    pla
    tax
    pla
    rts

send_hex_value:
    pha
    txa
    pha
    tya
    pha
    tsx
    inx
    inx
    inx
    lda STACK, x                    ; Get back accumulator
    lsr
    lsr
    lsr
    lsr
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr acia_send_char
    lda STACK, x                    ; Get back accumulator
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr acia_send_char
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

