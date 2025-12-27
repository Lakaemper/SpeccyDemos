; ---------------------------------------------------------------------------
; MAZE: 16x16 maze related functions
; ---------------------------------------------------------------------------
; Maze cell data: row wise cells
; low  nibble: walls. bits 0,1,2,3: n,s,w,e
; bit 7: 0->non-maze cell (temp flag for maze creation)
MAZE:   defs    16*16       ; Maze data, cells.    

; ---------------------------------------------------------------------------
; InitializeMaze()->():(af,bc,de,hl)
; Initializes maze space and creates a unique solution maze using the Hunt and Kill ALgo
InitMaze:
    ; create all non-permanent walls, initialize permanent walls to 0
    ld de, MAZE+1
    ld hl, MAZE
    ld a,$8f        ; all walls up, bit 7 set
    ld bc,$00ff
    ld (hl),a
    LDIR
    ;        
    jp CreateMaze   ; create the maze and return

; ---------------------------------------------------------------------------
; DrawMaze(de: offset (r,c), a: color (spectrum attribute))->():(af,bc,de,hl)
; Draws 16x16 maze at r,c CHARACTER offset position, each cell is one character
; Offset (i.e. top left corner) row must be in [0,8], col in [0,16]
DrawMaze:
MAZE_OFFSET:     dw  0
; - - - - - - - -
; init attributes    
    ld (MAZE_OFFSET),de
    ld c,a    
    rrc d
    rrc d
    rrc d               ; row*32
    ld a,d    
    and $e0    
    add e               ; + col
    ld e,a
    rr d                ; bit 3->carry
    ld d,0
    jr nc,DM_nc1
    inc d
DM_nc1:
    ld hl, $5800        ; spectrum attribute region
    add hl,de           ; base address in hl
    ld a,c
    ld b,$10
    ld c,$10            ; bc: 16x16
    ld de,$0010         ; offset 16 (32-16=16)
DM_attrLoop:
    ld (hl),a
    inc hl
    djnz DM_attrLoop
    ld b,$10
    add hl,de
    dec c
    jr nz,DM_attrLoop
; - - - - - 
; draw cells
    ld de,$0000         ; top left    
DM_cellLoop:    
    push de   
    call DrawMazeCell    
    pop de
    inc e
    ld a,e
    cp $10
    jr c,DM_cellLoop    
    ld e,$00
    inc d
    ld a,d
    cp $10
    jr c,DM_cellLoop
    ;
    ret

; ---------------------------------------------------------------------------
; DrawMazeCell(de: position (r,c))->():(af,bc,de,hl)
; Draws single 8x8 cell
; Assumes: OFFSET is initialized, attributes are set
; CELLCHARS: the 16 characters for different wall configurations
CELLCHARS:  defb $00,$00,$00,$00,$00,$00,$00,$00        ;  0 = ----
            defb $ff,$00,$00,$00,$00,$00,$00,$00        ;  1 = n---
            defb $00,$00,$00,$00,$00,$00,$00,$ff        ;  2 = -s--
            defb $ff,$00,$00,$00,$00,$00,$00,$ff        ;  3 = ns--
            defb $80,$80,$80,$80,$80,$80,$80,$80        ;  4 = --w-
            defb $ff,$80,$80,$80,$80,$80,$80,$80        ;  5 = n-w-
            defb $80,$80,$80,$80,$80,$80,$80,$ff        ;  6 = -sw-
            defb $ff,$80,$80,$80,$80,$80,$80,$ff        ;  7 = nsw-
            defb $01,$01,$01,$01,$01,$01,$01,$01        ;  8 = ---e
            defb $ff,$01,$01,$01,$01,$01,$01,$01        ;  9 = n--e
            defb $01,$01,$01,$01,$01,$01,$01,$ff        ; 10 = -s-e
            defb $ff,$01,$01,$01,$01,$01,$01,$ff        ; 11 = ns-e
            defb $81,$81,$81,$81,$81,$81,$81,$81        ; 12 = --we
            defb $ff,$81,$81,$81,$81,$81,$81,$81        ; 13 = n-we
            defb $81,$81,$81,$81,$81,$81,$81,$ff        ; 14 = -swe
            defb $ff,$81,$81,$81,$81,$81,$81,$ff        ; 15 = nswe
DrawMazeCell:   
    ; get screen address
    ld hl,(MAZE_OFFSET)
    ld a,d              ; compute row->y=l    
    add a,h
    sla a
    sla a
    sla a    
    ld h,a
    ld a,e              ; compute col->x=h    
    add a,l
    sla a
    sla a
    sla a
    ld l,h    
    ld h,a        
    push de
    call GetStartPattern    ; in LineDrawer.asm, screenAddress -> hl
    ;
    ; get maze content
    pop de
    push hl             ; stack: screen, de: (r,c)    
    call MZ_getCellAddress  ; in hl        
    ld a,(hl)           ; a->maze cell content
    and $0f             ; keep non permanent wall signature
    ;
    ; get char address    
    sla a
    sla a
    sla a
    ld hl,CELLCHARS
    ld d,0
    ld e,a
    add hl,de           ; hl->cell char
    pop de              ; de->screen address
    ;
    ; draw character            
    ld b,8
DMC_loop1:    
    ld a,(hl)
    ld (de),a
    inc hl    
    inc d
DMC_noCarry:
    djnz DMC_loop1
    ret

; ---------------------------------------------------------------------------
; MZ_getCellAddress(de: (r,c)->(hl):(hl)
; Get memory address of cell (r,c)
MZ_getCellAddress:    
    push af
    push de
    ld a,d
    sla a
    sla a
    sla a
    sla a
    add e    
    ld e,a
    ld d,0
    ld hl,MAZE
    add hl,de           ; address in hl
    pop de
    pop af
    ret

; =============================================================================
; Hunt and Kill Maze Algo
; =============================================================================
; CreateMaze()->():(?)
CreateMaze:
    ret

; ---------------------------------------------------------------------------
; HK_isDeadEnd(de: (r,c)) -> (a: dead end if non-zero) : (af)
; Helper for Hunt and Kill
; check if cell at (r,c) is dead end, i.e. no wall can be torn down to a 
; non-maze cell
HK_isDeadEnd:    
    call HK_getBoundaryState
    ld b,a    
    ;
    ld a,$ff           ; default: is maze
    bit 0,b
    call z,HK_northIsMaze
    and a
    jr z,HKD_isOK
    ;
    ld a,$ff           ; default: is maze
    bit 1,b
    call z,HK_southIsMaze
    and a
    jr z,HKD_isOK
    ;
    ld a,$ff           ; default: is maze
    bit 2,b
    call z,HK_westIsMaze
    and a
    jr z,HKD_isOK
    ;
    ld a,$ff           ; default: is maze
    bit 3,b
    call z,HK_eastIsMaze
    and a
    jr z,HKD_isOK
    ;
    ld a,$ff            ; dead end.
    ret
HKD_isOK:
    xor a
    ret

; ---------------------------------------------------------------------------
; HK_searchNextStart()->(de: (r,c), a:$ff=invalid location):(?)
; Search a new start location for random walk. Start location is a cell that
; is (a) non-maze, and (b) has a maze neighboring cell
; (very similar to dead end...)
HK_searchNextStart:
    ld de,$0000          ; start top left
    
HKS_loop:
    call MZ_getCellAddress
    ld a,(hl)
    bit 7,a              ; non maze?
    jr z,HKS_checkNext
    ;
    call HK_getBoundaryState
    ld b,a    
    ;
    xor a               ; default: is non-maze
    bit 0,b
    call z,HK_northIsMaze
    and a
    jr nz,HKS_foundStart
    ;
    xor a               ; default: is non-maze
    bit 1,b
    call z,HK_southIsMaze
    and a
    jr nz,HKS_foundStart
    ;
    xor a               ; default: is non-maze
    bit 2,b
    call z,HK_westIsMaze
    and a
    jr nz,HKS_foundStart
    ;
    xor a               ; default: is non-maze
    bit 3,b
    call z,HK_eastIsMaze
    and a
    jr nz,HKS_foundStart
    ;
HKS_checkNext:
    inc e
    ld a,e
    cp $10
    jr c,HKS_loop
    ld e,0
    inc d
    cp $10
    jr c,HKS_loop
    ;
    ; nothing found
    ld a,$ff
    ret

HKS_foundStart:
    xor a
    ret

; ---------------------------------------------------------------------------
; HK_getBoundaryState(de:(r,c))->(a: is boundary (bits 0,1,2,3->n,s,w,e)):(af,b)
HK_getBoundaryState:
    ld b,0
    ld a,d          ; row
    and a           ; zero?
    jr nz,HKB_nz1
    set 0,b
HKB_nz1:    
    cp $0F          ; 15?
    jr nz,HKB_nz2
    set 1,b
HKB_nz2:
    ld a,e
    and a           ; zero?
    jr nz,HKB_nz3
    set 2,b
HKB_nz3:    
    cp $0F          ; 15?
    jr nz,HKB_nz4
    set 3,b
HKB_nz4:
    ld a,b
    ret

; ---------------------------------------------------------------------------
; HK_<direction>IsMaze(de: (r,c))->(a: $ff if is maze):(a)
; assertion: non boundary cell in test direction
HK_northIsMaze:
    push de
    dec d
    jr HK_isMaze

HK_southIsMaze:
    push de
    inc d
    jr HK_isMaze

HK_westIsMaze:
    push de
    dec e
    jr HK_isMaze

HK_eastIsMaze:
    push de
    inc e

HK_isMaze:
    xor a
    push hl
    call MZ_getCellAddress
    bit 7,(hl)
    pop hl
    pop de
    ret nz
    dec a
    ret
