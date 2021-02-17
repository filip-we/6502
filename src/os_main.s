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
COMMAND_DATALEN =     $03
PRINT_HEX_TO_ACIA =   $04
TEMP =                $05
TEMP_ADDRESS =        $06     ; 2 bytes

COM_BUF_START =     $0200
COM_BUF_END =       $0201
BOOT_MODE =         $0210

COMMAND_DATA =      $0300
COM_BUF =           $0400

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
    lda #$00                ; Initialize CLI-buffer pointer
    sta COM_BUF_START
    sta COM_BUF_END

    sta BOOT_MODE           ; Set boot mode to standard (=0)
    sta PRINT_HEX_TO_ACIA

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

    lda #(%10000000 | LCD_SECOND_LINE)
    jsr lcd_send_command
    lda #$00                        ; Initialize communication counter
    tay
    cli                             ; Clear Interrupt disable (i.e. listen for interrupt requests)
    ldy #$00                        ; Count rows on LCD
main:
    lda COM_BUF_START
    cmp COM_BUF_END
    bpl main                        ; Branch if COM_BUF_START >= COM_BUF_END

    ; If LCD has 4 or more prints then we clear the display
    cpy #$04
    bmi main_print
    ldy #$00
    lda #%00000001                  ; Clear display
    jsr lcd_send_command
    lda #%00000010                  ; Return cursor home
    jsr lcd_send_command
main_print:
    lda #'$'
    jsr lcd_write_char
    jsr acia_send_char
    ldx COM_BUF_START
    lda COM_BUF, x
    sec
    jsr print_hex_value
    lda #' '
    jsr lcd_write_char
    jsr acia_send_char
    inc COM_BUF_START
    iny
    jmp main


;    ; y=0: store byte in COMMAND_ADDRESS
;    ; 0<y<=2: store byte in COMMAND
;    ; y>3:  store byte in memory COMMAND_ADDRESS, y
;    ;tya
;    cpy #$00
;    beq main_store_command
;    cpy #$03
;    bmi main_store_address
;main_handle_data:
;    lda COMMAND
;    cmp #COMMAND_RDRAM
;    beq command_rdram
;
;main_loop:
;    inc COM_BUF_START               ; Update COM_BUF_START
;    iny
;    jsr main_print_status
;    cpy #$13
;    bmi main
;    ldy #$00                        ; If y > 12 we roll around to #$00
;    jsr main_print_status
;    jmp main
;
;main_print_status:
;; Print current command, address, and y
;    lda #%00000001                  ; Clear display
;    jsr lcd_send_command
;    lda #%00000010                  ; Return cursor home
;    jsr lcd_send_command
;
;    ; THIS IS THE PROBLEM! WE ARE SAVING DATA IN $0000 AND $0001!!! since we set x to be 00 at some point
;    ldx #$80
;    ;dex
;    ;dex
;    lda #>string_debug_command      ; High byte
;    sta 1, x
;    lda #<string_debug_command      ; Low byte
;    sta 0, x
;    jsr print_string_zp
;    ;inx                             ; Free up data stack
;    ;inx
;    lda #(%10000000 | LCD_SECOND_LINE)
;    jsr lcd_send_command
;
;    lda #'$'
;    jsr lcd_write_char
;    lda COMMAND
;    jsr print_hex_value
;    lda #' '
;    jsr lcd_write_char
;
;    lda #'$'
;    jsr lcd_write_char
;    lda COMMAND_ADDRESS + 1
;    jsr print_hex_value
;    lda COMMAND_ADDRESS
;    jsr print_hex_value
;
;    lda #'$'
;    jsr lcd_write_char
;    tya
;    jsr print_hex_value
;    rts
;
;main_store_command:
;    ldx COM_BUF_START
;    lda COM_BUF, x
;    sta COMMAND
;    jmp main_loop
;
;main_store_address:
;    ;ldx COM_BUF_START
;    ;lda COM_BUF, x
;    ;dey                             ; y is either 1 or 2, but offset should be 0 or 1
;    ;sta COMMAND_ADDRESS, y          ; Store acc in COMMAND_ADDRESS + y - #$01 (Does this work on ZP?)
;    ;iny
;    tya
;    pha
;    tax
;    dex
;    ldy COM_BUF_START
;    lda COM_BUF, y
;    sta COMMAND_ADDRESS, x
;    pla
;    tay
;    jmp main_loop
;
;command_rdram:
;    ldx #$00
;command_rdram_loop:
;    lda (COMMAND_ADDRESS, x)
;    jsr acia_send_char
;    inx
;    cpx #$10
;    bne command_rdram_loop
;    ldy #$00                        ; Time for a new round
;    jmp main_loop


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

; ----------------------------------------
; ----- Strings & Tables -----------------
; ----------------------------------------
string_standard_boot_mode:
    .byte "== Iroko v0.5 ==", $00

string_ram_boot_mode:
    .byte "Booting from RAM", $00

table_byte_to_char:
    .byte "0123456789abcdef"

string_debug_command:
    .byte "Cmd Addr  y", $00
;         "$aa $abcd $01"

; ----------------------------------------
; ----- Subroutines ----------------------
; ----------------------------------------
    .segment "SUBROUTINES"

; Protocol
; CMD, ADDRx2, DLEN, DATA...
; Length is 4 + d bytes

; Start parsing new message if the buffer is >3 (and "CMDRDY"-flag is clear)
; Put the CMD, ADDR and DLEN in variables
; We continue to read all data (then we set "CMDRDY"-flag)

; If CMDRDY is set we can take action on the message
; (When we are done with the message we set the CMDRDY-flag to zero)
read_command:
    pha
    txa
    pha
    lda COM_BUF_END
    sec
    sbc COM_BUF_START
    sec
    sbc #PROTOCOL_HEADER_LEN
    bmi read_command                    ; Branch if COM_BUF_START >= COM_BUF_END
    ldx #PROTOCOL_HEADER_LEN - 1
store_command:
    lda COM_BUF_START, x
    sta COMMAND, x
    dex
    bpl store_command
    lda COM_BUF_START
    adc #PROTOCOL_HEADER_LEN
    sta COM_BUF_START


; Here we need to wait for all data bytes to arrive
    lda COMMAND_DATALEN
    beq read_command_return             ; Branch on zero
    tax
    dex
store_command_data:
    lda COM_BUF_START, x
    sta COMMAND_DATA, x
    dex
    bpl store_command_data
read_command_return:
    pla
    tax
    pla
    sei                                 ; Debugging
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
    jsr acia_send_char
print_hex_value_no_acia_1:
    lda STACK, x                    ; Get back accumulator
    and #%00001111
    tay
    lda table_byte_to_char, y
    jsr lcd_write_char
    ldy PRINT_HEX_TO_ACIA
    beq print_hex_value_no_acia_2   ; If carry bit is set we send to ACIA
    jsr acia_send_char
print_hex_value_no_acia_2:
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

