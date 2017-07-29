
runGame:
	ld a,1
	ld [$d000],a

mainLoop:
	ld hl,wFrameCounter
	inc [hl]
	call waitForVblank

	ld hl,wSelectedObjectMovementCounter
	ld a,[hl]
	or a
	jr z,++

	; Selected object is moving. Input disabled
	dec [hl]
	jr nz,@doneInput

	; Fix up the object's position
	ld a,[wSelectedObject]
	ld d,a
	call objectAlignPositionToTile

	; Clear selected object's speed
	ld h,d
	ld l,Object.speedY
	xor a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a
	ldi [hl],a
	jr @doneInput
++
	call updateInput
@doneInput

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
	call hOamProcedure
	call drawObjects
	call clearRemainingOam

	jr mainLoop

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
	call objectCheckCanReachTile
	jr c,@@@ok

	ld a,[wLastCursorY]
	ld [wCursorY],a
	ld a,[wLastCursorX]
	ld [wCursorX],a
	pop bc
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
	xor a
	ld [wSelectedObject],a
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
+
	ld a,MOVEMENT_FRAMES
	ld [wSelectedObjectMovementCounter],a

	; Set new tile position
	ld l,Object.tileY
	ld a,[wCursorY]
	ldi [hl],a
	ld a,[wCursorX]
	ld [hl],a
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
	ld a,MOVEMENT_FRAMES
	call divideBCByA
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
