; ----------------------------------------------------------
; polygon is stored as:
; numVertices (1b), x,y,x,y,x,y,... as signed bytes
; ----------------------------------------------------------
PolySquare: defb $02,$f6,$f6,$f6,$0a



;
; Poly.draw(b: num vertices, c: mode, hl:pointer to vertices, de:center)->():(?)
Poly.draw:    
    push bc 
    push de
    ld a,(hl)       ; x1
    add d
    ld b,a
    inc hl
    ld a,(hl)
    add e           ; y1
    ld c,a
    push bc         ; x1,y1 -> stack
    ;
    ld a,(hl)       ; x2
    add d
    ld b,a
    inc hl
    ld a,(hl)
    add e           ; y2
    ld c,a    
    ;
    ld h,b
    ld l,c
    pop de
    ;
    xor a
    call DrawLine
    ret
    

