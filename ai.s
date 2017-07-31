
enemyPhase:
	call resetAllObjectMovement
	xor a
	ld [wDrawCursor],a
	ld a,1
	ld [wPhase],a

	ld de,enemyPhaseText
	ld a,1
	call printText

	ld a,FIRST_OBJECT_INDEX
	ld [wSelectedObject],a

---
	ld a,[wSelectedObject]
	cp LAST_OBJECT_INDEX+1
	jr nc,@end

	ld d,a
	ld e,Object.side
	ld a,[de]
	or a
	jr z,@nextEnemy

	call objectCenterCamera
	call waitForCamera

	call aiGetTarget
	call objectCalculateMovementSpeed
	jr z,@doneMovement ; Skip movement animation if speed is 0

	; Set new tile position
	ld h,d
	ld l,Object.tileY
	ld [hl],b
	inc l
	ld [hl],c

	call objectCenterCamera

	ld b,MOVEMENT_FRAMES

	; Move the object
	push de
--
	push bc
	call updateBasics
	call waitForVblank
	pop bc
	dec b
	jr nz,--
	pop de
@doneMovement

	; Zero speed, align position
	ld h,d
	ld l,Object.speedY
	xor a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a
	call objectAlignPositionToTile

	ld e,Object.moved ; Set moved to stop animation
	ld a,1
	ld [de],a

	; Attack if there's something there
	call objectGetAttackableObjects
	ld a,[wObjectListCount]
	or a
	jr z,@doneAttack
	call aiChooseObjectToAttack
	call doAttack
@doneAttack
	

@nextEnemy
	ld hl,wSelectedObject
	inc [hl]
	jr ---

@end:
	xor a
	ld [wSelectedObject],a
	jp playerPhase


aiGetTarget:
; =======================================================================================
; Parameters: d = object to move
; Returns:    bc = position to move to
; =======================================================================================
	push hl

	xor a
	ld [wBestTarget],a

	; Set default target
	ld h,d
	ld l,Object.tileY
	ld b,[hl]
	inc l
	ld c,[hl]
	ld hl,wBestTargetPosition
	ld [hl],b
	inc hl
	ld [hl],c

	; Save original position
	push bc

	; Get which squares are accessible
	call objectGetMovement
	call bfs

	; Iterate through all possible positions
	ld bc,0
--
	call isTraversibleTilesBitSet ; Check we can reach here
	jr z,@nextPosition

	; Check nothing's there already
	call findObjectAtPosition
	jr z,@nextPosition

	; Set tileY/X for checking for function call below (objectGetAttackableObjects)
	ld h,d
	ld l,Object.tileY
	ld [hl],b
	inc l
	ld [hl],c

	; See if there's a good target
	call objectGetAttackableObjects
	jr z,@nextPosition ; TODO: prioritize by proximity?

	call aiChooseObjectToAttack
	ld a,[wTargetObject]
	ld h,a
	
	ld a,[wBestTarget] ; Set target if none exists
	or a
	jr z,@setTarget

	ld a,[wBestTargetHP] ; Set target if health is lower
	ld l,Object.hp
	cp [hl]
	jr c,@nextPosition

@setTarget:
	ld a,h
	ld [wBestTarget],a
	ld l,Object.hp
	ld a,[hl]
	ld [wBestTargetHP],a

	ld hl,wBestTargetPosition
	ld [hl],b
	inc hl
	ld [hl],c

@nextPosition:
	inc c
	ld a,c
	cp MAP_WIDTH
	jr c,--
	ld c,0
	inc b
	ld a,b
	cp MAP_HEIGHT
	jr c,--

	; Restore object's tileY/X
	pop bc
	ld h,d
	ld l,Object.tileY
	ld [hl],b
	inc l
	ld [hl],c

	; Return chosen position
	ld hl,wBestTargetPosition
	ld b,[hl]
	inc hl
	ld c,[hl]

	pop hl
	ret

aiChooseObjectToAttack:
; =======================================================================================
; Selects the object with the lowest health.
; Assumes wObjectList is non-empty.
; Returns: [wTargetObject] = object to attack
; =======================================================================================
	push bc
	push de
	push hl

	ld a,[wObjectListCount]
	ld b,a
	ld c,$ff ; Lowest "health" value so far
	ld hl,wObjectList
--
	ldi a,[hl]
	ld d,a
	ld e,Object.hp
	ld a,[de]
	cp c
	jr nc,@next

	ld c,a
	ld a,d
	ldh [<hTmp1],a
@next
	dec b
	jr nz,--

	ldh a,[<hTmp1]
	ld [wTargetObject],a

	pop hl
	pop de
	pop bc
	ret
