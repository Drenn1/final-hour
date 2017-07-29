addToOam:
; =======================================================================================
; Parameters: hl = oam data to load, bc = Y/X offset
; =======================================================================================
	ldi a,[hl]
	ldh [<hTmp1],a

--
	ldh a,[<hNumOamEntries]
	cp 40
	ret nc
	add a ; a *= 4
	add a
	ld de,wOam
	call addAToDE
	
	push bc
	ldi a,[hl] ; Y
	add b
	ld b,a
	ldi a,[hl] ; X
	add c
	ld c,a

	; Check if sprite is on-screen
	ld a,b
	or a
	jr z,@skipSprite
	cp 144+16
	jr nc,@skipSprite
	ld a,c
	or a
	jr z,@skipSprite
	cp 160+8
	jr nc,@skipSprite

	ld a,b
	ld [de],a
	inc de
	ld a,c
	ld [de],a
	inc de

	ldi a,[hl] ; Tile
	ld [de],a
	inc de
	ldi a,[hl] ; Flags
	ld [de],a

	ldh a,[<hNumOamEntries]
	inc a
	ldh [<hNumOamEntries],a
	jr @nextSprite

@skipSprite:
	inc hl
	inc hl

@nextSprite:
	pop bc
	ld a,[hTmp1]
	dec a
	ld [hTmp1],a
	jr nz,--
	ret

clearRemainingOam:
	ldh a,[<hNumOamEntries]
	cp 40
	ret nc
	add a
	add a
	ld hl,wOam
	call addAToHL
--
	xor a
	ldi [hl],a
	inc l
	inc l
	inc l
	ld a,l
	cp $a0
	jr c,--
	ret


convertPositionForOam:
; =======================================================================================
; Parameters: bc = position value (in room)
; Returns:    bc = position value (relative to camera, for oam)
; =======================================================================================
	push hl
	ld hl,wCameraY
	ld a,b
	sub [hl]
	add 16
	ld b,a

	inc hl
	ld a,c
	sub [hl]
	add 8
	ld c,a
	pop hl
	ret

drawCursor:
; Draw the cursor OAM.
	ld hl,wCursorY
	ldi a,[hl]
	swap a
	ld b,a
	ld a,[hl]
	swap a
	ld c,a

	call convertPositionForOam
	ld hl,@cursorOam
	jp addToOam

@cursorOam:
	.db 4
	.db 0 0 0 $00
	.db 0 8 0 $20
	.db 0 0 0 $40
	.db 0 8 0 $60


drawObjects:
; =======================================================================================
; Draws all objects in memory at $d000-$de00.
; =======================================================================================
	ld d, FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next

	; If selected, flicker the object
	ld a,[wSelectedObject]
	cp d
	jr nz,+
	ld a,[wSelectedObjectMovementCounter]
	or a
	jr nz,+
	ld a,[wFrameCounter]
	and $10
	jr z,@next
+
	ld e,Object.yh
	ld a,[de]
	ld b,a
	ld e,Object.xh
	ld a,[de]
	ld c,a
	call convertPositionForOam
	ld hl,classOam
	push de
	call addToOam
	pop de

@next:
	inc d
	ld a,d
	cp LAST_OBJECT_INDEX+1
	jr c,--
	ret

classOam:
	.db 2
	.db 0 0 $04 0
	.db 0 8 $06 0


