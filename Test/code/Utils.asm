; ------------------------------------------
; delayMS(ms:hl)->():()
; Input: HL = delay in milliseconds (0–65535)

DelayMS:
    push af
    push bc    
    push de            ; preserve DE
    push hl
DelayLoop:
    ld  b, 255          ; inner loop count (tuned for ~1 ms at 3.5 MHz)
Inner:
    djnz Inner
    dec hl             ; one ms elapsed
    ld  a,h
    or  l
    jr  nz, DelayLoop
    pop hl
    pop de
    pop bc
    pop af
    ret

; ---------------------------------------------------------------------
; Random()->(a):()
; 8 bit Random Generator
RAND_SEED:  defb    0,0
FrameSeedRandom:
        ld hl, 23672
        ld a,(hl)
        ld (RAND_SEED),a
        ret
        
Random:
        push    hl
        push    de
        ld      hl,(RAND_SEED)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (RAND_SEED),hl
        pop     de
        pop     hl
        ret

; ---------------------------------------------------------------------
; Plot(hl: x,y)->():()
PLT_BIT_TABLE:  defb 192,96,48,24,12,6,3,1
Plot:
    push af
    push de
    push hl
    ; Y
    ld a,l
    and $07         ; which intra-line?
    ld d,a          ; *256 (d is address highByte)
    ld a,l
    and $c0         ; which of the 3 regions?
    rra
    scf             ; base address, shifts to $40
    rra
    rra             ; 3 left instead of 5 right = * 2048
    or d                
    ld d,a          ; high byte ready
    ld a,l
    and $38         ; reset carry
    rla             ; character-line * 32
    rla
    ld e,a          ; de is row byte address
    ;
    ; X
    ld a,h          ; X
    and $F8
    rra
    rra
    rra
    or e
    ld e,a          ; byte address in de
    ld a,h
    and $07
    push de
    ld e,a
    ld d,0
    ld hl,PLT_BIT_TABLE
    add hl,de
    ld a,(hl)
    pop hl          ; address in hl
    xor (hl)
    ld (hl),a       ; plot.
    ;
    pop hl
    pop de
    pop af
    ret

; ------------------------------------------------------------
ReadKeyRow:
    ld a,$FE              ; select row 0
    IN   A,($FE)
    AND  %00011111        ; Keep only 5 key bits
    CP   %00011111        ; All high = none pressed
    SCF                    ; Assume pressed
    JR   NZ,$+3            ; If not all high, keep carry set
    CCF                    ; Else clear carry
    RET
