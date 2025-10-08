; Put your Z80 assembly code into code files
    .model Spectrum48
	.org #8000

Vector2_A:	defs 4

	jp Start
	#include "UtilsDBG.asm"
	#include "Screen.asm"
	#include "Vector2D.asm" 
	#include "Centipede.asm"


; ====================================================
Start:
	ld hl, $0000		; reset cursor
	call SetCursor
	;	
	call CP_initAll		; init all centipedes
	call CP_infoAll		; print info
	call CP_move


	



ente:
	jr ente


