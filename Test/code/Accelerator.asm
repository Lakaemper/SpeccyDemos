ACC_update:
    push hl

    ld (IX+CP_ACC),$80
    ld (IX+CP_ACC+1),$00
    ld (IX+CP_ACC+2),$80
    ld (IX+CP_ACC+3),$00
    
    pop hl
    ret
