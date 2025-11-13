; ------------------------------------------------------
; Implementation of Bresenham's Line Drawing Algorithm
; ------------------------------------------------------
; DrawLine(de->(x1,y1), hl->(x2,y2), a=0: make interrupt-safe)->():(?)
;
; Flag for differnt modes
; bit 0: make routine interrupt-safe
; bit 1: save final screen address and bit pattern
; bit 2: skip screen address and bit pattern computation
; bit 3: use xor instead of or for plotting
; bit 4: omit last point (important for polygons in xor mode)
INPUT_FLAG:     defb 0              
; (precomputed) plotting parameters
; these will be stored and used if flag bit 1,2 are set accordingly
SCREEN_ADDRESS: defw 0
BIT_PATTERN:    defb 0 
; jump addresses for conditional jumps to handle different octants
DL_JUMP_TABLE:  defw dl_oct4_belowT, dl_oct4_geqT, dl_oct5_belowT, dl_oct5_geqT
                defw dl_oct6_belowT, dl_oct6_geqT, dl_oct7_belowT, dl_oct7_geqT
DL_TEMP_STACK:  defw 0
DrawLine:
        ld (INPUT_FLAG),a
        bit 0,a                 ; skip interrupt-safety?
        jr nz,dl_testModificationFlag    ; -> yes
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
dl_testModificationFlag:
        ; modify plot code according to bit 3 in INPUT_FLAG        
        call ModifyPlotCode
        ;        
        ; Start of draw line routine
dl_start:                     
        ; Truncate y1, y2 to max 191
        ld b,191
        ld a,e
        cp b
        jr c, dl_x1OK
        ld e,b
dl_x1OK:
        ld a,l
        cp b
        jr c,dl_x2OK
        ld l,b
dl_x2OK:
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
        jp dl_endBresenham
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
        ld a,b
        ld b,c
        ld c,a              ; swap dx,dy
        jr dl_jtOK
dl_oct6:
        ; Octant 6
        ld hl, DL_JUMP_TABLE + 8
        ld a,b
        ld b,c
        ld c,a              ; swap dx,dy
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
        ld a,(INPUT_FLAG)
        bit 2,a                 ; skip computation?
        jr nz,dl_skipScreenComp ; -> yes
        call GetStartPattern  ; no, compute: screen address in hl, bit pattern in a        
        jr dl_plotPatternOK
dl_skipScreenComp:
        ld hl,(SCREEN_ADDRESS)  ; retrieve: screen address in hl, bit pattern in a        
        ld a,(BIT_PATTERN)
dl_plotPatternOK:
        ld d,a                  ; initial plot bit        
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
        ld a,h                  ; positive. err > 255?
        and a
        jr nz, dl_geqThresh     ; yes
        ; the threshold for a line jump is T=dx/2 (int division!)        
        ld a,b
        srl a                   ; dx/2
        cp l                    ; err low byte.
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
        ;
dl_endBresenham:        
        ld a,(INPUT_FLAG)
        ld b,a
        bit 4,b
        jr nz,dl_skipLast        
        ld a,d                  ; plot final pattern
dl_MOD00: nop               ; WILL BE MODIFIED (xor/or)
        ld (hl),a                
dl_skipLast:
        bit 1,b                 ; store final address and pattern?
        jr z, dl_noPatternStore
        ld (SCREEN_ADDRESS),hl        
        ld a,c
        ld (BIT_PATTERN),a        
dl_noPatternStore:
        bit 0,b                 ; interrupt-safe mode?
        ret nz                  ; -> no
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
;
; Octant 4 - - - - - - -
dl_oct4_belowT:
        exx        
        rl c                    ; move left
        ld a,d                  
        jr c,dl_o4_prevByte     ; -> proceed to new byte        
        or c                    ; stay in same byte: plot c into pattern d
        ld d,a
        jr dl_continueLoop
dl_o4_prevByte:
        rl c                    ; set bit 0
dl_MOD01: or (hl)               ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        ld d,c                  ; init new pattern
        dec hl                  ; next byte same row        
        jp dl_continueLoop
        ;
dl_oct4_geqT:
        exx
        ld a,d                  
dl_MOD02: nop               ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        ;
        call NextLine
        ;
        rl c 
        ld d,c       
        jr nc,dl_continueLoop        
        rl c
        ld d,c
        dec hl
        jp dl_continueLoop

; Octant 5 - - - - - - -
dl_oct5_belowT:
        exx        
        ld a,c               ; purge and go to next line
dl_MOD03: or (hl)            ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        call NextLine
        jr dl_continueLoop
        ;        
dl_oct5_geqT:
        exx
        ld a,c               ; purge
dl_MOD04: nop            ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        call NextLine           ; next line
        ;
        rl c                    ; move left
        ld d,c                  ; d is only for the last plot. A bit of a waste :-)
        jr nc,dl_continueLoop        
        rl c                            
        dec hl
        ld d,c
        jp dl_continueLoop      ; one byte to the left
;
; Octant 6 - - - - - - -
dl_oct6_belowT:
        exx        
        ld a,c               ; purge and go to next line
dl_MOD05: nop               ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        call NextLine
        jr dl_continueLoop
        ;        
dl_oct6_geqT:
        exx
        ld a,c                ; purge
dl_MOD06: nop               ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        call NextLine           ; next line
        ;
        srl c                   ; move right        
        ld d,c                  ; d is only for the last plot. A bit of a waste :-)
        jr nc,dl_continueLoop        
        rr c                            
        inc hl
        ld d,c
        jp dl_continueLoop      ; one byte to the right
;
; Octant 7 - - - - - - -
dl_oct7_belowT:
        exx        
        srl c                   ; move right
        ld a,d                  
        jr c,dl_o7_nextByte     ; -> proceed to new byte        
        or c                    ; stay in same byte: plot c into pattern d
        ld d,a
        jp dl_continueLoop
dl_o7_nextByte:
        rr c                    ; set bit 7        
dl_MOD07: nop               ; purge pattern into screen WILL BE MODIFIED
        ld(hl),a
        ld d,c                  ; init new pattern
        inc hl                  ; next byte same row        
        jp dl_continueLoop
        ;
dl_oct7_geqT:
        exx
        ld a,d                  ; purge pattern into screen
dl_MOD08: nop               ; purge pattern into screen WILL BE MODIFIED
        ld (hl),a
        ;
        call NextLine
        ;
        srl c 
        ld d,c       
        jp nc,dl_continueLoop        
        rr c
        ld d,c
        inc hl
        jp dl_continueLoop

; ---------------------------------------------------------------------
; ModifyPlotCode(A: modificationflag)->():(af,b)
; Modifies the DrawLine code: for screen-plotting, xor/or is used depending
; on bit 1 of the MODE flag
MODTABLE: defw dl_MOD00,dl_MOD01,dl_MOD02,dl_MOD03,dl_MOD04,dl_MOD05,dl_MOD06,dl_MOD07,dl_MOD08
ModifyPlotCode:        
        push hl        
        and $08                 ; test modification bit
        ld a,$B6                ; opcode "or (HL)" (for bit = 0)
        jr z, dl_opcodeOK
        ld a, $AE               ; opcode "xor (HL)" (for bit = 1)
dl_opcodeOK:
        ld b,9                  ; number of modifications
        ld (DL_TEMP_STACK),SP
        ld SP,MODTABLE
dl_modificationLoop:
        pop hl                  ; modification address
        ld (hl),a               ; opcode -> address        
        djnz dl_modificationLoop
        ;
        ld SP,(DL_TEMP_STACK)
        pop hl
        ret

; ---------------------------------------------------------------------
; Compute screen address of byte below (hl)
; NextLine(hl: current address)->(hl: next address):(af,hl)
NextLine:
        inc h
        ld a,h
        and $07        
        ret nz      ; intra character position
        ;
        ld a,l
        cp $e0      ; intra region?
        jr c,dl_intraRegion
        ; region transition. the high byte is already ok, erase the 
        ; low byte row-bits
        and $1f     
        ld l,a
        ret
        ;
dl_intraRegion:
        add $20         ; next char-row
        ld l,a
        ld a,h
        sub $08         ; reverse overflow from inc h above
        ld h,a
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