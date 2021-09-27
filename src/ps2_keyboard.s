
read_scan_code:
    lda DDRB                ; Reads a byte from port A.
    pha                     ; Will restore the state of the DDR:s before returning.

    lda #$00
    sta DDRB
    lda PORTA               ; Will clear CA1-interrupt
    lda #$00
    sta PORTA               ; Toggle output-enable for shift-registers

    lda KB_BUFF_WRITE
    tay
    lda PORTB
    tax
    lda keymap, x
    sta KB_BUFF, y
    inc KB_BUFF_WRITE

    lda #$01
    sta PORTA               ; We do not want the shift-registers to interfer with the LCD

    pla
    sta DDRB
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
  .byte "????????????????" ; F0-FF