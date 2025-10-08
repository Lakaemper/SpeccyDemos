; Put your Z80 assembly code into code files
    .model Spectrum48
	.org #8000

Vector2_A:	defs 4
Vector2_B:	defs 4
Vector_temp1:	defs 4

	jp Start

; ====================================================
Start:
	ld hl, $0000		; reset cursor
	call SetCursor
	;
	ld bc, $0201		; x1
	ld de, $0100		; y1
	ld hl, Vector2_A	
	call Store2D		; bcde -> (hl)
	call Print2D
	ld bc,$0200
	push hl
	call Trim2D
	pop hl
	call Print2D

ente:
	jr ente

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
; Sum2D(hl: adr x1,y1, de: adr x2, y2)->(hl: adr resX,resY):(f)
; 8.8 addition of 2D vectors
Sum2D:
	push af
	push bc
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
	pop bc
	pop af
	ret

;---------------------------------------------------------
; CompareToThresh2D(hl: vector, bc: thresh)->(carry):()
; carry set: |vector| < T
CompareToThresh2D:	
	push bc
	push de
	push hl
	;
	push bc
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld h,b
	ld l,c
	add hl,de			; l1 norm in hl
	pop de				; thresh -> de
	or A
	sbc hl, de
	;
	pop hl
	pop de
	pop bc
	ret

; ------------------------------------------------------------
; Half2D(hl: adr)->():()
; reduce a 2D 8.8 vector to half its lenght in place
Half2D:
	push hl
	inc hl
	srl (hl)
	dec hl		
	rr (hl)			; x / 2
	inc hl
	inc hl
	inc hl
	srl (hl)
	dec hl
	rr (hl)			; y / 2
	pop hl
	ret

; ------------------------------------------------------------
; Stash2D(hl: Vector)->():()
; Copies 2D vector (hl) to stash
Vector_STASH:	defs 4
Stash2D:
	push bc
	push de
	push hl
	ld de,Vector_STASH
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
	ld de,Vector_STASH
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
; use the last result < T
Trim2D:		
	call CompareToThresh2D	
	ret c						; NO TRIMMING REQUIRED
	;
	; Trimming required
	; initialize with a vector below thresh
	; divide by 2 until |vector| < T
tr_init:		
	call Half2D
	call CompareToThresh2D
	jr nc, tr_init			
	; here: |V| < T	
	ld de, Vector_temp1
	call Copy2D			; copy vector to temp
	ld a,5				; loop 5-1=4 times max (1/2  + (1/4 + 1/8 + 1/16 + 1/32) )
tr_loop:
	dec A
	jr z, tr_end	
	;
	ex de,hl
	call Half2D			; temp / 2
	ex de,hl
	call Stash2D		; keep previous result
	call Sum2D			; V <- V + temp
	call CompareToThresh2D	; still below T?	
	jr c,tr_loop		
	;
	call Unstash2D		; last result < T -> V
tr_end:	
	ret

; ------------------------------------------------------------
; SetCursor(hl = row, col)->():(?)
SetCursor:
	ex de,hl
	ld hl,$5C3C		; Col
	ld (hl),e
	inc hl
	ld (hl),d
	ret

; ------------------------------------------------------------
; Print2D(hl: adress)->():()
; Prints an 8.8 2D vector in the format:  (xxxx,yyyy)<newline>
; x = BC (8.8 fixed), y = DE (8.8 fixed)

Print2D:
    push af
    push bc
	push de
	push hl

    ; Print '('
    push hl
	ld a,'('	
    rst 16          ; RST 10h = 0x10 = print A
	ld a,'$'
	rst 16
	pop hl

    ; --- Print x ---
    ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ex de,hl
    call Print16
	ex de,hl

    ; Print comma
    push hl
	ld a,','    
	rst 16
	ld a,'$'
	rst 16
	pop hl
	;
    ; --- Print y ---
    ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ex de,hl
    call Print16
	ex de,hl
	;
    ; Print ')'
    ld a,')'
    rst 16
	;
    ; Print newline (CR/LF)
    ld a,13
    rst 16    
	;
    pop hl
	pop de
	pop bc
    pop af
    ret


; ------------------------------------------------------------
; Print16(hl)->():()
; Input: HL = 16-bit value
; Prints 4 hex digits
Print16:
    push af
    push bc
	push de
	push hl
    ;
    ld a,h    
    srl a
	srl a
	srl a
	srl a
    call PrintHexDigit		; x high
    ld a,h
    and %00001111
    call PrintHexDigit		
    ld a,l    
    srl a
	srl a
	srl a
	srl a
    call PrintHexDigit
    ld a,l
    and %00001111
    call PrintHexDigit		; x low
    ;
	pop hl
	pop de
	pop bc
    pop af
    ret

; ------------------------------------------------------------
; PrintHexDigit
; Input: A = 0–15
; ------------------------------------------------------------
PrintHexDigit:
    cp 10
    jr c,ph_digit
    add a,'A'-10
    jr ph_out
ph_digit:
    add a,'0'
ph_out:
    rst 16
    ret

