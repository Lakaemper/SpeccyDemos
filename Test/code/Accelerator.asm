ACC_REGION_SIZE     EQU     40      ; selection radius





; -------------------------------------------------------------
; ACC_update(hl,IX: struct CP start)->():()
ACC_update:
    push af
    push bc
    push de
    push hl
    ;    
    ld de, CP_ACC
    add hl,de    
    call Random                 ; random strength
    ld (hl),a
    call random                 ; determine direction
    sub 128
    jr c, acc_posX
    ld a,(hl)
    cpl
    ld (hl),a
    inc hl
    ld (hl),255
    jr acc_doY
acc_posX:    
    inc hl
    ld (hl),0
acc_doY:        
    inc hl
    call Random
    ld (hl),a
    call random
    cp 128
    jr c, acc_posY
    ld a,(hl)
    cpl
    ld (hl),a
    inc hl
    ld (hl),255
    jr acc_done
acc_posY:
    inc hl
    ld (hl),0    
    ; 
acc_done:    
    pop hl
    pop de
    pop bc
    pop af
    ret
