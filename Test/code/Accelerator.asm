ACC_REGION_SIZE     EQU     40      ; selection radius





; -------------------------------------------------------------
; ACC_update(hl,IX: struct CP start)->():(af,bc,de)
ACC_update:
    push af
    push bc
    push de
    push hl
    ;
    ld de, CP_ACC
    add hl,de
    push hl
    call Random
    inc hl
    ld (hl),a
    call Random
    inc hl
    inc hl
    ld (hl),a
    ld bc, $0100
    pop hl
    call Trim2D
    ; 
    pop hl
    pop de
    pop bc
    pop af
    ret
