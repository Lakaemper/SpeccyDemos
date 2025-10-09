; Put your Z80 assembly code into code files
    .model Spectrum48
	.org #8000

Vector2_A:	defs 4

	jp Start
	#include "UtilsDBG.asm"
	#include "Screen.asm"
	#include "Accelerator.asm"
	#include "Vector2D.asm" 
	#include "Centipede.asm"

VECTOR:		defs 4


; ====================================================
Start:
	call ClearScreen

	ld bc,$f100
	ld de,$0200
	ld hl,VECTOR
	call Store2D
	call Print2D
	call PrintNewline
	ld bc,$0300
	call Trim2D
	ld hl,VECTOR
	call Print2D

abc:
	jr abc





	;	
	call CP_initAll		; init all centipedes
	call CP_infoAll		; print info
	
mvloop:	
	call ClearScreen
	call CP_moveAll
	call CP_infoAll
	jr mvloop
ente:
	jr ente


