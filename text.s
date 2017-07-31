.SECTION text

setWindowHeight:
; =======================================================================================
; Parameters: a = window height
; =======================================================================================
	push hl
	ld h,a
	ld a,144
	sub h
	ld [wWY],a
	ld a,7
	ld [wWX],a

	ld hl,wLCDC
	ld a,$20 ; Enable window layer
	or [hl]
	ld [hl],a
	pop hl
	ret

clearWindowMap:
	ld hl,wWindowMap
	ld b,32*4/16
	ld a,$a8 ; space
	jp fillMemory16

hideWindow:
; =======================================================================================
; Hides the text window
; =======================================================================================
	ld hl,wLCDC
	ld a,$ff~$20 ; Disable window layer
	and [hl]
	ld [hl],a
	ret

printText:
; =======================================================================================
; Prints text, and if there are options, this doesn't return until one is chosen.
; Parameters: de = pointer to text (null terminated)
;             a = always wait for input (if nonzero)
; Returns:    cflag = set if a valid option was selected (if B was pressed, this is unset)
;             a = selected text option (if there were options and one was selected)
; =======================================================================================
	ldh [<hTmp1],a ; Store whether to always wait for input
	xor a
	ldh [<hTmp2],a ; Use hTmp2 to remember the number of substitutions done so far

	push bc
	push hl
	ld a,[de]
	inc de
	call setWindowHeight
	call clearWindowMap

	ld hl,wWindowMap
--
	ld a,[de]
	inc de
	or a ; Check null
	jr z,@doneReading

	cp 1 ; Check newline
	jr nz,+
	ld a,l ; Go to next line
	and $e0
	ld l,a
	ld a,$20
	call addAToHL
	jr --
+
	cp 2 ; Check if option
	jr nz,+

	push hl
	ld hl,wNumTextOptions
	ld a,[hl]
	inc [hl]
	pop hl

	ld bc,wTextOptionPositions
	call addAToBC
	ld a,l
	sub <wWindowMap
	ld [bc],a
	ld a,$a8 ; space
	ldi [hl],a
	jr --
+
	cp 3 ; Check if number substitution
	jr nz,+
	call @handleNumberSubstitution
	jr --
+
	cp 4 ; Check if text substitution
	jr nz,+
	call @handleTextSubstitution
	jr --
+
	cp 5 ; Check if signed number substitution
	jr nz,+
	call @handleSignedNumberSubstitution
	jr --
+
	ldi [hl],a
	jr --

@doneReading;
	ldh a,[<hTmp1] ; Check if we're always supposed to wait for input
	or a
	jr nz,+
	ld a,[wNumTextOptions]
	or a
	jr z,@end
+
	xor a
	ld [wSelectedTextOption],a

; If input is needed, this waits for the selection.
; Otherwise this just waits for input.
@waitForSelection:
	call updateBasics
	call waitForVblank

; Check input
	call readInput
	ldh a,[<hButtonsJustPressed]
	ld b,a

	ld hl,wSelectedTextOption
	ld a,[wNumTextOptions]
	ld c,a
	dec c
	or a
	jr z,@doneDirectionalButtons

	bit BTN_BIT_UP,b
	jr nz,+
	bit BTN_BIT_LEFT,b
	jr z,++
+
	ld a,[hl]
	or a
	jr z,++
	dec [hl]
++
	bit BTN_BIT_DOWN,b
	jr nz,+
	bit BTN_BIT_RIGHT,b
	jr z,++
+
	ld a,[hl]
	cp c
	jr nc,++
	inc [hl]
++
@doneDirectionalButtons:
	bit BTN_BIT_A,b
	jr nz,@gotSelection

	bit BTN_BIT_B,b
	jr nz,@cancelSelection

; Update cursor
	ld a,[wNumTextOptions]
	or a
	jr z,@waitForSelection
	ld c,a
	ld b,0
	ld hl,wTextOptionPositions
--
	ldi a,[hl]
	ld de,wWindowMap
	call addAToDE
	ld a,[wSelectedTextOption]
	cp b
	jr z,+
	ld a,$a8 ; space
	jr ++
+
	ld a,$ad ; cursor
++
	ld [de],a
	
	inc b
	ld a,b
	cp c
	jr c,--

	jr @waitForSelection

@gotSelection: ; A button pressed
	xor a
	ld [wNumTextOptions],a

	call clearWindowMap
	pop hl
	pop bc
	scf ; carry flag set on return
	ld a,[wSelectedTextOption]
	ret

@cancelSelection: ; B button pressed
	xor a
	ld [wNumTextOptions],a

	call clearWindowMap

@end:
	pop hl
	pop bc
	xor a ; carry flag unset on return
	ret

@handleNumberSubstitution:
	ldh a,[<hTmp2] ; Get substitution index
	inc a
	ldh [<hTmp2],a
	dec a

	push hl
	ld hl,wTextSubstitutions
	add a
	call addAToHL

	ld a,[hl] ; Print this number
	pop hl
	ld b,a

	ld a,[de] ; Check if only one digit should be printed
	cp 3
	jr nz,+
	ld a,b
	and $f0
	swap a
	call @printDigit
+
	ld a,b
	and $0f
	call @printDigit

	ld a,[de]
	cp 3
	ret nz
	inc de
	ret

@handleSignedNumberSubstitution:
	ldh a,[<hTmp2] ; Get substitution index
	inc a
	ldh [<hTmp2],a
	dec a

	push hl
	ld hl,wTextSubstitutions
	add a
	call addAToHL

	ld a,[hl] ; Print this number
	pop hl

	bit 7,a
	jr z,+
	cpl
	inc a
	ld b,a
	ld a,$a7 ; minus
	jr ++
+
	ld b,a
	ld a,$af ; plus
++
	ldi [hl],a

	ld a,b
	and $0f
	call @printDigit

	inc de
	ret

@printDigit:
	add $81 ; '0'
	ldi [hl],a
	ret

@handleTextSubstitution:
	ldh a,[<hTmp2] ; Get substitution index
	inc a
	ldh [<hTmp2],a
	dec a

	push de
	push hl
	ld hl,wTextSubstitutions
	add a
	call addAToHL
	ldi a,[hl]
	ld d,[hl]
	ld e,a

; Insert text
	pop hl
	ld b,0
--
	ld a,[de]
	or a
	jr z,+
	ldi [hl],a
	inc de
	inc b
	jr --
+
	pop de

; Insert padding if necessary (equal to number of "@" characters in string)
	ld c,1
--
	ld a,[de]
	cp 4 ; Text substitution character
	jr nz,+
	inc de
	inc c
	jr --
+
	ld a,c
	sub b
	ret z
	ld b,a
	ld a,$a8 ; space
--
	ldi [hl],a
	dec b
	jr nz,--
	
	ret

afterMoveText:
	.db 16
	.asc "% Attack  % Wait" 0

nobodyToAttackText:
	.db 16
	.asc " Nobody to attack." 0

statText:
	.db 16
	.asc "@@@@@@@   @@@@@@@@" 1
	.asc "HP:##/##  MRL:$$" 0

noMoraleStatText:
	.db 16
	.asc "@@@@@@@   @@@@@@@@" 1
	.asc "HP:##/##  MRL:--" 0

battleStatText:
	.db 24
	.asc "@@@@@@@   @@@@@@@" 1
	.asc "HP:##/##  HP:##/##" 1
	.asc "ATK:##    ATK:##" 0

playerPhaseText:
	.db 16
	.asc "   Player phase" 0

enemyPhaseText:
	.db 16
	.asc "    Enemy phase" 0

moraleIncText:
	.db 16
	.asc "Morale +#" 0

moraleDecText:
	.db 16
	.asc "Morale -#" 0

.ENDS
