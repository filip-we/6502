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

read_scan_code:                 ; Destroys a, x, y.
    lda KB_BUFF_WRITE           ; Will clear any CA-interrupts!
    tay
    lda VIA2_PORTA              ; Clearing CA1-interrupt
    tax
    lda keymap, x
    sta KB_BUFF, y
    inc KB_BUFF_WRITE
    rts

read_scan_code_properly:
    lda VIA2_PORTA
    cmp #$f0
    beq read_scan_code_properly_return

    tax
    lda KB_BUFF_WRITE
    tay
    lda keymap, x
    sta KB_BUFF, y
    inc KB_BUFF_WRITE
read_scan_code_properly_return:
    rts

; Credit to Ben for this nice table
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
  .byte "ö???????????????" ; F0-FF
