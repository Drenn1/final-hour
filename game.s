
runGame:
	ld a,1
	ldh [<hUpdateWindowMap],a

	call loadParty

	; Load map
	ld a,0
	jp loadMap


playerPhase:
	ld d,$d0
	call objectCenterCamera
	call resetAllObjectMovement

	call checkAllEnemiesDead
	jr nz,+
	ld a,[wCurrentMap] ; Load next map
	inc a
	jp loadMap
+
	ld de,playerPhaseText
	ld a,1
	call printText

	ld a,1
	ld [wDrawCursor],a
	xor a
	ld [wPhase],a

playerPhaseLoop:
	call updateBasics
	call waitForVblank

	ld hl,wSelectedObjectMovementCounter
	ld a,[hl]
	or a
	jr z,@updateInput

	; Selected object is moving. Input disabled
	dec [hl]
	jr nz,playerPhaseLoop

	; Object finished moving, now open menu, etc
	call finishObjectMovement

	call checkAllEnemiesDead ; Check to load the next map
	jr nz,+

	ld a,[wCurrentMap]
	inc a
	jp loadMap
+
	call checkAllPlayerObjectsMoved ; Check if enemy phase is next
	jp nz,enemyPhase
	jr playerPhaseLoop

@updateInput
	call checkAllPlayerObjectsMoved ; Check if enemy phase is next
	jp nz,enemyPhase

	call updateInput
	jr playerPhaseLoop


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
	ld [de],a
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


waitForCamera:
	push de
	push hl
	ld hl,wCameraY
	ld de,wCameraDestY
--
	call updateBasics
	call waitForVblank
	ld a,[de]
	cp [hl]
	jr nz,--
	inc de
	ld a,[de]
	inc hl
	cp [hl]
	dec de
	dec hl
	jr nz,--

	pop hl
	pop de
	ret

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
	jr z,@killed

	; Defender attacks
	ld e,d
	ld d,b
	ld b,e
	call animateAttack
	call @applyDamage

	ld c,Object.enabled
	ld a,[bc]
	or a
	jr z,@killed

	; Both survived. Player object should lose morale
	ld e,Object.side
	ld a,[de]
	or a
	jr z,+
	ld d,b
+
	ld a,1
	call objectSubMorale

@ret
	; Restore cursor if in player phase
	ld a,[wPhase]
	or a
	ret nz
	ld a,1
	ld [wDrawCursor],a
	ret

@killed:
	; If the king was killed, game over
	push de
	ldde FIRST_OBJECT_INDEX, Object.enabled
	ld a,[de]
	or a
	pop de
	jp z,gameOver
	ld a,1
	call objectAddMorale ; Add morale to killer
	jr @ret


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

	call waitForVblank

	xor a
	ldh [<hOamFlicker],a

	pop bc
	pop de
	push bc
	push de
	ld h,d
	ld d,b

	; If killee was in squad (and not the king), dec squad morale
	ld e,Object.side
	ld a,[de]
	or a
	jr nz,+
	ld e,Object.class
	ld a,[de]
	cp C_KING
	jr z,+

	push hl ; Copy name into temporary buffer (since he's being delete)
	push de
	ld l,Object.name
	ld h,d
	ld de,wNameBuffer
	ld bc,8
	call copyMemory

	pop de
	call objectDelete

	ld hl,wTextSubstitutions ; Notify player of death
	ld [hl],<wNameBuffer
	inc hl
	ld [hl],>wNameBuffer
	push de
	ld de,objectDeadText
	ld a,1
	call printText
	pop de

	call decSquadMorale
	pop hl
	jr ++
+
	call objectDelete
++
	pop de
	pop bc

	call updateBasics
	call waitForVblank
	ret

objectDeadText:
	.db 16
	.asc "@ died." 0



gameOver:
; =======================================================================================
; Game over, man
; =======================================================================================
	call fadeOut
	call disableLcd
	call clearBackground
	call clearWindowMapInVram
	call deleteAllObjects
	ld a,%11100100
	ldh [R_BGP],a
	call enableLcd
	call waitForVblank ; Re-synchronize before printing text
	ld de,gameOverText
	ld a,1
	call printText
	jp begin

gameOverText:
	.db $58
	.asc " The king is dead." 1
	.asc "Long live the king!" 1 1
	.asc "     Game over" 0

wonGame:
; =======================================================================================
; Yay
; =======================================================================================
	call fadeOut
	call disableLcd
	call clearBackground
	call clearWindowMapInVram
	call deleteAllObjects
	ld a,%11100100
	ldh [R_BGP],a
	call enableLcd
	call waitForVblank ; Re-synchronize before printing text
	ld de,victoryText
	ld a,1
	call printText
	jp begin
	ret

victoryText:
	.db $58
	.asc "Mathias has escaped" 1
	.asc "from the usurpers." 1
	.asc "For now, the battle" 1
	.asc "      is won." 0

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
	push bc
	push de
	push hl

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

	; Update sprite animation counter
	ld hl,wObjectAnimationCounter
	ld a,[hl]
	or a
	jr nz,++
	; Next frame
	ld [hl],25
	dec hl ; wObjectAnimationFrame
	ld a,1
	xor [hl]
	ld [hl],a
	inc hl
++
	dec [hl]


	pop hl
	pop de
	pop bc
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
	ldh a,[<hButtonsJustPressed]
	ld b,a

	bit BTN_BIT_A,b ; Check if selected an object
	jr z,+
	call trySelectObject
+
	bit BTN_BIT_SELECT,b ; Center on player character
	jr z,+
	ld d,$d0
	call objectCenterCamera
+
	bit BTN_BIT_START,b
	jr z,+
.ifdef DEBUG
	call killAllEnemies
.else
	ld de,endTurnText
	ld a,1
	call printText
	or a
	jr z,+
	call setAllObjectsMoved
.endif
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
	jr z,@ret

	ld a,[wSelectedObject]
	ld d,a
	ld a,[wCursorY] ; bc = cursor position
	ld b,a
	ld a,[wCursorX]
	ld c,a

	; Don't allow movement to there if an object is already present
	call findObjectAtPosition
	jr nz,@moveUnit
	ld a,h
	cp d ; It's fine if the object is itself
	jr nz,@ret

@moveUnit
	call objectCalculateMovementSpeed

	ld a,1 ; only 1 frame if speed was 0
	jr z,+
	ld a,MOVEMENT_FRAMES
+
	ld [wSelectedObjectMovementCounter],a

	; Disable flickering while moving
	ld e,Object.flicker
	xor a
	ld [de],a

@ret
	ret

objectCalculateMovementSpeed:
; =======================================================================================
; Sets an object's speed to move toward a position
; Parameters: d = object
;             bc = target position
;             zflag = set if speed is 0 (both components)
; =======================================================================================
	push hl

	ld h,d
	ld e,Object.speedY
	ld l,Object.tileY
	ld a,b
	call @calcSpeedComponent

	ld e,Object.speedX
	ld l,Object.tileX
	ld a,c
	call @calcSpeedComponent

	ld l,Object.speedY ; Check if speed is 0
	ldi a,[hl]
	or [hl]
	inc l
	or [hl]
	inc l
	or [hl]

	pop hl
	ret

@calcSpeedComponent:
; =======================================================================================
; Calculates the speed necessary to reach the target tile in the movement animation.
; =======================================================================================
	push bc
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
	pop bc
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
	jr c,+
	cp 1*16
	ret nc
+
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
	jr c,+
	cp 1*16
	ret nc
+
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
