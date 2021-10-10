.import __VIA2_START__

VIA2_PORTB          = __VIA2_START__
VIA2_PORTA          = __VIA2_START__ + 1
VIA2_DDRB           = __VIA2_START__ + 2
VIA2_DDRA           = __VIA2_START__ + 3
VIA2_T1C_L          = __VIA2_START__ + $04
VIA2_T1C_H          = __VIA2_START__ + $05
VIA2_T1L_L          = __VIA2_START__ + $06
VIA2_T1L_H          = __VIA2_START__ + $07
VIA2_SR             = __VIA2_START__ + $0A
VIA2_ACR            = __VIA2_START__ + $0B
VIA2_PCR            = __VIA2_START__ + $0C
VIA2_IFR            = __VIA2_START__ + $0D
VIA2_IER            = __VIA2_START__ + $0E


VIA2_IFR_CA2        = %00000001
VIA2_IFR_CA1        = %00000010
VIA2_IFR_SR         = %00000100
VIA2_IFR_CB2        = %00001000
VIA2_IFR_CB1        = %00010000
VIA2_IFR_T2         = %00100000
VIA2_IFR_T1         = %01000000

VIA2_PS2_PORTB_CTL  = %00000111             ; Stop-, parity- and start-bit
PS2_CTL_MASK        = %00000101             ; Ignore parity for now.
PS2_CTL_CMP         = %00000100             ; Stop bit should be 1, parity ignored, startbit 0

RELEASE_FLAG        = %00000001             ; Flags for keyboard status
EXTENDED_FLAG       = %00000010
SHIFT_FLAG          = %00000100
CTRL_FLAG           = %00001000

read_keyboard:                              ; Destroys a, x, y.
    ldx #$ff
check_control_bits:
    lda VIA2_PORTB                          ; We want to check the control-bits first.
    and #PS2_CTL_MASK
    cmp #PS2_CTL_CMP
    beq read_scan_code
    dex
    bne check_control_bits
    lda VIA2_PORTA                          ; The control-bits are not correct. We need to
    rts                                     ; clear the interrupt and return.

read_scan_code:
    lda kb_flags                            ; Since scan codes are entirely different for
    and #EXTENDED_FLAG                      ; extended codes we checks that first.
    bne read_extended_key

;   ----------------------------------------------------------------
;   1-scan code keys
;   ----------------------------------------------------------------
    lda kb_flags
    and #RELEASE_FLAG
    bne key_released

read_key:
    lda VIA2_PORTA
    cmp #$F0
    beq set_release_flag
    cmp #$E0
    beq set_extended_flag
    cmp #$12
    beq shift_pressed
    cmp #$59
    beq shift_pressed                       ; If it was neither shift or $f0 we read the key.
    cmp #$14
    beq ctrl_pressed

    tax
    lda kb_flags
    and #SHIFT_FLAG
    bne load_shifted_key

    lda keymap, x
store_key:
    tax
    lda kb_buff_write
    tay
    txa
    sta kb_buff, y
    inc kb_buff_write
    rts

key_released:
    lda kb_flags                            ; The releseflag was set so we need reset
    eor #RELEASE_FLAG                       ; it to handle the comming scan code normally.
    sta kb_flags

    lda VIA2_PORTA                          ; Clear interrupt
    cmp #$12
    beq shift_released
    cmp #$59
    beq shift_released

    cmp #$14
    beq ctrl_released
    cmp #$59
    beq ctrl_released                        ; We don't care to record if "normal" keys
    rts                                      ; where released.
load_shifted_key:
    lda keymap_shifted, x
    jmp store_key

;   ----------------------------------------------------------------
;   Extended keys
;   ----------------------------------------------------------------
read_extended_key:
    lda kb_flags
    eor #EXTENDED_FLAG
    sta kb_flags
    lda kb_flags
    and #RELEASE_FLAG
    bne extended_key_released

    lda VIA2_PORTA
    cmp #$F0
    beq set_release_flag
    cmp #$14
    beq ctrl_pressed

    tax
    lda keymap_extended, x
    jmp store_key

extended_key_released:
    lda VIA2_PORTA                          ; Clear interrupt
    cmp #$14
    beq ctrl_released
    rts

;   ----------------------------------------------------------------
;   Set and reset routines
;   ----------------------------------------------------------------
set_extended_flag:
    lda kb_flags
    ora #EXTENDED_FLAG
    sta kb_flags
    rts

set_release_flag:
    lda kb_flags
    ora #RELEASE_FLAG
    sta kb_flags
    rts

shift_pressed:
    lda kb_flags
    ora #SHIFT_FLAG
    sta kb_flags
    rts

ctrl_pressed:
    lda kb_flags
    ora #CTRL_FLAG
    sta kb_flags
    rts

shift_released:
    lda kb_flags
    eor #SHIFT_FLAG
    sta kb_flags
    rts

ctrl_released:
    lda kb_flags
    eor #CTRL_FLAG
    sta kb_flags
    rts


; Credit to Ben for these nice table
keymap:
  .byte $00,$09,$00,$05, $03,$01,$02,$0C ; 00-08
  .byte $0A,$08,$06,$00, $00," `",$00 ; 08-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=????",$0A,"]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568",$1B,"?",$0B,"+3-*9??" ; 70-7F ; Esc and F11
  .byte "???",$07,"????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

keymap_shifted:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q!???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte "??'?{+?????}?|??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

keymap_extended:
  .byte "????????????????" ; 00-0F
  .byte "???????????????+" ; 10-1F
  .byte "???????+???????A" ; 20-2F              ; Apps
  .byte "????????????????" ; 30-3F
  .byte "??????????/?????" ; 40-4F
  .byte "??????????", $0A, "?????" ; 50-5F      ; KP-Enter
  .byte "?????????E?", $11, "H???" ; 60-6F      ; Left
  .byte "I", $20, $12, "?", $14, $13, "????", $15, "??", $16, "??" ; 70-7F  ; Del, Down, right, up, Pg D/U
  .byte "????????????????" ; 80-8F

