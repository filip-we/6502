PRINT_STRING = $e000

    .org $1000
    dex
    dex
    lda #>test_string               ; High byte
    sta 1, x
    lda #<test_string               ; Low byte
    sta 0, x
    jsr PRINT_STRING
    inx                             ; Free up data stack
    inx


test_string:
    .byte "Det är otroligt", $00

