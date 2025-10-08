
CP_NUM_CENTIPEDES       EQU     4                                                       ; number of centipedes
CP_NUM_TAILSEGMENTS     EQU     4                                                       ; number of tail segments to be displayed
CP_TAILSEGMENT_INTERVAL EQU     5                                                       ; interval between displayed tail segments
CP_TAIL_LENGTH          EQU     CP_NUM_TAILSEGMENTS * CP_TAILSEGMENT_INTERVAL * 4
CP_ACC_UPDATE           EQU     10                                                      ; update interval for accelerator

; Struct centipede
CP_POSHEAD      EQU     0
CP_SPEED        EQU     4
CP_ACC          EQU     8
CP_TAIL         EQU     12      ; length = 4 * NUM * INTERVAL = 4 * 20 = 80
CP_ACC_COUNT    EQU     92
CP_END          EQU     93      ; END = length of structure

CENTIPEDES:     defs CP_END * CP_NUM_CENTIPEDES


; --------------------------------------------------------------------------------
; CP_init(a: centipede index)->():(af,bc,de,hl)
CP_init:
    call CP_getStructStart      ; CP_POS_HEAD[idx] -> hl
    ; memset 0
    ld bc,CP_END-1
    ld d,h
    ld e,l
    inc de
    ld (hl),0
    push hl
    LDIR
    pop hl
    ;
    ; POS_HEAD    
    push hl
    inc hl
    ld (HL),SCR_CENTER_X        
    inc hl    
    inc hl
    ld (HL),SCR_CENTER_Y             
    pop hl
    ; CP_ACC
    ld de,CP_ACC
    add hl,de
    ld (hl),1
    ret

; --------------------------------------------------------------------------------
; CP_initAll()->():(af,bc,de,hl)
; Initialize all centipedes
CP_initAll:
    ld b,CP_NUM_CENTIPEDES
    xor a
cpia_lp1:    
    push af
    push bc
    call CP_init
    pop bc
    pop af
    inc a
    djnz cpia_lp1
    ret

; --------------------------------------------------------------------------------
; CP_getStructStart(a: idx)->(hl: start of CP structure[idx]):(bc,de,hl)
; get start of structure in HL
CP_getStructStart:    
    ld hl,0
    ld de,CP_END
    and a
    jr z,cpinit_offsetOK    
    ld b,a    
cpinit_lp1:             
    add hl,de
    djnz cpinit_lp1
cpinit_offsetOK:
    ld de,CENTIPEDES
    add hl,de               ; CP_POSHEAD[idx] -> hl
    ret
    
; --------------------------------------------------------------------------------
; CP_info(a: idx)->():()
CP_info:
    push af
    push bc
    push de
    push hl        
    ;
    push af
    call CP_getStructStart    
    ld de,$04           ; vector size
    pop af
    ;
    add '0'             ; ID
    rst 16  
    ld a,':'
    rst 16
    call PrintNewline  
    ;
    ld a,'P'            ; POS HEAD
    rst 16
    call Print2D
    call PrintNewline
    ;
    ld a,'S'            ; Speed
    rst 16
    add hl,de           ; next vector
    call Print2D
    call PrintNewline    
    ;
    ld a,'A'            ; Acceleration
    rst 16
    add hl,de           ; next vector
    call Print2D
    call PrintNewline
    pop hl
    pop de
    pop bc
    pop af
    ret

; --------------------------------------------------------------------------------
; CP_infoAll()->():()
CP_infoAll:
    push af
    push bc
    ld b,CP_NUM_CENTIPEDES
    xor a
cpina_lp1:        
    call CP_info
    inc a
    djnz cpina_lp1
    pop bc
    pop af
    ret

; --------------------------------------------------------------------------------
; CP_updateTail(a: idx)->(hl: structStart):(de,hl)
CP_updateTail:
    call CP_getStructStart
    push hl
    ld de, CP_TAIL + CP_TAIL_LENGTH  -1   ; last tail byte
    add hl,de
    ld e,l
    ld d,h
    dec hl
    dec hl
    dec hl
    dec hl
    ld bc,CP_TAIL_LENGTH - 4
    LDDR
    ; head -> tail[0]
    pop hl
    inc hl
    inc hl
    inc hl
    ld bc,4
    LDDR
    inc hl      ; hl: structStart    
    ret

; --------------------------------------------------------------------------------
; CP_move(a: idx)->():(de, hl)
; main movement routine
CP_move:
    DI
    push af
    push bc
    push IX
    call CP_updateTail          ; returns structStart in hl
    push hl
    pop IX
    ; test: update accelerator required?
    dec (IX+CP_ACC_COUNT)
    jr nz, cpmv_updateSpeed 
    call ACC_update                         ; updates directly in struct !!! TODO    
    ld (IX+CP_ACC_COUNT),CP_ACC_UPDATE      ; reset counter
    ;
cpmv_updateSpeed:
    ; speed update: speed += acc/4
    ; create acc/4 in temp
    push hl                     ; struct start -> (SP)
    ld de,CP_ACC
    add hl,de                   ; hl <- acc
    ld de,V2_temp1
    call Copy2D                 ; copy acc -> temp
    ex de,hl                    ; hl: temp
    call Div4_2D                ; temp = acc/4
    ex (SP),hl                  ; 
    ld de,CP_SPEED
    add hl,de                   ; hl <- speed
    pop de                      ; de <- acc/4
    call Sum2D                  ; speed += acc/4
    ;
    ; position update: pos += speed/4


    // div4 must be signed
    // sum2D must be signed
    






    pop IX
    pop bc
    pop af
    EI
    ret
