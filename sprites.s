addToOam:
	xor a

addToOamWithFlags:
; =======================================================================================
; Parameters: hl = oam data to load,
;             bc = Y/X offset
;             a = value to OR flags with
; =======================================================================================
	ldh [<hTmp2],a
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
	cp SCREEN_HEIGHT*16+16
	jr nc,@skipSprite
	ld a,c
	or a
	jr z,@skipSprite
	cp SCREEN_WIDTH*16+8
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
	ldh a,[<hTmp2] ; Flags
	or [hl]
	inc hl
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
; =======================================================================================
; Draws the cursor OAM.
; =======================================================================================
	ld a,[wDrawCursor]
	or a
	ret z

	; If selecting an object, we don't use the cursor position
	ld a,[wSelectingObject]
	or a
	jr nz,@selectingObject

@notSelectingObject: ; Get Y/X from cursor position
	ld hl,wCursorY
	ldi a,[hl]
	swap a
	ld b,a
	ld a,[hl]
	swap a
	ld c,a
	jr ++

@selectingObject: ; Get Y/X from selecting object position
	ld a,[wObjectListIndex]
	ld hl,wObjectList
	call addAToHL
	ld h,[hl]
	ld l,Object.yh
	ldi a,[hl]
	ld b,a
	inc l
	ld c,[hl]

++
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
	ld e,Object.flicker
	ld a,[de]
	or a
	jr z,+
	ld b,a
	ld a,[wFrameCounter]
	and b
	jr z,@next
+
	ld e,Object.yh
	ld a,[de]
	ld b,a
	ld e,Object.xh
	ld a,[de]
	ld c,a
	call convertPositionForOam

	ld e,Object.oamFlags
	ld a,[de]
	ld hl,classOam
	push de
	call addToOamWithFlags
	ld a,e
	inc a
	sub 8
	pop de
	ld e,Object.oamAddress
	ld [de],a

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


