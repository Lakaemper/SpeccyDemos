; setup parameters
CP_NUM_CENTIPEDES       EQU     6                                                    ; number of centipedes
CP_NUM_TAILSEGMENTS     EQU     5                                                       ; number of tail segments to be displayed
CP_TAILSEGMENT_INTERVAL EQU     5                                                       ; interval between displayed tail segments
CP_TAIL_LENGTH          EQU     CP_NUM_TAILSEGMENTS * CP_TAILSEGMENT_INTERVAL * 2       ; 2: x,y uint8, not 8.8!

; movement model parameters
CP_ACC_UPDATE           EQU     20                                                      ; update interval for accelerator
CP_SPEED_MAX            EQU     16                                                       ; max speed

; Struct centipede
CP_POSHEAD      EQU     0
CP_SPEED        EQU     CP_POSHEAD + 4
CP_ACC          EQU     CP_SPEED + 4
CP_TAIL         EQU     CP_ACC + 4                                                      
CP_ACC_COUNT    EQU     CP_TAIL + CP_TAIL_LENGTH
CP_STATUS       EQU     CP_ACC_COUNT + 1                                            ; status bits: 0: initial round->0                 
CP_END          EQU     CP_STATUS + 1                                               ; END = length of structure

; memory block for centipede states
CENTIPEDES:     defs CP_END * CP_NUM_CENTIPEDES
CP_TEMPVECTOR:  defs 4

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
    ld de,CP_ACC_COUNT
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
; CP_updateTail(a: idx)->(hl: structStart):(bc,de,hl)
CP_updateTail:
    call CP_getStructStart
    push hl
    ld de, CP_TAIL + CP_TAIL_LENGTH  - 1   ; last tail byte
    add hl,de
    ld e,l
    ld d,h
    dec hl                                  ; tail segment is 2 byte: x,y uint8
    dec hl    
    ld bc,CP_TAIL_LENGTH - 2
    LDDR
    ; head -> tail[0]
    pop hl                                  ; struct start = POSHEAD
    inc hl                                  
    inc hl
    inc hl                                  ; hi byte Y
    LDD        
    dec hl                                  ; hi byte X
    LDD                                     ; structStart in hl    
    ret

; --------------------------------------------------------------------------------
; CP_move(a: idx)->():(de, hl)
; main movement routine
CP_move:
    DI
    push af
    push bc
    push IX
    ;
    call CP_updateTail          ; returns structStart in hl!   
    push hl
    pop IX
    ; test: update accelerator required?
    dec (IX+CP_ACC_COUNT)
    jr nz, cpmv_updateSpeed 
    call ACC_update                         ; updates directly in struct   
    ld (IX+CP_ACC_COUNT),CP_ACC_UPDATE      ; reset counter
    ;
cpmv_updateSpeed:
    ; speed update: speed += acc    
    push hl                     ; struct start -> (SP)    
    push hl
    ld de,CP_ACC
    add hl,de                   ; hl <- acc    
    ex (SP),hl                  ; (SP): acc, hl: struct start
    ld de,CP_SPEED
    add hl,de                   ; hl <- speed
    pop de                      ; de <- acc
    call Sum2D                  ; speed += acc
    ;
    ; position update: pos += speed/8
    ; here: stack-> start, hl -> new speed
    ld de,V2_TEMPVECTOR
    call Copy2D                 ; temp = speed (which is now speed + acc)
    ex (SP),hl                  ; struct start = POS in hl, (SP) = speed
    ex de,hl                    ; hl: speed (temp), de: pos
    call Div8_2D                ; speed / 8
    ex de,hl
    push de                     ; memorize previous position in CP_TEMPVECTOR (for out of bounds check below)
    ld de,CP_TEMPVECTOR
    call Copy2D
    pop de
    call Sum2D                  ; pos = pos + speed/4
    ;
    ; check if speed > limit
    ex (SP),hl                  ; hl = speed, (SP) = pos
    ld b,CP_SPEED_MAX          ; thresh
    ld c,0
    call CompareToThresh2D
    jr c,cpmv_speedOK
    ;
    ; trim speed    
    call Trim2D       
    ;
    ; check if position is out of bounds
    ; X is complicated, it's always valid (0..255),
    ; but it shouldn't wrap around
    ; check highest bit of hiByte in prev and current position
    ; If different: there was a wrap around.
cpmv_speedOK:
    ex (SP),hl                  ; (SP) = speed, hl = pos
    inc hl
    ld a,(CP_TEMPVECTOR+1)
    xor (hl)
    jp P, cpmv_checkY               ; both same bit 7: OK
    ld a,(hl)                       ; chack radius of 10 around 128. If in there: ok
    cp 118                         
    jr c, cpmv_checkX
    cp 138
    jr c, cpmv_checkY
    ;
    ; X out of bounds:
    ; reset x to either 0 or 255
    ; set x-speed to 0
    ; force acc update    
cpmv_checkX:
    ;ld (IX+CP_ACC_COUNT),1
    xor a                       ; get a zero
    bit 7,(hl)                  ; new position > 128?
    jr nz,cpmv_setX0            ; yes, set to left boundary
    dec a                       ; a = 255 = right boundary
cpmv_setX0:
    ld (hl),a    
    ; set xLow
    xor a
    dec hl
    ld (hl),a                   ; x low byte->0
    ;
    ex (SP),hl                  ; hl = speed, (SP) = pos    
    call Negate88_2D            ; speedX = - speedX
    ex (SP),hl                  ; hl = pos, (SP) = speed
    inc hl                      ; hl = pos+1
    ;
    ; Y out of bounds: 
    ; any number between 192 and 255 is out of bounds
    ; at this point: hl = pos+1, (SP) = speed
cpmv_checkY:
    inc hl
    inc hl                      ; hl = high byte Y             
    ld b,192                    ; screen height
    ld a,(HL)
    cp  b
    jr c,cpmv_okY               ; boundary y ok.
    ; check if posY inside [192,192+MAX_SPEED] corridor
    ; (it's fine to check MAX_SPEED and not MAX_SPEED/8)
    ;ld (IX+CP_ACC_COUNT),1            ; force acc update
    ld a,CP_SPEED_MAX
    add b    
    dec b                       ; 191
    cp (hl)
    jr nc,cpmv_setY191
    ld b,0
cpmv_setY191:
    ld (hl),b                   ; yHigh = 0 or 192
    xor a
    dec hl
    ld (hl),a                   ; yLo = 0
    ;
    pop hl                      ; speed -> hl
    inc hl
    inc hl
    call Negate88_2D            ; speedY = -speedY
    push hl
    ;
cpmv_okY:
    pop hl    
    ;
    ; update background
    ld e,(IX+1)
    ld d,(IX+3)
    srl d
    srl d
    srl d
    srl e
    srl e
    srl e
    call UpdateBackground
    jr nc,cpmv_end    
    ;
cpmv_end:
    pop IX
    pop bc
    pop af
    EI
    ret

; --------------------------------------------------------------------------------
; CP_moveAll()->():(af,b,de,hl)
CP_moveAll:    
    ld b,CP_NUM_CENTIPEDES
    xor a
cpma_lp1:        
    call CP_move
    inc a
    djnz cpma_lp1    
    ret

; --------------------------------------------------------------------------------
; CP_plot(a: idx)->():(de,hl)
CP_plot:    
    push bc
    push IX
    ;
    call CP_getStructStart
    push hl
    pop IX
    push hl
    
    ; plot Tail pos
    ld de, CP_TAIL      ; tail is 1 byte per coordinate!
    add hl,de           ; first tail segment erases head
    ld d,(hl)
    inc hl
    ld e,(hl)
    bit 0,(IX+CP_STATUS)
    jr z,cppl_plotHead
    ;    
cppl_unplotHead:
    ex de,hl            ; hl = xy, de = tail[0]_y
    call Plot           ; unplot head
    ex de,hl            ; hl = tail[0]_y  
    ;
    ; plot head
cppl_plotHead:
    ex (SP),hl            ; hl = struct start (pos), (SP) = tail[0]_y 
    inc hl
    ld d,(hl)
    inc hl
    inc hl
    ld e,(hl)
    ex de,hl
    call Plot
    ;
    ; plot tail segments
    ld b,CP_NUM_TAILSEGMENTS
    dec b               ; !!!
    pop hl              ; hl = tail[0]_y
    ld de,CP_TAILSEGMENT_INTERVAL
    sla e               ; *2    
    ;
cppl_loop1:
    add hl,de
    push de
    push hl
    ld e,(hl)
    dec hl
    ld d,(hl)
    bit 0,(IX+CP_STATUS)
    jr z,cppl_plotSegment
    ex de,hl
    call plot           ; unplot (seg+1)
    ex de,hl
cppl_plotSegment:    
    dec hl
    ld e,(hl)
    dec hl
    ld d,(hl)
    ex de,hl
    call plot           ; plot seg
    pop hl
    pop de
    djnz cppl_loop1    
    ;
    set 0,(IX+CP_STATUS)
    pop IX
    pop bc    
    ret

; --------------------------------------------------------------------------------
; CP_plotAll()->():(af,b,de,hl)
CP_plotAll:    
    ld b,CP_NUM_CENTIPEDES
    xor a
cppa_lp1:        
    call CP_plot
    inc a
    djnz cppa_lp1    
    ret