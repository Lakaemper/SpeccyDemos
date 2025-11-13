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
UTILS_STACK_SAVE:       dw 0
CLS:
        push bc
        push hl
        ld (UTILS_STACK_SAVE),SP
        ld SP,$5800
        ld hl,0
        ld b,192
loopCls:        
        push hl         ; 16 pushes
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        djnz loopCls
        ;
        ld SP,(UTILS_STACK_SAVE)
        pop hl
        pop bc
        ret   