; ------------------------------------------------------
; Implementation of Bresenham's Line Drawing Algorithm
; ------------------------------------------------------
; DrawLine(de->(x1,y1), hl->(x2,y2), a=0: make interrupt safe)->():(?)
IRFLAG:         defb 0              ; Flag if routine was made interrupt safe
; jump addresses for conditional jumps to handle different octants
DL_JUMP_TABLE:  defw dl_oct4_belowT, dl_oct4_geqT, dl_oct5_belowT, dl_oct5_geqT
                defw dl_oct6_belowT, dl_oct6_geqT, dl_oct7_belowT, dl_oct7_geqT
DL_TEMP_STACK:  defw 0
DrawLine:
        ld (IRFLAG),a
        and a
        jr nz,dl_start
        ; if interrupt on call was enabled, 
        ; save registers (debug mode with ROM routines enabled)
        DI        
        exx
        push bc
        push de
        push hl
        push IX
        push IY
        exx
        ;        
        ; Start of draw line routine
dl_start:                     
        ; Truncate y1, y2 to max 191
        ld a,e
        and $3f
        ld e,a
        ld a,l
        and $3f
        ld l,a
        ;
        ; start = end? => plot and leave
        push hl
        and a
        sbc hl,de
        ld a,h
        or l
        pop hl
        jr nz, dl_realLine
        ;
        ; Plot single dot
        call GetStartPattern
        ld d,a
        jr dl_endBresenham
        ;
dl_realLine:
        ; make sure to draw direction down (y2 >= y1)
        ld a,e
        cp l                ; TODO: fast horizontal
        jr c, dl_yOrderOK
        ex de,hl            ; e <= l  (i.e. y1 <= y2)
dl_yOrderOK:
        push de             ;save start address x,y
        ; determine octant (4,5,6 or 7 are remaining)
        ; compare x (distinguish 4,5 from 6,7)
        ld a,d
        cp h                ; TODO: fast vertical
        jr c, dl_oct67
        ; here: octant 4 or 5
        ; x1 > x2, y1 < y2
        ; check dx vs dy
        ; create abs(dx), abs(dy)
        ld a,d
        sub h
        ld b,a              ; b = dx
        ld a,l
        sub e
        ld c,a              ; c = a = dy
        sub b               ; dy-dx
        jr nc,dl_oct5       ; TODO: fast diagonal
        jr dl_oct4
        ;
dl_oct67:
        ; here: octant 6 or 7
        ; x1 < x2, y1 < y2
        ; check dx vs dy
        ; create abs(dx), abs(dy)
        ld a,h
        sub d
        ld b,a
        ld a,l
        sub e
        ld c,a              ; c = a = dy
        sub b               ; dy-dx
        jr nc,dl_oct6       ; TODO: fast diagonal
        jr dl_oct7
        ;
dl_oct4:
        ; Octant 4
        ld hl, DL_JUMP_TABLE
        jr dl_jtOK
dl_oct5:
        ; Octant 5
        ld hl, DL_JUMP_TABLE + 4
        jr dl_jtOK
dl_oct6:
        ; Octant 6
        ld hl, DL_JUMP_TABLE + 8
        jr dl_jtOK
dl_oct7:
        ; Octant 7
        ld hl, DL_JUMP_TABLE + 12
dl_jtOK:
        ; load jump addresses into IX and IY
        ; hl points to 2nd jump address
        ld (DL_TEMP_STACK),SP   
        ld sp,hl
        pop IX
        pop IY
        ld SP,(DL_TEMP_STACK)
        ;
        ; determine initial screen byte, bit and pattern
        ; after this, the absolute x,y coordinates are not 
        ; of importance anymore. The algorithm is relative
        ; to the start pattern, abs(dx), abs(dy) and the octant
        pop hl                  ; start address (x,y) in hl                
        call GetStartPattern    ; screen address in hl, bit pattern in a        
        ld d,a                  ; initial plot pattern
        push bc                 ; save dx,dy
        ld a,b                  ; set counter = max(dx,dy)+1
        cp c                   
        jr nc, dl_counterOK
        ld b,c                  ; b = max(dx, dy)
dl_counterOK:                                    
        ld c,d                  ; initial plot bit
        exx                     ; hl'=screen address, b'=counter, c'=bit, d'=plotPattern
        pop bc                  ; recover dx, dy
        ;
; - - - - - - - - - - - - - - - - -
; Bresenham Algorithm Starts here.
; bc = dx, dy
; plot-relevant values are in alternative registers        
        ; init        
        ld hl,0                 ; err = 0 (16bit!)
        exx
        ;
dl_bresenham:
        exx                     ; switch to main register set
        ld e,c                  ; dy
        ld d,0
        add hl,de               ; err+dy        
        ; if err < T: same line
        bit 7,h                 ; negative?
        jr nz, dl_belowThresh
        ; the threshold for a line jump is T=dx/2 (int division!)
        ld a,b
        srl a                   ; dx/2
        cp l                    ; err low byte (err cannot be >255. it's 16 bit because of SIGN)
        jr c, dl_geqThresh
        ;jr z, dl_geqThresh
        ;
        ; the following two jumps were modfified above to reflect the different 
        ; octant cases
dl_belowThresh:
        jp (IX)                 ; indirect jump, defined by table
dl_geqThresh:
        ld e,b                  ; dx
        and a
        sbc hl,de               ; err-dx (this goes negative)
        jp (IY)                 ; indirect jump, defined by table
        ;        
dl_continueLoop:
        ; after the different cases were processed, the program continues here
        ; currently, the alternative register set is active
        ; b is counter
        djnz dl_bresenham       ; are we there yet? no->loop
dl_endBresenham:        
        ld a,(hl)               ; plot final pattern
        or d
        ld (hl),a        
        ld a,(IRFLAG)
        and a
        ret nz
        ;
        pop IY
        pop IX
        pop hl
        pop de
        pop bc
        exx
        EI
        ret                     ; END BRESENHAM
        ;
; the following routines handle the different octant cases
; they are reached by the modified jump routines
        ; Octant 7
dl_oct4_belowT:
dl_oct4_geqT:
dl_oct5_belowT:
dl_oct5_geqT:
dl_oct6_belowT:
dl_oct6_geqT:
        ;
dl_oct7_belowT:
        exx        
        srl c                   ; move right
        jr c,dl_nextByte        ; -> proceed to new byte
        ld a,d                  ; stay in same byte: plot into pattern
        or c
        ld d,a
        jr dl_continueLoop
dl_nextByte:
        rr c                    ; set bit 7
        ld d,c
        or (hl)                 ; purge pattern into screen
        ld(hl),a
        inc hl                  ; next byte same row        
        jp dl_continueLoop
        ;
dl_oct7_geqT:
        exx
        ld a,d                  ; purge pattern into screen
        or (hl)
        ld (hl),a
        ;
        call NextLine
        ;
        srl c 
        ld d,c       
        jr nc,dl_continueLoop        
        rr c
        ld d,c
        inc hl
        jp dl_continueLoop

; ---------------------------------------------------------------------
; Compute screen address of byte below (hl)
; NextLine(hl: current address)->(hl: next address):(af,hl)
NextLine:
        inc h
        bit 3,h
        ret z       ; intra character position
        ;
        ld a,l
        add 32      ; character boundary
        ld l,a
        ret c       ; same region
        ;
        res 3,h     ; region transition
        ret

; ---------------------------------------------------------------------
; GetStartPattern(hl: x,y)->(hl: screen address, a: bit pattern):(af,de,hl)
LD_BIT_PATTERN_TABLE:  defb 128,64,32,16,8,4,2,1
GetStartPattern:    
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
    ld hl,LD_BIT_PATTERN_TABLE
    add hl,de
    ld a,(hl)
    pop hl          ; address in hl    
    ;    
    ret