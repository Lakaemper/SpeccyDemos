SCR_CENTER_X        EQU         128
SCR_CENTER_Y        EQU         96

COLOR_COUNTER       defw        $0300
STACK_STORE         defw        0

BASE_PATTERN:   defb      %11000111
                defb      %10000011
                defb      %00000001
                defb      %00000101
                defb      %00000101
                defb      %10001011
                defb      %11000111
                defb      %11111111

; ---------------------------------------------------------
; InitScreen()->():(af,bc,hl)
; Places the initial tokens on the screen
; very specific for a repeating 8x8 pattern
InitScreen:
    DI
    push IX

    ld hl,COLOR_COUNTER
    ld (HL),$03
    inc hl
    ld (hl),0

    ; attributes: red or magenta BG, black FG
    ld bc,768
    ld hl,$5800
lp:
    call Random
    and 4
    jr z,iscr_1
    ld (hl),$10
    jr iscr_2
iscr_1:
    ld (hl),$18
iscr_2:
    inc hl
    dec bc
    ld a,b
    or c
    jr nz, lp

    ; 
    ; hires pattern
    ld (STACK_STORE),SP         ; save stack
    ld IX, BASE_PATTERN-1    
    ld hl,$4000
    ld c,8
iscr_outlp:    
    inc IX
    ld d,(IX)                   ; load line pattern twice
    ld e,d
    inc h                       ; next line, +256
    ld b,128                    ; 32 * 8 / 2
    ld SP,hl                    ; end of first line, first region
iscr_lp0:
    push de
    djnz iscr_lp0
    ;
    ld b,128
    ld a,h
    add 8
    ld h,a                      ; 32 * 8 / 2
    ld SP,hl                    ; end of first line, second region
iscr_lp1:
    push de
    djnz iscr_lp1
    ;
    ld b,128
    ld a,h
    add 8
    ld h,a    
    ld SP,hl                    ; end of first line, third region
iscr_lp2:
    push de
    djnz iscr_lp2

    ld a,h
    sub 16
    ld h,a

    dec c
    jr nz, iscr_outlp
    ;
    ld SP,(STACK_STORE)    
    pop IX
    EI    
    ret

; ---------------------------------------------------------
; AnimateBG ()->():(af,bc,de,hl)
; Change color of random background balls
AnimateBG:
    ld b,10                 ; 10 attempts
    ; random in 0..767
anm_loop:    
    xor a
    ld h,a
    ld l,a
    ld d,a    
    call random
    ld e,a
    add hl,de
    add hl,de
    add hl,de
    ld d,0
    call Random
    and $03
    ld e,a
    add hl,de
    ld de,$5800
    add hl,de
    ;
    ; check if BG non zero
    ld a,(HL)
    and $38
    jr z,anm_nextAttempt
    xor $08
    ld (hl),a
    ;
anm_nextAttempt:
    djnz anm_loop
    ret

; ---------------------------------------------------------
; ClearChar(e: col, d: row)->():()
ClearChar:    
    push af
    push de
    push hl
    ;
    ld a,d
    and $18             ; segment 0-2
    or $40              ; base address
    ld h,a
    ld a,d    
    rrc a               ; row (in segment) * 32
    rrc a
    rrc a
    and $E0
    or e                ; col
    ld l,a              ; hl = address
    xor a
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ld (hl),a
    inc h
    ;
    pop hl
    pop de
    pop af
    ret

; ---------------------------------------------------------
; UpdateBackground(e: col, d: row)->(carry flag):(af)
; returns carry set if all cells are blue
; Turns BG to Black, erases character
UpdateBackground:     
    push hl
    push de
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
    jr z, upbg_checkCellCounter        ; nothing to do
    ;
    ; Clear character in cell
    pop de
    push de    
    call ClearChar    
    ;
upbg_randInk:         
    call Random     ; random ink
    and $07    
    jr z, upbg_randInk  ; non black ink, black paper    
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
    pop de
    pop hl    
    ret
    