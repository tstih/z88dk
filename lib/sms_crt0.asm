;       Startup Code for Sega Master System
;
;	Haroldo O. Pinheiro February 2006
;
;	$Id: sms_crt0.asm,v 1.12 2016-04-25 12:58:31 dom Exp $
;

	DEFC	ROM_Start  = $0000
	DEFC	INT_Start  = $0038
	DEFC	NMI_Start  = $0066
	DEFC	CODE_Start = $0100
	DEFC	RAM_Start  = $C000
	DEFC	RAM_Length = $2000
	DEFC	Stack_Top  = $dff0

	MODULE  sms_crt0

;-------
; Include zcc_opt.def to find out information about us
;-------

	INCLUDE "zcc_opt.def"

;-------
; Some general scope declarations
;-------

        EXTERN    _main           ;main() is always external to crt0 code
        PUBLIC    cleanup         ;jp'd to by exit()
        PUBLIC    l_dcal          ;jp(hl)


        PUBLIC    exitsp          ;Pointer to atexit() stack
        PUBLIC    exitcount       ;Number of atexit() functions registered

        PUBLIC    __sgoioblk      ;std* control block

        PUBLIC    heaplast        ;Near malloc heap variables
        PUBLIC    heapblocks      ;

        
        PUBLIC	fputc_vdp_offs	;Current character pointer
        
	PUBLIC	aPLibMemory_bits;apLib support variable
	PUBLIC	aPLibMemory_byte;apLib support variable
	PUBLIC	aPLibMemory_LWM	;apLib support variable
	PUBLIC	aPLibMemory_R0	;apLib support variable

	PUBLIC	raster_procs	;Raster interrupt handlers
	PUBLIC	pause_procs	;Pause interrupt handlers
	
	PUBLIC	timer		;This is incremented every time a VBL/HBL interrupt happens
	PUBLIC	_pause_flag	;This alternates between 0 and 1 every time pause is pressed
	
	PUBLIC	RG0SAV		;keeping track of VDP register values
	PUBLIC	RG1SAV
	PUBLIC	RG2SAV
	PUBLIC	RG3SAV
	PUBLIC	RG4SAV
	PUBLIC	RG5SAV
	PUBLIC	RG6SAV
	PUBLIC	RG7SAV

	org    ROM_Start

	jp	start
	
	defm    "Sega Master System - Small C+"
	
;-------        
; Interrupt handlers
;-------
filler1:
	defs	(INT_Start - filler1)

int_RASTER:
	push	hl
	
	ld	a, ($BF)
	or	a
	jp	p, int_not_VBL	; Bit 7 not set
	jr	int_VBL

int_not_VBL:
	pop	hl
	reti
	
int_VBL:
	ld	hl, timer
	ld	a, (hl)
	inc	a
	ld	(hl), a
	inc	hl
	ld	a, (hl)
	adc	a, 1
	ld	(hl), a		;Increments the timer
	
	ld	hl, raster_procs
	jr	int_handler

filler2:
	defs	(NMI_Start - filler2)
int_PAUSE:
	push	hl
	
	ld	hl, _pause_flag
	ld	a, (hl)
	xor	a, 1
	ld	(hl), a
	
	ld	hl, pause_procs
	jr	int_handler	

int_handler:
	push	af
	push	bc
	push	de
int_loop:
	ld	a, (hl)
	inc	hl
	or	(hl)
	jr	z, int_done
	push	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	h, a
	call	call_int_handler
	pop	hl
	inc	hl
	jr	int_loop
int_done:
	pop	de
	pop	bc
	pop	af
	pop	hl
	
	ei

	reti

call_int_handler:
	jp	(hl)

;-------        
; Beginning of the actual code
;-------
filler3:
	defs   (CODE_Start - filler3)

start:
; Make room for the atexit() stack
	ld	hl,Stack_Top-64
	ld	sp,hl
; Clear static memory
	ld	hl,RAM_Start
	ld	de,RAM_Start+1
	ld	bc,RAM_Length-1
	ld	(hl),0
	ldir
	ld      (exitsp),sp

	call	crt0_init_data
	
	call	DefaultInitialiseVDP
	
	im	1
	ei

; Entry to the user code
	call    _main

cleanup:
;
;       Deallocate memory which has been allocated here!
;
	push	hl
IF !DEFINED_nostreams
IF DEFINED_ANSIstdio
	EXTERN 	closeall
	call	closeall
ENDIF
ENDIF

endloop:
	jr	endloop
l_dcal:
	jp      (hl)
	
;---------------------------------
; VDP Initialization
;---------------------------------
DefaultInitialiseVDP:
    push hl
    push bc
        ld hl,_Data
        ld b,_End-_Data
        ld c,$bf
        otir
    pop bc
    pop hl
    ret

    DEFC SpriteSet          = 0       ; 0 for sprites to use tiles 0-255, 1 for 256+
    DEFC NameTableAddress   = $3800   ; must be a multiple of $800; usually $3800; fills $700 bytes (unstretched)
    DEFC SpriteTableAddress = $3f00   ; must be a multiple of $100; usually $3f00; fills $100 bytes

_Data:
    defb @00000100,$80
    ;     |||||||`- Disable synch
    ;     ||||||`-- Enable extra height modes
    ;     |||||`--- SMS mode instead of SG
    ;     ||||`---- Shift sprites left 8 pixels
    ;     |||`----- Enable line interrupts
    ;     ||`------ Blank leftmost column for scrolling
    ;     |`------- Fix top 2 rows during horizontal scrolling
    ;     `-------- Fix right 8 columns during vertical scrolling
    defb @10000100,$81
    ;      |||| |`- Zoomed sprites -> 16x16 pixels
    ;      |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
    ;      |||`---- 30 row/240 line mode
    ;      ||`----- 28 row/224 line mode
    ;      |`------ Enable VBlank interrupts
    ;      `------- Enable display
    defb (NameTableAddress/1024) |@11110001,$82
    defb (SpriteTableAddress/128)|@10000001,$85
    defb (SpriteSet/4)           |@11111011,$86
    defb $f|$f0,$87
    ;     `-------- Border palette colour (sprite palette)
    defb $00,$88
    ;     ``------- Horizontal scroll
    defb $00,$89
    ;     ``------- Vertical scroll
    defb $ff,$8a
    ;     ``------- Line interrupt spacing ($ff to disable)
_End:
	

;---------------------------------
; Select which printf core we want
;---------------------------------
	PUBLIC	asm_vfprintf
IF DEFINED_floatstdio
	EXTERN	asm_vfprintf_level3
	defc	asm_vfprintf = asm_vfprintf_level3
ELSE
	IF DEFINED_complexstdio
	        EXTERN	asm_vfprintf_level2
		defc	asm_vfprintf = asm_vfprintf_level2
	ELSE
	       	EXTERN	asm_vfprintf_level1
		defc	asm_vfprintf = asm_vfprintf_level1
	ENDIF
ENDIF

;--------
; Now, include the math routines if needed..
;--------
IF NEED_floatpack
;        INCLUDE "float.asm"
ENDIF

SECTION code_crt_init
crt0_init_data:
IF !DEFINED_nostreams
IF DEFINED_ANSIstdio
; Set up the std* stuff so we can be called again
        ld      hl,__sgoioblk+2
        ld      (hl),19 ;stdin
        ld      hl,__sgoioblk+6
        ld      (hl),21 ;stdout
        ld      hl,__sgoioblk+10
        ld      (hl),21 ;stderr
ENDIF
ENDIF
        ld      hl,$8080
        ld      (fp_seed),hl
        xor     a
        ld      (exitcount),a
SECTION code_crt_exit
        ret
SECTION code_compiler
SECTION code_clib
SECTION code_crt0_sccz80
SECTION code_l_sdcc
SECTION data_compiler
SECTION data_clib
SECTION rodata_compiler
SECTION rodata_clib

SECTION bss_crt
	org	RAM_Start
__sgoioblk:      	defs    40      ;stdio control block
exitsp:          	defw    0       ;atexit() stack
exitcount:       	defb    0       ;Number of atexit() routines
fp_seed:         	defs    6       ;Floating point seed (not used ATM)
extra:           	defs    6       ;Floating point spare register
fa:              	defs    6       ;Floating point accumulator
fasign:          	defb    0       ;Floating point variable
heapblocks:      	defw    0       ;Number of free blocks
heaplast:        	defw    0       ;Pointer to linked blocks
fputc_vdp_offs:		defw	0	;Current character pointer
aPLibMemory_bits:	defb	0	;apLib support variable
aPLibMemory_byte:	defb	0	;apLib support variable
aPLibMemory_LWM:	defb	0	;apLib support variable
aPLibMemory_R0:		defw	0	;apLib support variable
raster_procs:		defs	16	;Raster interrupt handlers
pause_procs:		defs	16	;Pause interrupt handlers
timer:			defw	0	;This is incremented every time a VBL/HBL interrupt happens
_pause_flag:		defb	0	;This alternates between 0 and 1 every time pause is pressed
RG0SAV:			defb	0	;keeping track of VDP register values
RG1SAV:			defb	0
RG2SAV:			defb	0
RG3SAV:			defb	0
RG4SAV:			defb	0
RG5SAV:			defb	0
RG6SAV:			defb	0
RG7SAV:			defb	0

SECTION bss_clib
IF DEFINED_defvarsaddr
	org	defvarsaddr
ENDIF
SECTION bss_compiler






