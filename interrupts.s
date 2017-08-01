.ORGA $40 ; VBlank interrupt
	jp vblankInterrupt

.ORGA $48 ; LCD interrupt
	jp lcdInterrupt

.ORGA $50 ; Timer interrupt
	jp timerInterrupt

.ORGA $58 ; Serial
	reti

.ORGA $60 ; Joyped
	reti

.SECTION Interrupt_Implementations FREE

timerInterrupt:
	push af
	push bc
	push de
	push hl
; 	ld a, INT_TIMER
; 	ldh (<hInterruptType), a

	pop hl
	pop de
	pop bc
	pop af
	reti


lcdInterrupt:
	push af
	push de
	push hl

	ldh a,[<hOamFlicker]
	or a
	jr z,@end

	dec a
	ld l,a
	ld h,$fe ; OAM memory
	ldh a,[R_LY]
	and 1
	jr z,+
	call @waitForHblank
	ld e,l
	ld d,>wOam
	ld a,[de]
	ld [hl],a
	inc l
	inc l
	inc l
	inc l
	ld [hl],a
	jr ++
+
	call @waitForHblank
	xor a
	ld [hl],a
	inc l
	inc l
	inc l
	inc l
	ld [hl],a
++

	ldh a,[<hOamFlickerLine]
	ld b,a
	ldh a,[<hOamFlickerSize]
	ld c,a
	ldh a,[R_LYC]
	sub b
	cp c
	jr nc,++
+
	ldh a,[R_LYC]
	inc a
	ldh [R_LYC],a
	jr +++
++
	ld a,b
	ldh [R_LYC],a
+++

@end
	pop hl
	pop de
	pop af
	reti

@waitForHblank:
	ldh a,[R_STAT]
	and 3
	or a
	ret z
	jr @waitForHblank


vblankInterrupt:
	push af
	push bc
	push de
	push hl

	ld a,INT_VBLANK
	ldh [<hInterruptType],a

	; Update BG scroll
	ld a,[wCameraY]
	ldh [R_SCY],a
	ld a,[wCameraX]
	ldh [R_SCX],a

	; Update window scroll
	ld a,[wWY]
	ldh [R_WY],a
	ld a,[wWX]
	ldh [R_WX],a

	; Update LCDC if actually in vblank
	ldh a,[R_LY]
	cp $90
	jr nz,+
	ld a,[wLCDC]
	ldh [R_LCDC],a
+
	call vblankUpdateWindowMap
	call hOamProcedure
	call xpmp_update

	pop hl
	pop de
	pop bc
	pop af
	reti

vblankUpdateWindowMap:
; =======================================================================================
; Updates a 3rd of the window each frame
; =======================================================================================
	ldh a,[<hUpdateWindowMap]
	or a
	ret z

	ld hl,wWindowMap
	ld de,$9c00
	ld b,32*4/16
	jp copyMemory16


waitForVblank:
	ldh a,[R_LCDC]
	and $80
	ret z

	xor a
	ldh [<hInterruptType],a
-
	halt
	nop
	ldh a,[<hInterruptType]
	and INT_VBLANK
	jr z,-
	ret

.ENDS
