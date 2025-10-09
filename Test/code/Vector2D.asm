; ====================================================
; Package for 8.8 2D vector routines
; ====================================================

V2_TEMPVECTOR:  defs 4
V2_STASH:	    defs 4

; ----------------------------------------------------
; Store2D(bc,de,hl)->():()
; Store 2D, 8.8 vector bc,de -> (hl), low endian
Store2D:
	push hl
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d	
	pop hl
	ret

; ----------------------------------------------------
; Retrieve2D(hl)->(bc,de):()
; Store 2D, 8.8 vector bc,de -> (hl), low endian
Retrieve2D:
	push hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)	
	pop hl
	ret

; ----------------------------------------------------
; Sum2D(hl: adr x1,y1, de: adr x2, y2)->(hl: adr resX,resY):()
; 8.8 addition of 2D vectors
Sum2D:
	push af	
	push de
	push hl	
	;
	ld a,(de)		; add x low
	add a,(hl)	
	ld(hl),a		; store x low
	inc hl
	inc de
	ld a,(de)		; add x high
	adc a,(hl)				
	ld (hl),a		; store x low
	inc hl
	inc de
	;
	ld a,(de)		; add y low
	add a,(hl)
	ld(hl),a		; store y low
	inc hl
	inc de
	ld a,(de)		; add y high
	adc a,(hl)			
	ld (hl),a		; store y high
	;
	pop hl
	pop de	
	pop af
	ret

; ------------------------------------------------------------
; Div2_2D(hl: adr)->():()
; divide vector by 2 in place, SIGNED 8.8
; (~ 122T)
Div2_2D:
	push hl
	inc hl
	sra (hl)
	dec hl		
	rr (hl)			; x / 2
	inc hl
	inc hl
	inc hl
	sra (hl)
	dec hl
	rr (hl)			; y / 2
	pop hl
	ret

;---------------------------------------------------------
;Div4_2D(hl: vector)->():()
; divides vector by 4 in place, for SIGNED 8.8
Div4_2D:
    push hl
	;
    ; ---- X component ----
    ; shift right once
    inc hl
    SRA (hl)        ; high byte (signed shift)
    dec hl
    RR  (hl)        ; low byte through carry
    ; shift right again
    inc hl
    SRA (hl)
    dec hl
    RR  (hl)
	;
    ; ---- Y component ----
    inc hl          ; move to y_low
    inc hl
    inc hl
    SRA (hl)        ; y_high
    dec hl
    RR  (hl)
    inc hl
    SRA (hl)
    dec hl
    RR  (hl)
	;
    pop hl
    ret

;---------------------------------------------------------
; CompareToThresh2D(hl: vector, bc: thresh)->(carry):()
; Compares l1-norm of vector to threshold T
; carry set: |vector| < T

CompareToThresh2D:	
	push bc
	push de
	push hl
	;
	push bc
	; X
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl	
	ex de,hl			; store hl
	push hl
	call ABS_88
	pop hl
	ex de,hl			; |X| in de
	; Y
	ld c,(hl)
	inc hl
	ld b,(hl)
	push bc
	call ABS_88
	pop hl				; |Y| in hl
	;
	add hl,de			; l1 norm in hl
	pop de				; thresh -> de
	or A
	sbc hl, de
	;
	pop hl
	pop de
	pop bc
	ret

;---------------------------------------------------------
; ABS_88()->():(hl): absolute value for signed 8.8 fixed-point
; input:   (SP+2)   = low byte
;          (SP+3) = high byte
; output: (SP+2),(SP+3) replaced with absolute value
; USES STACK to pass the parameter:
;     push bc
;     call ABS
;     pop bc
; result: BC = |BC|
ABS_88:
	push af
	push de				; save de
	ld hl,$0006
	add hl,SP			; get argument (low=LSB, high=MSB)    
    ld e,(hl)
	inc hl
	ld d,(hl)	
	bit 7,d				; already positive? 
    jr z,abs_done		; yes	
	;
	;two's complement
	ld a,e
    cpl
    ld e,a
    ld a,d
    cpl
    ld d,a
	; write back |value|
    inc de
    ld (hl),d
	dec hl
	ld (hl),e
abs_done:
	pop de
	pop af
    ret

; ------------------------------------------------------------
; Stash2D(hl: Vector)->():()
; Copies 2D vector (hl) to stash
Stash2D:
	push bc
	push de
	push hl
	ld de,V2_STASH
	LDI
	LDI
	LDI
	LDI
	pop hl
	pop de
	pop bc
	ret

Unstash2D:
	push bc
	push de
	push hl
	ld de,V2_STASH
	ex de,hl
	LDI
	LDI
	LDI
	LDI
	pop hl
	pop de
	pop bc
	ret

; ------------------------------------------------------------
; Copy2D(hl: source, de:target)->():()
Copy2D:
	push de
	push hl
	LDI
	LDI
	LDI
	LDI
	pop hl
	pop de
	ret
	
; ------------------------------------------------------------
; Trim2D((hl): vectorAdr, bc: thresh)->(hl: vectorAdr):(af, bc, de, hl)
; Trim a 2D vector to length about (but smaller than) thresh
; utilizing L1 norm
; Trimming Algorithm:
; init with vector of length/2
; as long as len(vec) < T: add 1/4-length , 1/8-length etc.
; do until 1/32
; (always loops 4 times)
; use the last result < T
; (~ 3000T)
Trim2D:		
	call CompareToThresh2D	
	ret c						; NO TRIMMING REQUIRED
	;
	; Trimming required
	; initialize with a vector below thresh
	; divide by 2 until |vector| < T
tr_init:		
	call Div2_2D
	call CompareToThresh2D
	jr nc, tr_init			
	; here: |V| < T	
	ld de, V2_TEMPVECTOR
	call Copy2D			; copy vector to temp
	ld a,5				; loop 5-1=4 times max (1/2  + (1/4 + 1/8 + 1/16 + 1/32) )
tr_loop:
	dec A
	jr z, tr_end	
	;
	ex de,hl
	call Div2_2D			; temp / 2
	ex de,hl
	call Stash2D				; keep previous result
	call Sum2D					; V <- V + temp	
	call CompareToThresh2D		; below T?	
	jr c,tr_loop		
	call Unstash2D		; get last result < T,
	jr tr_loop			; try again with 1/2 sized summand
tr_end:	
	ret