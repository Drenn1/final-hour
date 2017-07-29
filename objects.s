trySelectObject:
; =======================================================================================
; Called when A is pressed.
; Returns: zflag set if object was selected; h = selected object
; =======================================================================================
	ld h, FIRST_OBJECT_INDEX
--
	ld l,Object.enabled
	ld a,[hl]
	or a
	jr z,@next

	; Compare Y/X
	ld l,Object.tileY
	ld a,[wCursorY]
	cp [hl]
	jr nz,@next
	inc l
	ld a,[wCursorX]
	cp [hl]
	jr nz,@next

	; Object is on tile
	ld d,h
	jr objectSetSelected
@next
	inc h
	ld a,h
	cp LAST_OBJECT_INDEX+1
	jr c,--
	or h
	ret

updateObjects:
; =======================================================================================
; Called each frame.
; =======================================================================================
	ld d, FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	call nz,@objectUpdate
	
	inc d
	ld a,d
	cp LAST_OBJECT_INDEX+1
	jr c,--
	ret

@objectUpdate:
; =======================================================================================
; Update object 'd'.
; =======================================================================================
	ld h,d
	ld e,Object.speedY
	ld l,Object.y
	call @updateSpeedComponent
	ld e,Object.speedX
	ld l,Object.x

@updateSpeedComponent:
	ld a,[de]
	add [hl]
	ldi [hl],a
	inc e
	ld a,[de]
	ld b,a
	ld a,0
	adc [hl]
	add b
	ld [hl],a
	ret
	
objectGetMovement:
	ld a,4
	ret


objectAlignPositionToTile:
; =======================================================================================
; Sets an object's x and y positions to match the tileY and tileX variables.
; =======================================================================================
	ld h,d
	ld l,Object.tileY
	ldi a,[hl]
	swap a
	ld b,a
	ld a,[hl]
	swap a
	ld l,Object.xh
	ld [hld],a
	ld [hl],0
	dec l
	ld [hl],b
	dec l
	ld [hl],0
	ret

objectSetSelected:
; =======================================================================================
; Sets object 'd' as the selected object.
; =======================================================================================
	ld a,d
	ld [wSelectedObject],a
	ret

objectCheckCanReachTile
; =======================================================================================
; Parameters: bc = Y/X of tile
; Returns:    cflag set if reachable
; =======================================================================================
	; Check movement range
	call objectGetMovement
	ld h,a

	ld e,Object.tileY
	ld a,[de]
	sub b
	jr nc,+
	cpl
	inc a
+
	ld b,a

	ld e,Object.tileX
	ld a,[de]
	sub c
	jr nc,+
	cpl
	inc a
+
	add b
	cp h
	jr nz,+
	scf
+
	ret
