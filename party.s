
loadParty:
; =======================================================================================
; Called once at the start of the game, loads all party members into objects.
; Their positions are not set here.
; =======================================================================================
	ld hl,partyData
@next
	ld a,[hl]
	or a
	ret z

	call getFreeObjectSlot
	ret c

	ld e,Object.class
	ldi a,[hl]
	ld [de],a

	ldi a,[hl]
	ld e,Object.morale
	ld [de],a
	ldi a,[hl]
	ld e,Object.hp
	ld [de],a
	inc e
	ld [de],a

	ld e,Object.name
--
	ldi a,[hl]
	or a
	ld [de],a
	jr z,@gotName
	inc e
	jr --
@gotName
	call objectInit
	jr @next


partyData:
	.db C_KING
	.db 0 ; morale
	.db $30 ; health
	.asc "Mathias" 0

	.db C_HORSEMAN
	.db 1 ; morale
	.db $25 ; health
	.asc "Ralph" 0

	.db C_SOLDIER
	.db 3 ; morale
	.db $15 ; health
	.asc "Joffrey" 0

	.db C_SOLDIER
	.db 4 ; morale
	.db $20 ; health
	.asc "Jean" 0

	.db C_HORSEMAN
	.db 5 ; morale
	.db $25 ; health
	.asc "Lin" 0
	.db 0


objectGetClassName:
; =======================================================================================
; Returns: bc = pointer to class text
; =======================================================================================
	push hl

	ld e,Object.class
	ld a,[de]
	ld hl,classNameTable
	add a
	call addAToHL
	ldi a,[hl]
	ld b,[hl]
	ld c,a

	pop hl
	ret

classNameTable:
	.dw 0
	.dw kingText
	.dw soldierText
	.dw horseText
	.dw knightText

kingText:
	.asc "King" 0
soldierText:
	.asc "Soldier" 0
horseText:
	.asc "Horseman" 0
knightText:
	.asc "Knight" 0


objectGetMovement
; =======================================================================================
; Returns: a = object's movement distance
; =======================================================================================
	push hl

	ld hl,@classMovements
	ld e,Object.class
	ld a,[de]
	call addAToHL
	ld a,[hl]

	pop hl
	ret

@classMovements:
	.db 0
	.db 4 ; King
	.db 4 ; Soldier
	.db 7 ; Horse


objectGetAttack:
; =======================================================================================
; Returns: a = object's attack
; =======================================================================================
	push hl
	ld hl,classAttackTable
	ld e,Object.class
	ld a,[de]
	call addAToHL
	ld a,[hl]
	pop hl
	ret

classAttackTable:
	.db 0
	.db 10 ; King
	.db 10 ; Soldier
	.db 8 ; Horse

