PM_MEM_START:           equ $F000
; Mem: order:
;   Address Table
;   Polygons
;       len
;       trans x,y
;       rot dd
;       x,y,x,y,.. (signed byte)    orig data
;       x,y,x,y,.. (signed byte)    rotated data
;       x,y,x,y,.. (unsigned byte)  current absolute data

PM_MAX_POLYGONS:        defb 0
PM_NEXT_POLY_ID:        defb 0
PM_NEXT_POLY_ADDR:      defw 0
PM_ADDRESS_TABLE:       defw 0

; -------------------------------------------------------------------
PM_init:
    ld (PM_MAX_POLYGONS),a
    ld hl,PM_MEM_START
    ld PM_ADDRESS_TABLE, hl         ; address table sits at start of mem area
    ld e,a
    ld d,0
    add hl,de
    add hl,de                       ; first (= next) poly sits directly behind address table
    ld (PM_NEXT_POLY_ADDR),hl
    ret

; -------------------------------------------------------------------
; polygon: length,x,y,x,y,x,y
PM_create:
    ; check if there's vacancy
    ld a,PM_NEXT_POLY_ID
    cp (PM_MAX_POLYGONS)
    ret nc
    ;
    ; add to table
    ld e,a
    ld d,0
    push hl
    ld hl,PM_ADDRESS_TABLE
    add hl,de
    add hl,de                       
    ld de,(PM_NEXT_POLY_ADDR)
    ex de,hl
    LDI                             ; copy address into table
    pop hl
    ; here: de contains address, hl points to polygon init data





