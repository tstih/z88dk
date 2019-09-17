;
;	Startup for Gameboy
;


	module gb_crt0

;--------
; Include zcc_opt.def to find out some info
;--------

        defc    crt0 = 1
        INCLUDE "zcc_opt.def"

;--------
; Some scope definitions
;--------

        EXTERN    _main           ;main() is always external to crt0 code
        EXTERN    asm_im1_handler

        PUBLIC    cleanup         ;jp'd to by exit()
        PUBLIC    l_dcal          ;jp(hl)


        defc    TAR__clib_exit_stack_size = 0
        defc    TAR__register_sp = 0xE000
	defc	CRT_KEY_DEL = 127
	defc	__CPU_CLOCK = 4000000
        INCLUDE "crt/classic/crt_rules.inc"

        defc CRT_ORG_CODE = 0x0000

	INCLUDE	"gb_globals.def"

	org	  CRT_ORG_CODE


if (ASMPC<>$0000)
        defs    CODE_ALIGNMENT_ERROR
endif
	ret

	defs	$0010-ASMPC
if (ASMPC<>$0010)
        defs    CODE_ALIGNMENT_ERROR
endif
	defb	0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01
        defb	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80

	defs	$0040-ASMPC
if (ASMPC<>$0040)
        defs    CODE_ALIGNMENT_ERROR
endif
	; VBL
	ld	hl,int_0x40
	jp	int

	defs	$0048-ASMPC
if (ASMPC<>$0048)
        defs    CODE_ALIGNMENT_ERROR
endif
	; LCD
	ld	hl,int_0x48
	jp	int

	defs	$0050-ASMPC
if (ASMPC<>$0050)
        defs    CODE_ALIGNMENT_ERROR
endif
	; TIM 
	ld	hl,int_0x50
	jp	int

	defs	$0058-ASMPC
if (ASMPC<>$0058)
        defs    CODE_ALIGNMENT_ERROR
endif
	; SIO
	ld	hl,int_0x58
	jp	int


	defs	$0060-ASMPC
if (ASMPC<>$0060)
        defs    CODE_ALIGNMENT_ERROR
endif
	; JOY
	ld	hl,int_0x60
	jp	int

int:
	push	af
	push	bc
	push	de
int1:
	ld	a,(hl+)
	or	(hl)
	jr	z,int2
	ld	a,(hl-)
	ld	l,a
	ld	h,a
	call	l_dcal
	pop	hl
	inc	hl
	jr	int1
int2:
	pop	de
	pop	bc
	pop	af
	pop	hl	
	reti


	; Gameboy header
	defs	$0100-ASMPC
if (ASMPC<>$0100)
        defs    CODE_ALIGNMENT_ERROR
endif
header:
	nop
	jp	0x150
        defb   0xCE,0xED,0x66,0x66
        defb   0xCc,0x0D,0x00,0x0B
        defb   0x03,0x73,0x00,0x83
        defb   0x00,0x0c,0x00,0x0D
        defb   0x00,0x08,0x11,0x1F
        defb   0x88,0x89,0x00,0x0E
        defb   0xDc,0xCc,0x6E,0xE6
        defb   0xDD,0xDD,0xD9,0x99
        defb   0xBb,0xBb,0x67,0x63
        defb   0x6E,0x0E,0xEc,0xCC
        defb   0xDD,0xDc,0x99,0x9F
        defb   0xBb,0xB9,0x33,0x3E

	defs	$0134-ASMPC
if (ASMPC<>$0134)
        defs    CODE_ALIGNMENT_ERROR
endif
__header_title:
	defm	"MadeByZ88dk"
	defb	0

	defs	$0144-ASMPC
if (ASMPC<>$0144)
        defs    CODE_ALIGNMENT_ERROR
endif
	defb	0,0,0

__header_cartridge_type:
	defb	0
__header_romsize:
	defb	0		;32kb
__header_ramsize:
	defb	0		;0kb
__header_makerid:
	defb	0,0
__header_version:
	defb	1
__header_complement_check:
	defb	0
__header_checksum:
	defb	0,0

	defs	$0150-ASMPC
if (ASMPC<>$0150)
        defs    CODE_ALIGNMENT_ERROR
endif
program:
	di
	ld	d,a		;Save CPU type
	xor	a
        INCLUDE "crt/classic/crt_init_sp.asm"
	; Clear from 0xc00 to 0xdfff
	ld	hl,0xdfff
	ld	c,0x20
	ld	b,0x00
clear1:
	ld	(hl-),a
	dec	b
	jr	nz,clear1
	dec	c
	jr	nz,clear1
	; Clear from 0xfe00 to feff
	ld	hl,0xfeff
	ld	b,0
clear2:
	ld	(hl-),a
	dec	b
	jr	nz,clear2
	; Clear from 0xff80 to 0xffff
	ld	hl,0xffff
	ld	b,0x80
clear3:
	ld	(hl-),a
	dec	b
	jr	nz,clear3
	ld	a,d
	ld	(__cpu),a

	call	_display_off		;Turn screen off
	; Initialise the display
	xor	a
	ldh	(SCY),a
	ldh	(SCX),a
	ldh	(STAT),a
	ldh	(WY),a
	ld	a,7
	ldh	(WX),a


	; Copy refresh_OAM routine to high ram
        ld      bc,refresh_OAM
        ld      hl,start_refresh_OAM
        ld      b,end_refresh_OAM-start_refresh_OAM
copy1:
        ld      a,(hl+)
        ldh     (c),a
        inc     c
        dec     b
        jr      nz,copy1

	;; Interrupt handlers
	ld	bc,vbl
	call	add_VBL
	ld	bc,serial_IO
	call	add_SIO

        ;; Standard color palettes
        ld      a,@11100100     ; Grey 3 = 11 (Black)
                                ; Grey 2 = 10 (Dark grey)
                                ; Grey 1 = 01 (Light grey)
                                ; Grey 0 = 00 (Transparent)
        ldh     (BGP),a
        ldh     (OBP0),a
        ld      A,@00011011
        ldh     (OBP1),a

        ;; Turn the screen on
        ld      a,@11000000     ; LCD           = On
                                ; WindowBank    = 0x9C00
                                ; Window        = Off
                                ; BG Chr        = 0x8800
                                ; BG Bank       = 0x9800
                                ; OBJ           = 8x8
                                ; OBJ           = Off
                                ; BG            = Off
        ldh     (LCDC),a
        xor     a
        ldh     (IF),A
        ld      a,@00001001     ; Pin P10-P13   =   Off
                                ; Serial I/O    =   On
                                ; Timer Ovfl    =   Off
                                ; LCDC          =   Off
                                ; V-Blank       =   On
        ldh     (IE),a

        xor     a
        ldh     (NR52),a       ; Turn sound off
        ldh     (SC),a         ; Use external clock
        ld      A,DT_IDLE
        ldh     (SB),a         ; Send IDLE byte
        ld      A,0x80
        ldh     (SC),a         ; Use external clock

	call    crt0_init_bss
IF 0
	ld	hl,sp+0
	ld	d,h
	ld	e,l
	ld	hl,exitsp
	ld	a,l
	ld	(hl+),a
	ld	a,h
	ld	(hl+),a
ENDIF
; Optional definition for auto MALLOC init
; it assumes we have free space between the end of
; the compiled program and the stack pointer
IF DEFINED_USING_amalloc
    INCLUDE "crt/classic/crt_init_amalloc.asm"
ENDIF
	ei
	push	hl	;argv
	push	bc	;argc
	call	banked_call
	defw	_main
	defw	1		;Bank
cleanup:
	halt
	jr	cleanup


	defs	0x01E0 - ASMPC
if (ASMPC<>0x01E0)
        defs    CODE_ALIGNMENT_ERROR
endif
MODE_TABLE:
	;; Jump table for modes
	ret

	;; Code that needs to be in home

        ;; Call the initialization function for the mode specified in hl
set_mode:
        ld      a,l
        ld      (mode),a

        ;; AND to get rid of the extra flags
        and     0x03
        ld      l,a
        ld      bc,MODE_TABLE
        sla     l               ; Multiply mode by 4
        sla     l
        add     hl,bc
l_dcal:
        jp      (hl)            ; Jump to initialization routine

remove_VBL:
        ld      hl,int_0x40
        jp      remove_int
remove_LCD:
        ld      hl,int_0x48
        jp      remove_int
remove_TIM:
        ld      hl,int_0x50
        jp      remove_int
remove_SIO:
        ld      hl,int_0x58
        jp      remove_int
remove_JOY:
        ld      hl,int_0x60
        jp      remove_int
add_VBL:
        ld      hl,int_0x40
        jp      add_int
add_LCD:
        ld      hl,int_0x48
        jp      add_int
add_TIM:
        ld      hl,int_0x50
        jp      add_int
add_SIO:
        ld      hl,int_0x58
        jp      add_int
add_JOY:
        ld      hl,int_0x60
        jp      add_int

        ;; Remove interrupt BC from interrupt list hl if it exists
        ;; Abort if a 0000 is found (end of list)
        ;; Will only remove last int on list
remove_int:
        ld      a,(hl+)
        ld      e,a
        ld      d,(hl)
        or      d
        ret     z               ; No interrupt found

        ld      a,e
        cp      c
        jr      nz,remove_int
        ld      a,d
        cp      b
        jr      nz,remove_int

        xor     a
        ld      (hl-),a
        ld      (hl),a
        inc     a               ; Clear Z flag

        ;; Now do a memcpy from here until the end of the list
        ld      d,h
        ld      e,l
        dec     de

        inc     hl
remove_int_1:
        ld      a,(hl+)
        ld      (de),a
        ld      b,a
        inc     de
        ld      a,(hl+)
        ld      (de),a
        inc     de
        or      b
        ret     z
        jr      remove_int_1

        ;; Add interrupt routine in BC to the interrupt list in hl
add_int:
        ld      a,(hl+)
        or      (hl)
        jr      Z,add_int_doit
        inc     hl
        jr      add_int
add_int_doit:
        ld      (hl),B
        dec     hl
        ld      (hl),C
        ret

        ;; VBlank interrupt
vbl:
        ld      hl,_sys_time
        inc     (hl)
        jr      nz,vbl_1
        inc     hl
        inc     (hl)
vbl_1:
        call    refresh_OAM

        ld      A,0x01
        ld      (vbl_done),A
        ret

        ;; Wait for VBL interrupt to be finished
_wait_vbl_done:
        ;; Check if the screen is on
        ldh     a,(LCDC)
        add     a
        ret     nc              ; Return if screen is off
        xor     a
        di
        ld      (vbl_done),A   ; Clear any previous sets of vbl_done
        ei
wait_1:
        halt                    ; Wait for any interrupt
        nop                     ; HALT sometimes skips the next instruction
        ld      a,(vbl_done)   ; Was it a VBlank interrupt?
        ;; Warning: we may lose a VBlank interrupt, if it occurs now
        or      a
        jr      z,wait_1        ; No: back to sleep!

        xor     a
        ld      (vbl_done),A
        ret

_display_off:
        ;; Check if the screen is on
        ldh     a,(LCDC)
        add     a
        ret     nc              ; Return if screen is off
                                ; We wait for the *NEXT* VBL
wait_next:
        ldh     a,(LY)
        CP      0x92            ; Smaller than or equal to 0x91?
        jr      nc,wait_next    ; Loop until smaller than or equal to 0x91
wait_next_2:
        ldh     a,(LY)
        CP      0x91            ; Bigger than 0x90?
        jr      c,wait_next_2   ; Loop until bigger than 0x90

        ldh     a,(LCDC)
        and     @01111111
        ldh     (LCDC),a       ; Turn off screen
        ret

        ;; Copy OAM data to OAM RAM
start_refresh_OAM:
        ld      a,+(OAM / 256)
        ldh     (DMA),a        ; Put A into DMA registers
        ld      a,0x28         ; We need to wait 160 ns
OAM_1:
        dec     a
        jr      nz,OAM_1
        ret
end_refresh_OAM:

        ;; Serial interrupt
serial_IO:
        ld      A,(__io_status) ; Get status

        cp      IO_RECEIVING
        jr      nz,check_sending

        ;; Receiving data
        ldh     a,(SB)         ; Get data byte
        ld      (__io_in),A     ; Store it
	jr	set_idle

check_sending:
        cp      IO_SENDING
        jr      nz,not_sending

        ;; Sending data
        ldh     a,(SB)         ; Get data byte
        cp      DT_RECEIVING
        jr      z,set_idle
        ld      a,IO_ERROR
        jr      set_status
set_idle:
        ld      a,IO_IDLE
set_status:
        ld      (__io_status),a ; Store status
        xor     a
        ldh     (SC),a         ; Use external clock
        ld      a,DT_IDLE
        ldh     (SB),a         ; Reply with IDLE byte
not_sending:
        ld      a,0x80
        ldh     (SC),a         ; Enable transfer with external clock
        ret

_mode:
        ld      hl,sp+2         ; Skip return address
        ld      l,(hl)
        ld      h,0x00
        call    set_mode
        ret

_get_mode:
        ld      hl,mode
        ld      e,(hl)
        ret

_enable_interrupts:
        ei
        ret

_disable_interrupts:
        di
        ret

_reset:
        ld      a,(__cpu)
        jp      program

_set_interrupts:
        di
        ld      hl,sp+2         ; Skip return address
        xor     A
        ldh     (IF),A         ; Clear pending interrupts
        ld      A,(hl)
        ldh     (IE),A
        ei                      ; Enable interrupts
        ret

_remove_VBL:
        push    bc
        ld      hl,sp+4        ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    remove_VBL
        pop     bc
        ret

_remove_LCD:
        push    bc
        ld      hl,sp+4        ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    remove_LCD
        pop     bc
        ret

_remove_TIM:
        push    bc
        ld      hl,sp+4        ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    remove_TIM
        pop     bc
        ret

_remove_SIO:
        push    BC
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    remove_SIO
        pop     bc
        ret

_remove_JOY:
        push    bc
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    remove_JOY
        pop     bc
        ret

_add_VBL:
        push    bc
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    add_VBL
        pop     bc
        ret

_add_LCD:
        push    BC
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        INC     hl
        ld      b,(hl)
        call    add_LCD
        pop     BC
        ret

_add_TIM:
        push    bc
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    add_TIM
        pop     bc
        ret

_add_SIO:
        push    BC
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    add_SIO
        pop     BC
        ret

_add_JOY:
        push    bc
        ld      hl,sp+4         ; Skip return address and registers
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        call    add_JOY
        pop     bc
        ret

_clock:
        ld      hl,_sys_time
        di
        ld      a,(hl+)
        ei
        ;; Interrupts are disabled for the next instruction...
        ld      d,(hl)
        ld      e,a
        ret

__printTStates:
        ret

        ;; Performs a long call.
        ;; Basically:
        ;;   call banked_call
        ;;   .dw low
        ;;   .dw bank
        ;;   remainder of the code
        ;; Total m-cycles:
        ;;      3+4+4 + 2+2+2+2+2+2 + 4+4+ 3+4+1+1+1
        ;;      = 41 for the call
        ;;      3+3+4+4+1
        ;;      = 15 for the ret
banked_call:
        pop     hl              ; Get the return address
        ld      a,(__current_bank)
        push    af              ; Push the current bank onto the stack
        ld      e,(hl)          ; Fetch the call address
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl+)         ; ...and page
        inc     hl              ; Yes this should be here
        push    hl              ; Push the real return address
        ld      (__current_bank),a
        ld      (MBC1_ROM_PAGE),a      ; Perform the switch
        ld      hl,banked_ret  ; Push the fake return address
        push    hl
        ld      l,e
        ld      h,d
        jp      (hl)

banked_ret:
        pop     hl              ; Get the return address
        pop     af              ; Pop the old bank
        ld      (MBC1_ROM_PAGE),a
        ld      (__current_bank),a
        jp      (hl)


	INCLUDE "crt/classic/crt_runtime_selection.asm" 
	
	INCLUDE	"crt/classic/crt_section.asm"

	SECTION	bss_crt

	GLOBAL	banked_call
	GLOBAL	set_mode
	GLOBAL	_reset
	GLOBAL	_display_off
	GLOBAL	_wait_vbl_done
	GLOBAL	_add_VBL
	GLOBAL	_add_LCD
	GLOBAL	_add_TIM
	GLOBAL	_add_SIO
	GLOBAL	_add_JOY

	GLOBAL	__cpu
	GLOBAL	__io_out
	GLOBAL	__io_in
	GLOBAL	__io_status



__cpu:		defb    0            ; GB type (GB, PGB, CGB)
mode:		defb    0            ; Current mode
__io_out:	defb	0            ; Byte to send
__io_in:	defb	0            ; Received byte
__io_status:	defb	0            ; Status of serial IO
vbl_done:	defb	0            ; Is VBL interrupt finished?
__current_bank:	defb	0            ; Current MBC1 style bank.
_sys_time:	defw	0            ; System time in VBL units
int_0x40:	defs	16
int_0x48:	defs	16
int_0x50:	defs	16
int_0x58:	defs	16
int_0x60:	defs	16
