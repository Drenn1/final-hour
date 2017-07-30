
runGame:
	ld a,1
	ldh [<hUpdateWindowMap],a
	ld [wDrawCursor],a

	ld de,$d000
	call objectInit
	ld e,Object.tileY
	ld a,1
	ld [de],a
	inc e
	ld [de],a
	call objectAlignPositionToTile

	ld de,$d100
	ld e,Object.side
	ld a,1
	ld [de],a
	ld e,Object.oamFlags
	ld a,$10
	ld [de],a
	ld e,Object.tileX
	ld a,5
	ld [de],a
	call objectAlignPositionToTile
	call objectInit

	ld de,$d200
	ld e,Object.side
	ld a,1
	ld [de],a
	ld e,Object.oamFlags
	ld a,$10
	ld [de],a
	ld e,Object.tileY
	ld a,1
	ld [de],a
	ld e,Object.tileX
	ld a,4
	ld [de],a
	call objectAlignPositionToTile
	call objectInit

mainLoop:
	call waitForVblank

	ld hl,wSelectedObjectMovementCounter
	ld a,[hl]
	or a
	jr z,++

	; Selected object is moving. Input disabled
	dec [hl]
	jr nz,@doneInput

	call finishObjectMovement
	jr mainLoop
++
	call updateInput
@doneInput
	call updateBasics
	jr mainLoop


finishObjectMovement:
; =======================================================================================
; Called after a player unit moves.
; =======================================================================================
	ld a,[wSelectedObject]
	ld h,a

	; Re-enable flickering
	ld l,Object.flicker
	ld [hl],$10

	; Save old tile position
	ld l,Object.tileY
	ld b,[hl]
	inc l
	ld c,[hl]
	push bc

	; Set new tile position
	ld l,Object.tileY
	ld a,[wCursorY]
	ldi [hl],a
	ld a,[wCursorX]
	ld [hl],a

	; Fix up the object's position
	ld d,h
	call objectAlignPositionToTile

	; Clear selected object's speed
	ld h,d
	ld l,Object.speedY
	xor a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a

@openMenu:
	ld de,afterMoveText
	call printText
	jr nc,@resetObjectPosition

	ld a,[wSelectedTextOption]
	or a
	jr z,+
; Wait
	jr @deactivateObject
+
; Attack
	ld a,[wSelectedObject]
	ld d,a
	call objectGetAttackableObjects
	jr z,@noTarget

	call selectObject
	ld a,h
	or a
	jr z,@openMenu ; Re-open menu if nothing selected

	ld [wTargetObject],a
	call doAttack
	jr @deactivateObject

@noTarget:
	ld de,nobodyToAttackText
	ld a,1
	call printText
	jr @openMenu

@deactivateObject:
	call deselectObject
	ld e,Object.moved
	ld a,1
; 	ld [de],a
@ret:
	pop bc
	ret

@resetObjectPosition: ; Exited menu instead of selecting something
	pop bc
	call deselectObject
	ld h,d
	ld l,Object.tileY
	ld [hl],b
	inc l
	ld [hl],c

	ld d,h
	jp objectAlignPositionToTile


selectObject:
; =======================================================================================
; Select an object in wObjectList.
; Returns: h = selected object (or 0 if cancelled)
; =======================================================================================
	xor a
	ld [wObjectListIndex],a
	ld a,1
	ld [wSelectingObject],a

@waitForSelection:
	call updateBasics
	call waitForVblank

	call readInput
	ldh a,[<hButtonsPressedAutofire]
	ld b,a

; Check directional input
	ld hl,wObjectListIndex
	ld a,[wObjectListCount]
	ld c,a
	dec c

	bit BTN_BIT_UP,b ; Check to decrement selection
	jr nz,+
	bit BTN_BIT_LEFT,b
	jr z,++
+
	ld a,[hl]
	or a
	jr z,@loopFromBottom
	dec [hl]
	jr ++
@loopFromBottom:
	ld [hl],c

++
	bit BTN_BIT_DOWN,b ; Check to increment selection
	jr nz,+
	bit BTN_BIT_RIGHT,b
	jr z,++
+
	ld a,[hl]
	cp c
	jr nc,@loopFromTop
	inc [hl]
	jr ++
@loopFromTop:
	ld [hl],0
++

; Check A/B buttons
	ldh a,[<hButtonsJustPressed]
	ld b,a

	bit BTN_BIT_A,b
	jr nz,@gotSelection

	bit BTN_BIT_B,b
	jr nz,@cancelSelection

; Print stats
	ld a,[wSelectedObject]
	ld d,a
	ld a,[wObjectListIndex]
	ld hl,wObjectList
	call addAToHL
	ld h,[hl]
	call objectPrintBattleStats

	jr @waitForSelection

@gotSelection:
	xor a
	ld [wSelectingObject],a

	ld a,[wObjectListIndex]
	ld hl,wObjectList
	call addAToHL
	ld h,[hl]
	ret

@cancelSelection:
	xor a
	ld [wSelectingObject],a
	ld h,a
	ret


doAttack:
; =======================================================================================
; Performs an attack between wSelectedObject and wTargetObject.
; =======================================================================================
	xor a
	ld [wDrawCursor],a ; Disable cursor

	ld a,[wSelectedObject]
	ld d,a
	ld a,[wTargetObject]
	ld b,a
	; d = attacker, b = defender

	ld e,Object.flicker
	xor a
	ld [de],a

	; Attacker attacks
	call animateAttack
	call @applyDamage

	ld c,Object.enabled ; Return if enemy died
	ld a,[bc]
	or a
	jr z,@end

	; Defender attacks
	ld e,d
	ld d,b
	ld b,e
	call animateAttack
	call @applyDamage

@end
	ld a,1
	ld [wDrawCursor],a
	ret

@applyDamage:
; =======================================================================================
; Parameters: d = attacker, b = target
; =======================================================================================
	call objectGetAttack
	ld h,d
	ld d,b
	call objectTakeDamage
	ld d,h
	ret nz

	ld h,b
	; d = attacker, h = target
; Dead
	ld l,Object.oamAddress
	ld a,[hl]
	inc a
	ldh [<hOamFlicker],a

	ld l,Object.yh
	ld a,[hl]
	ld b,a
	call convertPositionForOam
	ld a,b
	sub $10
	ldh [<hOamFlickerLine],a
	ld a,1
	ldh [<hOamFlickerSize],a

	push de
	push hl ; Save object indices

; Do the death animation
@deathLoop1:
	ld b,3
-
	push bc
	call updateBasics
	call waitForVblank
	pop bc
	dec b
	jr nz,-


	ldh a,[<hOamFlickerSize]
	inc a
	inc a
	ldh [<hOamFlickerSize],a

	cp $e
	jr c,@deathLoop1


	ld a,$e
	ldh [<hOamFlickerSize],a

@deathLoop2:
	ld b,3
-
	push bc
	call updateBasics
	call waitForVblank
	pop bc
	dec b
	jr nz,-


	ldh a,[<hOamFlickerSize]
	dec a
	dec a
	ldh [<hOamFlickerSize],a

	or a
	jr nz,@deathLoop2

	call updateBasics
	call waitForVblank

	pop bc
	pop de
	ld h,d
	ld d,b
	call objectDelete
	ld d,h

	xor a
	ldh [<hOamFlicker],a

	call updateBasics
	call waitForVblank
	ret


animateAttack:
; =======================================================================================
; Animates an attack.
; Parameters: d = attacker, b = target
; =======================================================================================
	xor a
	ld [wAttackAnimationState],a
	ld a,20
	ld [wAttackAnimationCounter],a
@loop
	push bc
	push de
	call updateBasics
	call waitForVblank
	pop de
	pop bc

	ld a,[wAttackAnimationState]
	rst_jumpTable
	.dw @waiting
	.dw @moveForward
	.dw @moveBack

@waiting:
	ld hl,wAttackAnimationCounter
	dec [hl]
	jr nz,@loop

	ld [hl],5
	dec hl
	inc [hl] ; inc state
	ld h,b
	ld bc,$200
	call @setRelativeSpeed
	ld b,h
	jr @loop

@moveForward:
	ld hl,wAttackAnimationCounter
	dec [hl]
	jr nz,@loop

	ld [hl],10
	dec hl
	inc [hl] ; inc state
	ld h,b
	ld bc,-$100
	call @setRelativeSpeed
	ld b,h
	jr @loop

@moveBack:
	ld hl,wAttackAnimationCounter
	dec [hl]
	jr nz,@loop

	xor a
	ld h,d
	ld l,Object.speedY
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ret

@setRelativeSpeed:
; =======================================================================================
; Sets speed for object 'd' to move toward object 'h'.
; Parameters: bc = speed
; =======================================================================================
	ld e,Object.tileY
	ld l,e
	ld a,[de]
	cp [hl]
	jr z,@horizontal
@vertical
	ld e,Object.speedY
	jr c,@down
@up
	call @negateBC
@down
	jr @setSpeed

@horizontal
	inc e
	ld l,e
	ld a,[de]
	cp [hl]
	ld e,Object.speedX
	jr c,@right
@left
	call @negateBC
@right

@setSpeed
	ld a,c
	ld [de],a
	inc e
	ld a,b
	ld [de],a
	ret

@negateBC:
	dec bc
	ld a,b
	cpl
	ld b,a
	ld a,c
	cpl
	ld c,a
	ret
	

updateBasics:
; =======================================================================================
; This is part of the main loop, but sometimes code calls this outside of the main loop
; when they're holding it up somehow.
; =======================================================================================
	ld hl,wFrameCounter
	inc [hl]

	call updateObjects

	; Update camera
	ld hl,wCameraY
	call @updateCameraComponent
	ld hl,wCameraX
	call @updateCameraComponent

	; Update sprites
	xor a
	ldh [<hNumOamEntries],a
	call drawCursor
	call drawObjects
	call clearRemainingOam

	ret

@updateCameraComponent:
	ldi a,[hl]
	inc hl
	ld b,[hl]
	dec hl
	dec hl
	cp b
	ret z
	jr nc,+
	inc [hl]
	inc [hl]
	ret
+
	dec [hl]
	dec [hl]
	ret

updateInput:
	call readInput

	call @checkCursorInput

	ld a,[wSelectedObject]
	or a
	jr nz,+
	call @checkInputNothingSelected
	jr ++
+
	call @checkInputSomethingSelected
++
	ret

@checkCursorInput:
; Check cursor movement
	ldh a,[<hButtonsPressedAutofire]
	ld b,a

	bit BTN_BIT_UP,b
	jr z,+
	ld hl,wCursorY
	ld a,[hl]
	or a
	jr z,+
	dec [hl]
	call @@verifyNewCursorPos
	jr nc,+
	call checkMoveCameraUp
	call updateLastCursorPos
+
	bit BTN_BIT_DOWN,b
	jr z,+
	ld hl,wCursorY
	ld a,[hl]
	cp MAP_HEIGHT-1
	jr nc,+
	inc [hl]
	call @@verifyNewCursorPos
	jr nc,+
	call checkMoveCameraDown
	call updateLastCursorPos
+
	bit BTN_BIT_LEFT,b
	jr z,+
	ld hl,wCursorX
	ld a,[hl]
	or a
	jr z,+
	dec [hl]
	call @@verifyNewCursorPos
	jr nc,+
	call checkMoveCameraLeft
	call updateLastCursorPos
+
	bit BTN_BIT_RIGHT,b
	jr z,+
	ld hl,wCursorX
	ld a,[hl]
	cp MAP_WIDTH-1
	jr nc,+
	inc [hl]
	call @@verifyNewCursorPos
	jr nc,+
	call checkMoveCameraRight
	call updateLastCursorPos
+

	ld hl,wCursorY
	ld b,[hl]
	inc hl
	ld c,[hl]
	call findObjectAtPosition
	ret nz
	
	ld d,h
	call objectPrintStats
	ret

@@verifyNewCursorPos:
; =======================================================================================
; Reverts wCursorY/X changes if new position isn't reachable.
; Returns: cflag set if position is reachable.
; =======================================================================================
	push bc
	ld a,[wSelectedObject]
	or a
	jr z,@@@ok

	ld d,a
	ld a,[wCursorY]
	ld b,a
	ld a,[wCursorX]
	ld c,a

	call isTraversibleTilesBitSet
	jr z,@@@notOK
	jr @@@ok

@@@notOK:
	ld a,[wLastCursorY]
	ld [wCursorY],a
	ld a,[wLastCursorX]
	ld [wCursorX],a
	pop bc
	xor a
	ret
@@@ok:
	pop bc
	scf
	ret

@checkInputNothingSelected:
; =======================================================================================
; Handles input with cursor on the map, nothing selected.
; =======================================================================================
	; Check if selected an object
	ldh a,[<hButtonsJustPressed]
	ld b,a

	bit BTN_BIT_A,b
	jr z,+
	call trySelectObject
+
	ret

@checkInputSomethingSelected:
; =======================================================================================
; Handles input while a unit is selected.
; =======================================================================================
	ldh a,[<hButtonsJustPressed]
	ld b,a

	; Check B button to deselect
	bit BTN_BIT_B,b
	jr z,+
	call deselectObject
	ret
+
	; Check A button to move to position
	bit BTN_BIT_A,b
	jr z,++

	; Calculate speed needed to move to the position
	ld a,[wSelectedObject]
	ld h,a

	ld e,Object.speedY
	ld l,Object.tileY
	ld a,[wCursorY]
	call @@calcSpeedComponent

	ld e,Object.speedX
	ld l,Object.tileX
	ld a,[wCursorX]
	call @@calcSpeedComponent

	ld l,Object.speedY ; Check if speed is 0
	ldi a,[hl]
	or [hl]
	inc l
	or [hl]
	inc l
	or [hl]
	ld a,1
	jr z,+
	ld a,MOVEMENT_FRAMES
+
	ld [wSelectedObjectMovementCounter],a

	; Disable flickering while moving
	ld l,Object.flicker
	ld [hl],0

++
	ret

@@calcSpeedComponent:
; =======================================================================================
; Calculates the speed necessary to reach the target tile in the movement animation.
; =======================================================================================
	sub [hl]
	sla a
	sla a
	sla a
	sla a
	ld b,a
	ld c,0

.rept 5 ; bc /= 32
	sra b
	rr c
.endr
	ld l,e ; speedY or speedX
	ld [hl],c
	inc l
	ld [hl],b
	ret

updateLastCursorPos:
; =======================================================================================
; Updates wLastCursorY/X.
; =======================================================================================
	ld a,[wCursorY]
	ld [wLastCursorY],a
	ld a,[wCursorX]
	ld [wLastCursorX],a
	ret


checkMoveCameraUp:
; Updates camera position if cursor went too far off.
	ld a,[wCursorY]
	swap a
	ld hl,wCameraDestY
	sub [hl]
	cp 1*16
	ret nc
	ld a,[wCursorY]
	sub 1
	jr nc,+
	xor a
+
	swap a
	ld [wCameraDestY],a
	ret

checkMoveCameraDown:
; Updates camera position if cursor went too far off.
	ld a,[wCursorY]
	swap a
	ld hl,wCameraDestY
	sub [hl]
	cp (SCREEN_HEIGHT-2)*16
	ret c

	ld a,[wCursorY]
	sub SCREEN_HEIGHT-2
	jr nc,+ ; Check upper boundary
	xor a
+
	cp MAP_HEIGHT-SCREEN_HEIGHT ; Check lower boundary
	jr c,+
	ld a,MAP_HEIGHT-SCREEN_HEIGHT
+
	swap a
	ld [wCameraDestY],a
	ret

checkMoveCameraLeft:
; Updates camera position if cursor went too far off.
	ld a,[wCursorX]
	swap a
	ld hl,wCameraDestX
	sub [hl]
	cp 1*16
	ret nc
	ld a,[wCursorX]
	sub 1
	jr nc,+
	xor a
+
	swap a
	ld [wCameraDestX],a
	ret
	
checkMoveCameraRight:
; Updates camera position if cursor went too far off.
	ld a,[wCursorX]
	swap a
	ld hl,wCameraDestX
	sub [hl]
	cp (SCREEN_WIDTH-2)*16
	ret c

	ld a,[wCursorX]
	sub SCREEN_WIDTH-2
	jr nc,+ ; Check upper boundary
	xor a
+
	cp MAP_WIDTH-SCREEN_WIDTH ; Check lower boundary
	jr c,+
	ld a,MAP_WIDTH-SCREEN_WIDTH
+
	swap a
	ld [wCameraDestX],a
	ret
