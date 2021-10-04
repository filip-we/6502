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
SHIFT_FLAG          = %00000010
CTL_FLAG            = %00000010

read_scan_code:                             ; Destroys a, x, y.
    ldx #$ff
read_scan_code_poll:
    lda VIA2_PORTB                          ; We want to check the control-bits first.
    and #PS2_CTL_MASK                  ;
    cmp #PS2_CTL_CMP                        ;
    beq read_scan_code_verified             ;
    dex
    bne read_scan_code_poll
    lda VIA2_PORTA                          ; We have failed and need to clear the interrupt,
    rts                                     ; and need to return.

read_scan_code_verified:
    lda KB_FLAGS
    and #RELEASE_FLAG
    beq read_key

    lda KB_FLAGS                            ; If the releseflag was set we need to check
    eor #RELEASE_FLAG                       ; if the modifiers where released.
    sta KB_FLAGS

    lda VIA2_PORTA                          ; Clear interrupt
    cmp #$12
    beq shift_released
    lda KB_FLAGS
    cmp #$59
    beq shift_released
    lda KB_FLAGS                            ; If neither of the shifts where released,
    rts                                     ; we don't care.

shift_released:
    lda KB_FLAGS
    eor #SHIFT_FLAG
    sta KB_FLAGS
    rts

read_key:
    lda VIA2_PORTA
    cmp #$f0
    beq set_release_flag
    cmp #$12
    beq shift_pressed
    cmp #$59
    beq shift_pressed                       ; If it was neither shift or $f0 we read the key.

    tax
    lda KB_FLAGS
    and #SHIFT_FLAG
    beq normal_key

    lda keymap, x
normal_key:
    lda keymap, x

    tax
    lda KB_BUFF_WRITE
    tay
    txa
    sta KB_BUFF, y
    inc KB_BUFF_WRITE
    rts

set_release_flag:
    lda KB_FLAGS
    ora #RELEASE_FLAG
    sta KB_FLAGS
    rts

shift_pressed:
    lda KB_FLAGS
    ora #SHIFT_FLAG
    sta KB_FLAGS
    rts

ctrl_pressed:
    lda KB_FLAGS
    ora #CTL_FLAG
    sta KB_FLAGS
    rts

; Credit to Ben for these nice tabl
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=????",$0a,"]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568",$1b,"??+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

;keymap_shifted:
;  .byte "????????????? ~?" ; 00-0F
;  .byte "?????Q!???ZSAW@?" ; 10-1F
;  .byte "?CXDE#$?? VFTR%?" ; 20-2F
;  .byte "?NBHGY^???MJU&*?" ; 30-3F
;  .byte "?<KIO)(??>?L:P_?" ; 40-4F
;  .byte "??'?{+?????}?|??" ; 50-5F
;  .byte "?????????1?47???" ; 60-6F
;  .byte "0.2568???+3-*9??" ; 70-7F
;  .byte "????????????????" ; 80-8F
;  .byte "????????????????" ; 90-9F
;  .byte "????????????????" ; A0-AF
;  .byte "????????????????" ; B0-BF
;  .byte "????????????????" ; C0-CF
;  .byte "????????????????" ; D0-DF
;  .byte "????????????????" ; E0-EF
;  .byte "????????????????" ; F0-FF
