Start:
    .model Spectrum48
    .org #8000
    jp start1

    #include "AnimationData.asm"
    #include "LineDrawer.asm"
    #include "Utils.asm"
    #include "Polygon.asm"
    
start1:
    DI    
    ;
loop0:
    call CLS
    ld b,200
loop1:
    call Random
    ld h,a        
    call Random
    ld d,a
lp1:
    call Random
    cp 192
    jr nc,lp1
    ld l,a    
lp2:    
    call Random
    cp 192
    jr nc,lp2
    ld e,a
    ;    
    push bc    
    ld a,9
    call DrawLine    
    pop bc    
    djnz loop1
    jr loop0
    ;
    ;
    ;------------------
    ld hl,HUMAN_00
    ld b,12    
humanLoop:    
    ld a,$83
    out ($FE),a
    push bc
    ;
    ld de,$4000    
    ld c,7
    ld a,32
outerLoop:
    push de
    ld b,8 
    ld a,c
    ld c,$ff       
innerLoop:
    push de        
    LDI
    LDI
    LDI
    LDI
    pop de
    inc d
    djnz innerLoop
    ;
    pop de
    ld c,a
    ld a,32
    add e
    ld e,a
    dec c
    jr nz, outerLoop
    ;
    

    
    ld b,4
wait:
    call WaitFrame
    djnz wait
    
    pop bc
    djnz humanLoop
ente:
    jp start1


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
    
; ------------------------------------------------------------
WaitFrame:
    push hl
    ld hl, 23672    
    ld a, (hl)      ; Read current frame count
WAIT_LOOP:
    cp (hl)         ; Compare with current frame count
    jr z, WAIT_LOOP    ; Loop until it changes (new frame)
    pop hl
    ret