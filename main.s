.include "include/header.s"
.include "libgb/libgb.s"

.include "include/wram.s"
.include "include/hram.s"

.BANK 0

.ORGA $40 ; VBlank interrupt
	jp vblankInterrupt

.ORGA $100 ; Entry point
	jp begin


.SECTION "Main" FREE

begin:
	ld sp,wStackTop
	ld a,INT_VBLANK
	ldh [R_IE],a
	ei

	call disableLcd
	call clearVram
	call clearMemory
	call enableLcd

	ld c,R_BGP
main:
	ld a,[$ff00+c]
	inc a
	ld [$ff00+c],a
	call waitForVblank
	jr main


vblankInterrupt: ; Just wakes up the cpu
	push af
	ld a,INT_VBLANK
	ldh [<hInterruptType],a
	pop af
	reti


waitForVblank:
	ldh a,[R_LCDC]
	and $80
	ret z
-
	halt
	nop
	ldh a,[<hInterruptType]
	cp INT_VBLANK
	jr nz,-
	ret

.ENDS
