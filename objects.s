trySelectObject:
; =======================================================================================
; Called when A is pressed.
; Returns: zflag set if object was selected; h = selected object
; =======================================================================================
	ld hl,wCursorY
	ld b,[hl]
	inc hl
	ld c,[hl]
	call findObjectAtPosition
	ret nz

	; Object is on tile. Check if moved already
	ld l,Object.moved
	ld a,[hl]
	or a
	jr nz,@fail

	; All good, select this object
	ld d,h
	call objectSetSelected
	xor a
	ret

@fail:
	or 1
	ret
	

deselectObject:
; =======================================================================================
; Returns: d = formerly selected object
; =======================================================================================
	ld a,[wSelectedObject]
	ld d,a
	xor a
	ld [wSelectedObject],a
	ld e,Object.flicker
	ld [de],a
	ret

findObjectAtPosition:
; =======================================================================================
; Parameters: bc = tile position to check
; Returns:    h = object at that position (or 0 if none)
;             zflag set if match found
; =======================================================================================
	ld h, FIRST_OBJECT_INDEX
--
	ld l,Object.enabled
	ld a,[hl]
	or a
	jr z,@next
	ld l,Object.tileY
	ld a,[hl]
	cp b
	jr nz,@next
	inc l
	ld a,[hl]
	cp c
	ret z
@next:
	inc h
	ld a,h
	cp LAST_OBJECT_INDEX+1
	jr c,--
	or h
	ld h,0
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

objectPrintStats:
; =======================================================================================
; Print HP and Morale to the bottom bar.
; =======================================================================================
	ld hl,wTextSubstitutions
	ld a,Object.name; Get name for text substitution
	ld [hl],a
	inc hl
	ld a,d
	ld [hl],a
	inc hl

	ld e,Object.hp ; Get hp, maxHP for text substitution
	ld a,[de]
	inc de
	ldi [hl],a
	inc hl
	ld a,[de]
	ldi [hl],a
	inc hl

	ld e,Object.morale
	ld a,[de]
	call hexToBcd
	ld [hl],a
	inc hl
	inc hl

	push de
	ld de,statText
	xor a
	call printText
	pop de
	ret

objectPrintBattleStats:
; =======================================================================================
; Prints stats for two objects 'd' and 'h' about to fight each other.
; =======================================================================================
	push hl
	push de

	ld b,h
	ld hl,wTextSubstitutions
	ld a,Object.name ; Get names for text substitution
	ldi [hl],a
	ld a,d
	ldi [hl],a
	ld a,Object.name
	ldi [hl],a
	ld a,b
	ldi [hl],a

	ld e,Object.hp ; Get attacker hp values
	ld a,[de]
	ldi [hl],a
	inc hl
	inc de
	ld a,[de]
	ldi [hl],a
	inc hl
	inc de

	ld c,Object.hp ; Get target hp values
	ld a,[bc]
	ldi [hl],a
	inc hl
	inc bc
	ld a,[bc]
	ldi [hl],a
	inc hl

	call objectGetAttack
	call hexToBcd
	ld a,c
	ldi [hl],a
	inc hl
	ldi [hl],a
	inc hl

	ld de,battleStatText
	xor a
	call printText

	pop de
	pop hl
	ret

objectGetAttackableObjects:
; =======================================================================================
; Fills wObjectList with all objects that this one can attack.
; Currently this just means they're adjacent.
; Returns: zflag set if there are no attackable objects.
; =======================================================================================
	push bc
	ld hl,wObjectList
	
	ldbc 0, 1
	call @checkOffset
	ldbc 0, -1
	call @checkOffset
	ldbc 1, 0
	call @checkOffset
	ldbc -1, 0
	call @checkOffset

	ld [hl],0 ; Terminate list with null

	ld bc,(-wObjectList)&$ffff ; Calculate number of objects added
	add hl,bc
	ld a,l
	ld [wObjectListCount],a
	or a

	pop bc
	ret

@checkOffset:
	ld e,Object.tileY ; Get Y/X position to check
	ld a,[de]
	add b
	ld b,a
	inc e
	ld a,[de]
	add c
	ld c,a

	push hl
	call findObjectAtPosition
	ld a,h
	or a
	jr z,@ret

	ld e,Object.side
	ld l,e
	ld a,[de]
	cp [hl]
	jr z,@ret

	ld a,h
	pop hl
	ldi [hl],a ; Add this object
	ret

@ret:
	pop hl
	ret

objectInit:
; =======================================================================================
; Initialize an object
; =======================================================================================
	ld a,1
	ld e,Object.enabled
	ld [de],a

	; Set stats
	ld a,$20
	ld e,Object.hp
	ld [de],a
	inc e
	ld [de],a ; maxHP

	; Set default name
	ld e,Object.side
	ld a,[de]
	or a
	ld hl,@defaultAllyName
	jr z,+
	ld hl,@defaultEnemyName
+
	ld e,Object.name
	ld bc,6
	call copyMemory
	ret

@defaultAllyName:
	.asc "ALLY" 0
@defaultEnemyName:
	.asc "ENEMY" 0
	
objectGetMovement:
	ld a,4
	ret

objectGetAttack:
	ld a,10
	ret

objectTakeDamage:
; =======================================================================================
; Parameters: a = damage to take
; Returns:    zflag set if health is 0 or below
; =======================================================================================
	push bc
	ld b,a
	ld e,Object.hp
	ld a,[de]
	sub b
	daa
	ld [de],a
	pop bc

	or a
	ret z
	cp $80
	jr nc,@dead
	or 1
	ret
@dead:
	xor a
	ret

objectDelete:
; =======================================================================================
; Delete self.
; =======================================================================================
	ld e,$00
-
 	xor a
 	ld [de],a
	inc e
	ld a,e
	cp $80
	jr c,-
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

	; Flicker while selected (every 16 frames)
	ld e,Object.flicker
	ld a,$10
	ld [de],a

	; Fill wTraversibleTiles
	ld e,Object.tileY
	ld a,[de]
	ld b,a
	inc e
	ld a,[de]
	ld c,a
	call objectGetMovement
	call bfs

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
