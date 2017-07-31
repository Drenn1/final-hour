trySelectObject:
; =======================================================================================
; Called when A is pressed.
; Returns: zflag set if object was selected; h = selected object
; =======================================================================================
	push bc
	push hl
	ld hl,wCursorY
	ld b,[hl]
	inc hl
	ld c,[hl]
	call findObjectAtPosition
	jr nz,@fail

	; Object is on tile. Check if moved already
	ld l,Object.moved
	ld a,[hl]
	or a
	jr nz,@fail

	; All good, select this object
	ld d,h
	call objectSetSelected
	xor a
	pop hl
	pop bc
	ret

@fail:
	pop hl
	pop bc
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
	push bc
	push hl

	ld hl,wTextSubstitutions
	ld a,Object.name ; Print name
	ld [hl],a
	inc hl
	ld a,d
	ld [hl],a
	inc hl

	call objectGetClassName ; Print class
	ld [hl],c
	inc hl
	ld [hl],b
	inc hl

	ld e,Object.hp ; Print HP, maxHP
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

	call objectHasMorale
	push de
	ld de,noMoraleStatText
	jr nc,+
	ld de,statText
+
	xor a
	call printText
	pop de

	pop hl
	pop bc
	ret

objectHasMorale:
; =======================================================================================
; Returns: cflag set if object has morale
; =======================================================================================
	ld e,Object.side
	ld a,[de]
	or a
	ret nz ; Enemies don't have it
	ld e,Object.class
	ld a,[de]
	cp C_KING
	ret z ; King doesn't have it
	scf
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

	push bc
	call objectGetAttack
	call hexToBcd
	ld a,c
	ldi [hl],a
	inc hl

	pop bc
	push de
	ld d,b
	call objectGetAttack
	call hexToBcd
	ld a,c
	pop de
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

getNextObject:
; =======================================================================================
; Parameters: d = current object
; Returns:    d = next object
;             cflag = unset if there are no more objects
; =======================================================================================
	inc d
	ld a,d
	cp LAST_OBJECT_INDEX+1
	ret

objectCenterCamera:
	push hl

	ld hl,wCursorY
	ld b,[hl]
	inc hl
	ld c,[hl]
	push bc

	ld e,Object.tileX
	ld a,[de]
	ldd [hl],a
	dec e
	ld a,[de]
	ld [hl],a

	call checkMoveCameraUp
	call checkMoveCameraRight
	call checkMoveCameraDown
	call checkMoveCameraLeft

	pop bc
; 	ld hl,wCursorY
; 	ld [hl],b
; 	inc hl
; 	ld [hl],c

	pop hl
	ret

resetAllObjectMovement:
; =======================================================================================
; Allow all objects to move again.
; =======================================================================================
	ld d,FIRST_OBJECT_INDEX
	ld e,Object.moved
--
	xor a
	ld [de],a
	call getNextObject
	jr c,--
	ret

checkAllPlayerObjectsMoved:
; =======================================================================================
; Returns: nz if all player objects moved
; =======================================================================================
	ld d,FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next
	ld e,Object.side
	ld a,[de]
	or a
	jr nz,@next
	ld e,Object.moved
	ld a,[de]
	or a
	ret z
@next:
	call getNextObject
	jr c,--
	or d ; nz
	ret

checkAllEnemiesDead:
; =======================================================================================
; Returns: z if all enemies dead
; =======================================================================================
	push de

	ld d,FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next
	ld e,Object.side
	ld a,[de]
	or a
	jr nz,@notDead
@next
	call getNextObject
	jr c,--
	xor a
	pop de
	ret
@notDead
	or d
	pop de
	ret

objectInit:
; =======================================================================================
; Initialize an object
; =======================================================================================
	push bc
	push hl

	ld a,1
	ld e,Object.enabled
	ld [de],a

	; Set default name (enemies only)
	ld e,Object.side
	ld a,[de]
	or a
	jr z,++
	ld hl,@defaultEnemyName
	ld e,Object.name
	ld bc,8
	call copyMemory
++

	; Set palette
	ld e,Object.side
	ld a,[de]
	or a
	ld a,0
	jr z,+
	ld a,$10
+
	ld e,Object.oamFlags
	ld [de],a

	; Align on tile (assume caller set this already)
	call objectAlignPositionToTile

	pop hl
	pop bc
	ret

@defaultAllyName:
	.asc "ALLY" 0
@defaultEnemyName:
	.asc "ENEMY" 0
	
objectAddMorale:
; =======================================================================================
; Parameters: a = value to add to morale
; =======================================================================================
	push bc
	push hl

	ld b,a
	call objectHasMorale
	jr nc,@ret

	ld hl,wTextSubstitutions
	ld [hl],b

	push de
	ld de,moraleIncText
	call printText
	pop de

	ld e,Object.morale
	ld a,[de]
	add b
	ld [de],a

@ret
	pop hl
	pop bc
	ret

objectSubMorale:
; =======================================================================================
; Parameters: a = value to remove from morale
; =======================================================================================
	push bc
	push hl

	ld b,a
	call objectHasMorale
	jr nc,@ret

	ld hl,wTextSubstitutions
	ld [hl],b

	push de
	ld de,moraleDecText
	call printText
	pop de

	ld e,Object.morale
	ld a,[de]
	sub b
	ld [de],a

@ret
	pop hl
	pop bc
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

getFreeObjectSlot
; =======================================================================================
; Returns: d = object slot
;          cflag = set on failure
; =======================================================================================
	ld d,FIRST_OBJECT_INDEX
	ld e,Object.enabled
@next
	ld a,[de]
	or a
	ret z
	call getNextObject
	jr c,@next
	scf
	ret

objectAlignPositionToTile:
; =======================================================================================
; Sets an object's x and y positions to match the tileY and tileX variables.
; =======================================================================================
	push bc
	push hl

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

	pop hl
	pop bc
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
