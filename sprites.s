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
;             c if within the screen
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

	; Check in camera
	ld a,b
	or a
	jr z,@out
	cp 144+16
	jr nc,@out
	ld a,c
	or a
	jr z,@out
	cp 160+8
	jr nc,@out
	ret
@out:
	xor a
	ret

drawCursor:
; =======================================================================================
; Draws the cursor OAM.
; =======================================================================================
	ld a,[wDrawCursor]
	or a
	ret z

	; TODO: have cursor flicker on sprite overload

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
	.db 2
	.db 0 0 0 $00
	.db 0 8 0 $20


calculateNumSpritesInRows:
; =======================================================================================
; Fills wNumObjectsInRows. Used to check whether to do sprite flickering.
; TODO: optimize by only considering visible rows?
; =======================================================================================
	push bc
	push de
	push hl

	ld bc,MAP_HEIGHT
	ld hl,wNumObjectsInRows
	xor a
	call fillMemory

	ld d,FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next

	ld h,d
	ld l,Object.yh
	ld b,[hl]
	ld l,Object.xh
	ld c,[hl]
	call convertPositionForOam
	jr nc,@next

	ld e,Object.tileY
	ld a,[de]
	ld hl,wNumObjectsInRows
	call addAToHL
	ld a,[hl]
	inc [hl]
	ld e,Object.flickerIndex
	ld [de],a
@next
	call getNextObject
	jr c,--

	; Plus cursor
	ld a,[wDrawCursor]
	or a
	jr z,+
	ld a,[wCursorY]
	ld hl,wNumObjectsInRows
	call addAToHL
	inc [hl]
+

	ld b,0
	ld hl,wObjectRowFlickerCounters
--
	ld a,[hl]
	or a
	jr nz,+
	ld de,wNumObjectsInRows
	ld a,b
	call addAToDE
	ld a,[de]
	ld [hl],a
+
	dec [hl]
	inc hl
	inc b
	ld a,b
	cp MAP_HEIGHT
	jr c,--
+
	pop hl
	pop de
	pop bc
	ret

drawObjects:
; =======================================================================================
; Draws all objects in memory at $d000-$de00.
; =======================================================================================
	call calculateNumSpritesInRows

	ld d, FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next

	; Check if this row is overloaded with sprites
	ld e,Object.tileY
	ld a,[de]
	ld b,a
	ld hl,wNumObjectsInRows
	call addAToHL
	ld a,[hl]
	cp 6
	jr c,+
	sub 5
	ld c,a
	ld hl,wObjectRowFlickerCounters
	ld a,b
	call addAToHL
	ld e,Object.flickerIndex
	ld a,[de]
	ld b,a
	ld a,[hl]
	sub b
	cp c
	jr c,@next
+
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
	ld e,Object.yh ; Calculate position
	ld a,[de]
	ld b,a
	ld e,Object.xh
	ld a,[de]
	ld c,a
	call convertPositionForOam

	ld e,Object.class ; Lookup the OAM for this object
	ld a,[de]
	add a
	ld hl,classOamTable
	call addAToHL
	ldi a,[hl]
	ld h,[hl]
	ld l,a

	ld e,Object.moved ; If moved, don't animate (use frame 0 always)
	ld a,[de]
	or a
	jr nz,++
	ld a,[wObjectAnimationFrame] ; Get the frame of animation
	add a
	call addAToHL
++
	ldi a,[hl]
	ld h,[hl]
	ld l,a

	ld e,Object.oamFlags ; Get any modifications to oam flags
	ld a,[de]
	push de
	call addToOamWithFlags ; Draw it

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
	jp c,--
	ret

classOamTable:
	.dw 0
	.dw kingOam
	.dw solderOam
	.dw horseOam
	.dw solderOam

kingOam:
	.dw @frame0
	.dw @frame1

@frame0:
	.db 2
	.db 0 0 $14 0
	.db 0 8 $16 0
@frame1:
	.db 2
	.db 0 0 $18 0
	.db 0 8 $1a 0

solderOam:
	.dw @frame0
	.dw @frame1

@frame0:
	.db 2
	.db 0 0 $04 0
	.db 0 8 $06 0
@frame1:
	.db 2
	.db 0 0 $08 0
	.db 0 8 $0a 0

horseOam:
	.dw @frame0
	.dw @frame1

@frame0:
	.db 2
	.db 0 0 $0c 0
	.db 0 8 $0e 0
@frame1:
	.db 2
	.db 0 0 $10 0
	.db 0 8 $12 0
