showTitlescreen:
	; Load gfx
	ld hl,titlescreenGfx
	ld de,$8800
	ld b,0 ; $1000
	call copyMemory16

	; Set tilemap
	ld hl,$9800+13*32
	xor a
	ld b,$80
-
 	ldi [hl],a
	inc a
	dec b
	jr nz,-
-
	ld hl,$9800+3*32
	ld a,$80
	ld b,$80
-
 	ldi [hl],a
	inc a
	dec b
	jr nz,-
-
 	ld d,FIRST_OBJECT_INDEX
	ld e,Object.enabled
	ld a,1
	ld [de],a
	ld e,Object.class
	ld a,C_KING
	ld [de],a
	ld e,Object.yh
	ld a,$48
	ld [de],a
	inc e
	inc e
	ld a,$40
	ld [de],a

 	call enableLcd
-
 	call updateBasics
	call waitForVblank

	call readInput
	ldh a,[<hButtonsJustPressed]
	and (BTN_A | BTN_START)
	jr nz,+
	jr -
+
	call fadeOut
	call deleteAllObjects
	call disableLcd
	call loadGfx
	jp runGame
