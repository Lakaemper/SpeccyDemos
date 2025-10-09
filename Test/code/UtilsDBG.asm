        ATTR_P EQU 23693


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
    pop hl
	pop de
	pop bc
    pop af
    ret

; ------------------------------------------------------------
; PrintNewline()->():(exchange registers are altered)
PrintNewline:
    ld a,13
    rst 16
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

; ------------------------------------------------------------
;CLS
ClearScreen:
    push hl
    ld hl, ATTR_P
    ld (hl),$44         ; bright, paper 0, ink 4 (green)
    call $0DAF
    ld a,1              ; blue
    call 8859           ; setBorder
    pop hl
    ret

