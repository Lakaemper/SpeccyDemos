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
	call FrameSeedRandom
	call ClearScreen	
	call CP_initAll		; init all centipedes		
	call InitScreen
	xor a
	call SetBorder

mvloop:	
	call WaitFrame			
	call CP_moveAll
	call CP_plotAll
	call AnimateBG	
	call ReadKeyRow
	jr c,Start	
	jr mvloop


