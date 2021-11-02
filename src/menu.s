;   ----------------------------------------------------------------
;   Imports & Constants
;   ----------------------------------------------------------------
.import __ZP_START__

LCD_SIZE        = 32
LCD_WIDTH       = 16
LCD_HIGHT       = 2
KB_POLL         = $0340
WELCOME_MSG_LEN = LCD_WIDTH * 2

;   ----------------------------------------------------------------
;   Zeropage, Startingvectors, Bufferts & Reset Vectors
;   ----------------------------------------------------------------
.segment "ZEROPAGE": zeropage
.include "zeropage.s"

.segment "VECTORS"
.byte $0000
.byte $0000
.byte $0000

.segment "SIXTY5O2VECTORS"  ; Execution starts here, at $0200
    jmp start               ; Jump to main code. Instrction is 3 bytes long.
    jmp nmi                 ; Instruction is 3 bytes long and thus starts at $0203.

.segment "DATA"
kb_buff:        .res $100
term_buff:      .res $100
lcd_buff:       .res $100

welcome_msg:
    .byte "== Iroko 0.3 == "
    .byte "Hejsan!         ", $00

char_map:
    .byte $00, "UDLR", $00

;   ----------------------------------------------------------------
;   Code
;   ----------------------------------------------------------------
.segment "CODE"
.include "via.s"
.include "ps2_keyboard.s"
.include "terminal.s"

start:
    sei                     ; Only needed since we get here from other code, not a hardware reset
; Reset variables
    lda #0
    ldx #<__ZP_START__
reset_loop:
    sta $00, x
    inx
    bne reset_loop

    lda #(WELCOME_MSG_LEN - 1)
    sta lcd_buff_write

    ldx #32
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

    lda #<KB_POLL               ; Load T1-counter
    sta VIA1_T1L_L
    lda #>KB_POLL
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
    lda #%00000110              ; Entry mode
    jsr lcd_command
    lda #%00111000              ; Set to 8 bit mode, 1 line display, standard font
    jsr lcd_command
    lda #LCD_DISPLAY_ON
    jsr lcd_command

; Disabled since the terminal takes care of screen clearing when needed.
;clear_lcd:
;    ldx lcd_buff_write
;    lda #' '
;clear_lcd_loop:
;    inx
;    sta lcd_buff, x
;    cpx #$FF
;    bne clear_lcd_loop
    jsr update_lcd

    cli                         ; Ready to receive interrupts

main:
    lda #$00
    sta kb_buff_read
    sta kb_buff_write
start_loop:
    lda kb_buff_read        ; We want to keep the start message until user starts to type
    cmp kb_buff_write
    bpl start_loop
start_clear_lcd:
    ldx kb_buff_read        ; Convert first key-press to KC_ENTER will allow smooth start
    lda #KC_ENTER           ; of the terminal.
    sta kb_buff, x
    clc
    lda lcd_buff_read
    adc #LCD_WIDTH
    sta lcd_buff_read

main_loop:
    jsr parse_key
    jmp main_loop

update_lcd:                         ; Destructive on A
; Keep track on where we want to start to print in lcd_buff_read. It thus is allways dividable with 16.
; Update lcd_buff_read when (lcd_buff_write - lcd_buff_read > LCD_SIZE)
; I think the comparison will work automatically if we check for equality (with every read key) and not larger than.
; If we recognize an Enter we print Spaces on the rest of the line and switch to the next line.
    txa
    pha
    tya
    pha
    lda #LCD_CURSOR_HOME
    jsr lcd_command

    clc
    lda lcd_buff_read
    adc #LCD_SIZE / 2
    sta lcd_buff_read_lcd_size_half
    clc
    adc #LCD_SIZE / 2
    sta lcd_buff_read_lcd_size_full
update_lcd_loop_start:
    ldx lcd_buff_read
update_lcd_loop:
    lda lcd_buff, x
    jsr lcd_print_char
    inx
    cpx lcd_buff_read_lcd_size_half
    beq update_lcd_advance_line
    cpx lcd_buff_read_lcd_size_full
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
;    jsr read_buttons                    ; Disabling to save time when uploadnig code.
    lda VIA1_T1C_L                       ; Reset Interrupt-flag
    jmp isr_ifr_check

isr_VIA2_CA1:
    jsr read_keyboard
    jmp isr_ifr_check

nmi:
    rti

