;
;	Amstrad PCW specific routines (DKTronics sound generator)
;	by Stefano Bodrato, 2021
;
;	int set_psg(int reg, int val);
;
;	Play a sound by PSG
;
;
;	$Id: set_psg_callee.asm $
;

        SECTION code_clib
	PUBLIC	set_psg_callee
	PUBLIC	_set_psg_callee

	PUBLIC ASMDISP_SET_PSG_CALLEE

set_psg_callee:
_set_psg_callee:

   pop hl
   pop de
   ex (sp),hl
	
.asmentry
	
    ld bc,$aa
	out (c),l

	ld c,$ab
	out (c),e

	ret

DEFC ASMDISP_SET_PSG_CALLEE = asmentry - set_psg_callee
