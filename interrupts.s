.ORGA $40 ; VBlank interrupt
	jp vblankInterrupt

.ORGA $50 ; Timer interrupt
	jp timerInterrupt


.SECTION Interrupt_Implementations FREE

timerInterrupt:
	push af
	push bc
	push de
	push hl
	ld a, INT_TIMER
	ldh (<hInterruptType), a
; 	ld hl, rnd
; 	inc (hl)
; 	ldh a, (R_SVBK)
; 	push af
; 	ld a, MUSIC_WRAM_BANK
; 	ldh (R_SVBK), a
; 	call xpmp_update
	pop af
	ldh (R_SVBK), a

	pop hl
	pop de
	pop bc
	pop af
	reti


vblankInterrupt:
	push af
	ld a,INT_VBLANK
	ldh [<hInterruptType],a

	ld a,[wCameraY]
	ldh [R_SCY],a
	ld a,[wCameraX]
	ldh [R_SCX],a

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
