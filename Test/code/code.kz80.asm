; Put your Z80 assembly code into code files
    .model Spectrum48
	.org #8000

Vector2_A:	defs 4

	jp Start
	#include "UtilsDBG.asm"
	#include "Utils.asm"
	#include "Screen.asm"
	#include "Accelerator.asm"
	#include "Vector2D.asm" 
	#include "Centipede.asm"

VECTOR:		defs 4


; ====================================================
Start:
	call ClearScreen	
	;	
	call CP_initAll		; init all centipedes
	call CP_infoAll		; print info
	
mvloop:	
	call ClearScreen
	call CP_moveAll
	call CP_infoAll
	ld hl,2000
	call DelayMS
	jr mvloop
ente:
	jr ente


