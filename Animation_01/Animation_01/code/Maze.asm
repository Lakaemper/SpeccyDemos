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
    ret    

; ---------------------------------------------------------------------------
; DrawMaze()->():()
; Draws 16x16 maze at r,c CHARACTER offset position, each cell is one character
MAZE_OFFSET:        dw  $0810
MAZE_ATTR:          db  $03
DrawMaze:
; - - - - - - - -
    push af
    push bc
    push de
    push hl   
    ;
; init attributes 
    ld de,(MAZE_OFFSET)       
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
    ld a,(MAZE_ATTR)
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
    pop hl
    pop de
    pop bc
    pop af
    ret

; ---------------------------------------------------------------------------
; MZ_getScreenAddress(de:(r,c))->(hl:screen address):(af,hl)
MZ_getScreenAddress:
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
    pop de
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
    call MZ_getScreenAddress
    ;
    ; get maze content
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
; assumption: maze is initialized by InitMaze

MAZE_MAXPATHLENGTH  equ 15
CreateMaze:
    ; find random starting point
    call random
    and $0f
    ld d,a
    call random
    and $0f
    ld e,a
    ;
    call MZ_getCellAddress
    res 7,(hl)      ; maze cell    
    ;
    ld b,MAZE_MAXPATHLENGTH
; - - - - - - - - - - - - 
; Hunt and Kill main loop
; assumes valid start point (r,c) in de
; and address in hl
HK_mainLoop:    
    ld a,1          ; mode: search non maze
    call HK_getNBSignature
    and $0f         ; dead end?
    jr z,HK_startNewPath ; -> yes
    call HK_getRandomDirection     ; select from valid directions    
    call HK_extendPath             ; remove walls and move    
    djnz HK_mainLoop               ; if path shoty enough: continue
                                   ; otherwise, this falls through
; end mainloop
;
    ; Dead end: search new starting point
HK_startNewPath:
    call HK_getNextStart
    and a                   ; valid start point?
    jr z,HK_end             ; -> no, done
    call MZ_getCellAddress
    res 7,(hl)              ; maze cell
    push hl
    push de                 ; store position to undo "move" in extendPath
    call HK_extendPath      ; tear down walls to existing path
    pop de                  ; but stay in new position
    pop hl    
    ld b,MAZE_MAXPATHLENGTH
    jr HK_mainLoop
    ;
HK_end:
    ret

; ---------------------------------------------------------------------------
; HK_extendPath(de:(r,c),hl:address,a:direction)->(de:(r1,c1),hl:address1):(hl,de,af)
; Removes walls and moves one step forward
HK_extendPath:
    push bc
    ; remove walls towards direction    
    ld c,a          
    cpl
    and (hl)
    ld (hl),a
    ld a,c
    ; go to next cell
    call HK_move
    res 7,(hl)      ; make maze cell
    ;
    ; remove walls towards source direction
    ld b,$03        ; mask n,s
    cp $04
    jr c,HKE_maskOK
    ld b,$0c
HKE_maskOK:
    xor b           ; flip n<->s , w<->e
    cpl
    and (hl)
    ld (hl),a
    pop bc
    ret

; ---------------------------------------------------------------------------
; HK_move(de:(r,c),hl=address(r,c),a=direction)->(de:(r1,c1),hl:address(r1,c1)):(de,hl)
; moves one cell in direction A
; assumes valid direction
HK_move:
    ; north
    bit 0,a
    jr z, HKM_south
    dec d
    push de
    ld de,$FFF0         ; -16
    jr HKM_adjustHL
HKM_south:
    bit 1,a
    jr z,HKM_west
    inc d
    push de
    ld de,$0010         ; +16
    jr HKM_adjustHL
HKM_west:
    bit 2,a
    jr z,HKM_east
    dec e
    push de
    ld de,$FFFF         ; -1
    jr HKM_adjustHL
HKM_east:    
    inc e
    push de
    ld de,$0001         ; +1
HKM_adjustHL:
    add hl,de
    pop de
    ret
    
; ---------------------------------------------------------------------------
; HK_getNextStart()->(de:(r,c) next start, a:direction of maze-cell, 0: invalid):(de,af)
; Gets next starting point in main loop. A valid point is 
; (a) non maze, (b) has at least one maze neighbor
; if returned invalid, there are no non-maze points left.
HK_getNextStart:
    push hl
    ld de,$0000         ; top left
    call MZ_getCellAddress
    ;
HKN_loop:
    bit 7,(hl)          ; non maze?
    jr z,HKN_checkNext
    xor a               ; look for maze neighbors
    call HK_getNBSignature
    and $0f             ; neighbor bits?
    jr  nz, HKN_found   ; yes, done.
HKN_checkNext:
    inc hl
    inc e
    bit 4,e
    jr z,HKN_loop
    ld e,0
    inc d
    bit 4,d
    jr z,HKN_loop
    ;
    xor a               ; invalid
    pop hl
    ret
    ;
HKN_found:
    call HK_getRandomDirection     ; select one of the directions    
    pop hl    
    ret

; ---------------------------------------------------------------------------
; HK_getNBSignature(de: (r,c), a:mode) -> (a: valid direction bits) : (af)
; Helper for Hunt and Kill
; Returns all directions of <mode> maze cells.
; mode: 0: search for maze, 1: search for non-maze
; Returns signed bits, 0,1,2,3->n,s,w,e for neighbors that match mode
; If all bits are zero => dead end
HK_getNBSignature:    
    push bc
    ld c,a              ; c=mode (0 or 1)
    call HK_getBoundaryState    
    cpl
    and $0f
    ld b,a              ; signature    
    ;
    ; north
    bit 0,b
    jr z,HK_south       ; invalid, no testing necessary
    call HK_northIsMaze
    xor c               ; mode
    jr nz,HK_south      ; keep bit valid
    res 0,b             ; invalidate
HK_south:
    bit 1,b
    jr z,HK_west        ; invalid, no testing necessary
    call HK_southIsMaze
    xor c               ; mode
    jr nz,HK_west       ; keep bit valid
    res 1,b             ; invalidate
HK_west:
    bit 2,b
    jr z,HK_east        ; invalid, no testing necessary
    call HK_westIsMaze
    xor c               ; mode
    jr nz,HK_east       ; keep bit valid
    res 2,b             ; invalidate
HK_east:
    bit 3,b
    jr z,HK_done        ; invalid, no testing necessary
    call HK_eastIsMaze
    xor c               ; mode
    jr nz,HK_done       ; keep bit valid
    res 3,b             ; invalidate
HK_done:
    ld a,b
    pop bc
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
    xor a   ; default: a=0
    push hl
    call MZ_getCellAddress
    bit 7,(hl)
    pop hl
    pop de
    ret nz
    inc a   ; a=1
    ret

; ---------------------------------------------------------------------------
; HK_getRandomDirection(a:valid directions)->(a: selected direction):(af)
; assumes at least one valid direction
HKN_BITCOUNT: db 0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4
HK_getRandomDirection:
    push bc
    push de
    push hl
    ; count directions
    and 0x0F        ; lower nibble
    ld  hl, HKN_BITCOUNT
    ld  e, a
    ld  d, 0
    add hl, de
    ld  h, (hl)     ; h = number of bits
    ld  l,a         ; bits
    ;
HKR_randLoop:
    call Random
    and $07
    cp h           ; a must be in [0..h-1]
    jr nc,HKR_randLoop
    ;
    ; select n'th set bit in L
    inc a
    ld b,a
    ld a,l
    ld c,$01        ; mask
HKR_maskLoop:
    and c           ; test bit
    jr z,HKR_nextBit
    djnz HKR_nextBit
    ;
    ; bit was found
    ld a,c
    pop hl
    pop de
    pop bc
    ret
    ;
HKR_nextBit:
    ld a,l          ; restore
    sla c
    jr HKR_maskLoop
