;   ----------------------------------------------------------------
;   Execution starting here, at $0200!
    .segment "CODE"
    jmp start               ; Jump to main code. Instrction is 3 bytes long.
    jmp nmi                 ; Jump to NMI-handler. Instruction is 3 bytes long and starts 3 bytes in, at $0203.
;   ----------------------------------------------------------------
    .include "via.s"
    .include "ps2_keyboard.s"

; Variables
    ZP_START        = $10
    addr_a          = ZP_START + $10
    addr_b          = ZP_START + $12

    button_counters = ZP_START + $20        ; 4 bytes long
    button_pin_nr   = ZP_START + $2A
    pulse_counter   = ZP_START + $2B

    kb_buff_write   = ZP_START + $30
    kb_buff_read    = ZP_START + $31
    lcd_buff_write  = ZP_START + $32
    lcd_buff_read   = ZP_START + $33
    temp            = ZP_START + $34
    kb_flags        = ZP_START + $35
    lcd_buff        = ZP_START + $D0        ; 2x16 bytes, ending at $110F

    kb_buff         = $3000                 ; $ff bytes long

; Constants
    kb_poll         = $0340

start:
    sei                     ; Only needed since we get here from other code, not a hardware reset
; Reset variables
    lda #0
    ldx ZP_START
reset_loop:
    sta $00, x
    inx
    bne reset_loop

    sta pulse_counter

    ldx #33
lcd_ram_init:
    dex
    lda welcome_msg, x
    sta lcd_buff, x
    cpx #$00
    bne lcd_ram_init

; IRQ setup
    lda #<isr
    sta $04
    lda #>isr
    sta $05

; VIA-1 setup
    lda #%00000001              ; Disable shift-register output
    sta VIA1_PORTA
    lda #%11100001              ; Set PA1 to PA4 to input, PA0, PA5 to PA7 to output
    sta VIA1_DDRA
    lda #%11111111              ; Set all pins on port B to output
    sta VIA1_DDRB
    lda #%00000001              ; Set CB/CA to input, positive active edge.
    sta VIA1_PCR
    lda #%01000000              ; Enable T1 continous interrupts without PB7-pulsing
    sta VIA1_ACR

    lda #<kb_poll               ; Load T1-counter
    sta VIA1_T1L_L
    lda #>kb_poll
    sta VIA1_T1L_H
    sta VIA1_T1C_H
    lda VIA1_T1C_L              ; Clear Interrupt-bit
    lda #%11000000              ; Enable T1-interrupts
    sta VIA1_IER

; VIA-2 setup
    lda #$00                    ; The PS2-interface is connected to VIA2_PORTA
    sta VIA2_DDRA               ;
    lda #( ^ VIA2_PS2_PORTB_CTL | %10000000)
    sta VIA2_DDRB               ;
    lda #%00000001              ; Set CB/CA to input, positive active edge.
    sta VIA2_PCR                ;
    lda #%10000010              ; Enable CA1-interrupts
    sta VIA2_IER
    lda #%10000000              ; Light a litte nice debugging-LED
    sta VIA2_PORTB

; LCD-display setup
    lda #LCD_CLEAR_DISPLAY
    jsr lcd_command
    lda #LCD_CURSOR_HOME
    jsr lcd_command
    lda #%00000110              ; Entry mode
    jsr lcd_command
    lda #%00111000              ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_command
    lda #LCD_DISPLAY_ON
    jsr lcd_command
    jsr update_lcd

    cli                         ; Ready to receive interrupts
    jmp main

temp_main:
    ldx #64
temp_main_1:
    ldy #0
temp_main_2:
    dey
    bne temp_main_2
    dex
    bne temp_main_1

    lda #LCD_CLEAR_DISPLAY
    jsr lcd_command
    lda #LCD_CURSOR_HOME
    jsr lcd_command

    lda #'$'
    jsr lcd_print_char
    lda pulse_counter
    jsr lcd_print_hex_byte

    jmp temp_main

main:
;start_loop:
;    lda kb_buff_read        ; We want to keep the start message until user starts to type
;    cmp kb_buff_write
;    bpl start_loop
;    ldx #33
;    lda #' '
;start_clear_lcd:
;    dex
;    sta lcd_buff, x
;    cpx #0
;    bne start_clear_lcd

main_loop:
    sei
    lda kb_buff_read
    cmp kb_buff_write
    cli
    bpl main_loop
    sei

    ldx kb_buff_read
    lda kb_buff, x
    inc kb_buff_read

    ldx lcd_buff_write
    sta lcd_buff, x
    jsr update_lcd
    inx
    stx lcd_buff_write
    cpx #33
    bne main_loop
    lda #0
    sta lcd_buff_write
    jmp main_loop

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

update_lcd:                         ; Destructive on A
    txa
    pha
    tya
    pha
    lda #LCD_CURSOR_HOME
    jsr lcd_command

    ldx #0
update_lcd_loop:
    lda lcd_buff, x
    jsr lcd_print_char
    inx
    cpx #16
    beq update_lcd_advance_line
    cpx #32
    bne update_lcd_loop
    pla
    tay
    pla
    tax
    rts

update_lcd_advance_line:
    lda #LCD_SECOND_LINE
    jsr lcd_command
    jmp update_lcd_loop


temp_isr:
    pha

    inc pulse_counter
    lda VIA1_PORTA                       ; Clear CA1-interrupt

    pla
    rti

isr:
    pha
    txa
    pha
    tya
    pha

isr_ifr_check:
    lda VIA1_IFR                    ; Checking VIA1
    asl                             ; T1
    bmi isr_VIA1_T1
    asl                             ; T2
    asl                             ; CB1
    asl                             ; CB2
    asl                             ; SR
    asl                             ; CA1
    asl                             ; CA2

    lda VIA2_IFR                    ; Checking VIA2
    asl                             ; T1
    asl                             ; T2
    asl                             ; CB1
    asl                             ; CB2
    asl                             ; SR
    asl                             ; CA1
    bmi isr_VIA2_CA1
    asl                             ; CA2
return_isr:
    pla
    tay
    pla
    tax
    pla
    rti

isr_VIA1_T1:
    jsr read_buttons
    lda VIA1_T1C_L                       ; Reset Interrupt-flag
    jmp isr_ifr_check

isr_VIA2_CA1:
    jsr read_scan_code
    jmp isr_ifr_check

nmi:
    rti

test_text:
    .byte "Hejsan!", $00

welcome_msg:
    .byte "0123456789abcdef", "0123456789abcdef", $00

char_map:
    .byte 0, "UDLR", 0
