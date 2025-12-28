; ======================================================
; MazeDweller: Maze-inhabitant functions
; ======================================================
;
DW_RC:  equ 0           ; position, 2 bytes
DW_DIR: equ 2           ; direction, 1 byte
DW_LEN: equ 3           ; length of structure

DW_NUMDWELLERS: equ     5
DW_DWELLERS:    defs    DW_NUMDWELLERS * DW_LEN

; ------------------------------------------------------
; InitDwellers()->():(?)
; Inits
InitDwellers:
    ld hl,DW_DWELLERS
    ld de,DW_DWELLERS+1
    ld bc,DW_NUMDWELLERS * DW_LEN - 1
    ld (hl),$FF
    LDIR
    ret

; ------------------------------------------------------
; CreateDweller(a:ID, b:type)->(IX:dweller structure)->(IX)
; type: 0: prisoner, 1: guardian
CreateDweller:
    push af    
    call DW_getStruct
DW_posLoop:
    call DW_getRandomPose
    call DW_isValidPose
    and a
    jr z,DW_posLoop
    ld (IX+0),d
    ld (IX+1),e
    ld (IX+2),1
    pop af
    ret

; ------------------------------------------------------
; DW_isValidPose(de:(r,c), c:ID)->(a:1=valid):(af)
; compare pose against exit and other dwellers
; to avoid collision (e.g. in startpose)
DW_isValidPose:
    push bc
    push de
    push hl
    ;
    ; check for exit ($0F, $0F)
    ld a,d
    and e
    cp $0f
    jr z,DWV_end_invalid       ; ->exit, invalid.    
    ;
    ; check collision
    ld hl,DW_DWELLERS
    ld b,0
    ;
DWV_checkCollisionLoop:    
    ; check ID. same? skip.
    ld a,c
    cp b
    jr z,DWV_next
    ; check for same position
    ld a,d
    cp (hl)
    jr nz,DWV_next
    inc hl
    ld a,e
    cp (hl)
    dec hl
    jr z,DWV_end_invalid    ; collision    
    ;
DWV_next:
    inc b
    ld a,b
    cp DW_NUMDWELLERS
    jr z,DWV_end_valid
    ld de,DW_LEN    
    add hl,de
    jr DWV_checkCollisionLoop
    ;
DWV_end_valid:
    ld a,1                  ; valid
    jr DWV_end
DWV_end_invalid:
    xor a
DWV_end:
    pop hl
    pop de
    pop bc
    ret

; ------------------------------------------------------
; DW_getStruct(a:ID)->(IX:struct-address):(IX)
DW_getStruct:
    push bc
    push de
    push hl
    ld hl,DW_DWELLERS
    and a
    jr z,DWS_adrOK
    ld de,DW_LEN
    ld b,a
DWS_loop:
    add hl,de
    djnz DWS_loop    
DWS_adrOK:
    push hl
    pop IX
    ;
    pop hl
    pop de
    pop bc
    ret

; ------------------------------------------------------
; DW_getRandomPose()->(de:(r,c),a:dir):(de,af)
DW_getRandomPose:
    call Random
    and $0F
    ld d,a
    call Random
    and $0F
    ld e,a
    ret

; ------------------------------------------------------
; DrawDweller(IX:struct, a:charID)->():()
DW_CHARS:   db  $00,$18,$3C,$7E,$7e,$3C,$18,$00
DrawDweller:
    push af
    push bc
    push de
    push hl
    ;
    ; get char address
    ld hl,DW_CHARS
    sla a
    sla a
    sla a
    ld e,a
    ld d,0
    add hl,de
    push hl
    ;
    ; get screen address    
    ld d,(IX+0)
    ld e,(IX+1)
    call MZ_getScreenAddress        ; in hl
    ;
    ; draw
    pop de
    ld b,8
DWD_charLoop:
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    inc h
    djnz DWD_charLoop
    ;
    pop hl
    pop de
    pop bc
    pop af
    ret
