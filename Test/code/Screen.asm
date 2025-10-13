SCR_CENTER_X        EQU         128
SCR_CENTER_Y        EQU         96

COLOR_COUNTER       defw        $0300

; ---------------------------------------------------------
; InitInkAttributes()->():(af,bc,hl)
InitInkAttributes:
    ld bc, 767
    ld hl, $5800
    ld de, $5801
    ld (hl),$07
    LDIR
    ret

; ---------------------------------------------------------
; UpdtaeBackground(e: col, d: row)->(zero flag):(af)
; returns carry set if all cells are blue
; Turns BG to blue
UpdateBackground:     
    push de
    push hl
    ld h,$58
    ld l,e          ; base + col    
    sla d
    sla d
    sla d
    ld e,d
    ld d,0          ; row * 8
    ex de,hl
    add hl,hl
    add hl,hl       ; row * 32    
    add hl,de
    ;    
    ld a,(hl)        
    and $38         ; paper
    jr nz, upbg_checkCellCounter        ; nothing to do
upbg_randInk:
    call Random     ; random ink
    and $07
    cp 2            ; non black, non blue
    jr c, upbg_randInk
    or $08          ; blue paper
    ld (hl),a
    ;
    ;decCounter
    ld hl, COLOR_COUNTER
    ld e,(hl)
    inc hl
    ld d,(hl)
    ;
    dec de    
    ld (hl),d
    dec hl
    ld (hl),e
    ld a,e
    or d
    jr nz,upbg_end
    scf                     ; all blue
    jr upbg_end


    ;
upbg_checkCellCounter:    
    ld hl, COLOR_COUNTER
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld a,e
    or d
    jr nz,upbg_end
    scf                     ; all blue    
    ;
upbg_end:
    pop hl
    pop de    
    ret
    