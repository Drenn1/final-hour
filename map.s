.BANK 0 SLOT 0
.SECTION mapLoading FREE

loadMap:
; =======================================================================================
; Parameters: a = map index
; =======================================================================================
	ld [wCurrentMap],a

	cp 3
	jp z,wonGame

	or a
	jr nz,+
	call clearPalettes
	jr ++
+
	call fadeOut
++
	call disableLcd

	call clearBackground
	ld a,%11100100
	ldh [R_BGP],a
	call enableLcd

	call printPreMapText
	ld a,[wCurrentMap]
	or a
	jr z,+
	call decSquadMorale
	call checkDesertion
+
	call disableLcd
	call clearPalettes

	ld a,[wCurrentMap]
	ld hl,mapTable
	add a
	call addAToHL
	ldi a,[hl]
	ld h,[hl]
	ld l,a
	push hl
	ld de,wMapLayout
	ld bc,32*32
	call copyMemory

	pop hl
	ld de,$9800
	ld bc,32*32
	call copyMemory

	; Set object positions
	ld hl,mapObjTable
	ld a,[wCurrentMap]
	add a
	add a
	call addAToHL
	push hl
	ldi a,[hl]
	ld h,[hl]
	ld l,a

	call @loadPlayerObjects
	pop hl
	inc hl
	inc hl
	call @loadEnemyObjects

	call enableLcd
	call fadeIn

	jp playerPhase


@loadPlayerObjects:
	ld d,FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@@nextObj
	ld e,Object.side
	ld a,[de]
	or a
	jr nz,@@nextObj

	ld e,Object.maxHP ; Replenish HP
	ld a,[de]
	dec e
	ld [de],a

	ld e,Object.tileX ; Set position
	ldi a,[hl]
	ld [de],a
	dec e
	ldi a,[hl]
	ld [de],a
	call objectAlignPositionToTile
@@nextObj:
	call getNextObject
	jr c,--
	ret

@loadEnemyObjects:
	ldi a,[hl]
	ld h,[hl]
	ld l,a
--
	ld a,[hl]
	or a
	ret z

	call getFreeObjectSlot
	ret c

	ld e,Object.class
	ldi a,[hl]
	ld [de],a
	ld e,Object.tileX
	ldi a,[hl]
	ld [de],a ; X
	dec e
	ldi a,[hl]
	ld [de],a ; Y

	ld e,Object.hp
	ldi a,[hl]
	ld [de],a
	inc e
	ld [de],a

	ld a,1
	ld e,Object.side
	ld [de],a

	call objectInit
	jr --

printPreMapText:
	ld hl,mapTextTable
	ld a,[wCurrentMap]
	add a
	call addAToHL
	ldi a,[hl]
	ld d,[hl]
	ld e,a
	ld a,1
	call printText
	ret
	
mapTextTable:
	.dw @map0
	.dw @map1
	.dw @map2

@map0:
	.db 16
	.asc "The castle is under" 1
	.asc "siege." 0

@map1:
	.db 16
	.asc "Fled the castle." 0

@map2:
	.db 16
	.asc "Rested in a cave." 1
	.asc "Enemy ambush!" 0

decSquadMorale:
; =======================================================================================
; Squad morale -1.
; =======================================================================================
	push de

	ld de,FIRST_OBJECT_INDEX
--
	ld e,Object.enabled
	ld a,[de]
	or a
	jr z,@next
	ld e,Object.side
	ld a,[de]
	or a
	jr nz,@next
	call objectHasMorale
	jr nc,@next
	ld e,Object.morale
	ld a,[de]
	dec a
	ld [de],a
@next
	call getNextObject
	jr c,--

	ld de,decSquadMoraleText
	ld a,1
	call printText

	pop de
	ret

checkDesertion:
; =======================================================================================
; Prints messages for soldiers who abandon you, then deletes their objects.
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
	call objectHasMorale
	jr nc,@next
	ld e,Object.morale
	ld a,[de]
	or a
	jr z,+
	cp $80
	jr c,@next
+
	; This soldier will desert
	ld hl,wTextSubstitutions
	ld [hl],Object.name
	inc hl
	ld [hl],d
	push de
	ld de,desertionText
	ld a,1
	call printText
	pop de
	call objectDelete
@next
	call getNextObject
	jr c,--
	ret

getTileAddress:
; =======================================================================================
; Parameters: bc = tile position
; Returns:    hl = address of top-left tile in wMapLayout
; =======================================================================================
	push bc
	sla c
	xor a
.rept 2
	rr b
	rr a
.endr
	or c
	ld c,a
	ld hl,wMapLayout
	add hl,bc
	pop bc
	ret

isTileTraversible:
; =======================================================================================
; Parameters: bc = tile position
; Returns:    cflag set if traversible
; =======================================================================================
	push hl
	call getTileAddress
	ld a,[hl]
	cp 3 ; floor tile
	jr z,@nonSolid
	cp 4 ; Outside tile
	jr z,@nonSolid
	cp 10 ; Cave tile
	jr z,@nonSolid

@solid:
	pop hl
	xor a
	ret

@nonSolid:
	pop hl
	scf
	ret

.ENDS


.BANK 1 SLOT 1
.ORGA $4000

.SECTION "maps" FREE

mapTable:
	.dw map0
	.dw map1
	.dw map2

mapObjTable:
	.dw map0PlayerObj
	.dw map0EnemyObj
	.dw map1PlayerObj
	.dw map1EnemyObj
	.dw map2PlayerObj
	.dw map2EnemyObj

map0:
	.incbin "gfx/castle.map"

map0PlayerObj:
	.db 2 1
	.db 1 0
	.db 2 0
	.db 3 0
	.db 4 0
	.db 4 1
	.db 13 4

; Format: class,Y,X,Health
map0EnemyObj:
	.db C_SOLDIER,	1, 6, $08
	.db C_SOLDIER,	3, 4, $10
	.db C_SOLDIER,	4, 4, $10

	.db C_SOLDIER,	12,7, $15
	.db C_SOLDIER,	14,7, $15

	.db C_HORSEMAN,	6, 11,$15
	.db C_HORSEMAN,	8, 11,$15

	.db C_KING,     7, 14,$25
	.db 0

map1:
	.incbin "gfx/forest.map"

map1PlayerObj:
	.db 7 1
	.db 6 0
	.db 7 0
	.db 8 0
	.db 9 0
	.db 8 1

map1EnemyObj:
	.db C_HORSEMAN	4, 3, $15
	.db C_SOLDIER	11,3, $15

	.db C_SOLDIER	2, 5, $15
	.db C_SOLDIER	13,5, $15

	.db C_HORSEMAN	6, 11,$20
	.db C_HORSEMAN	9, 11,$20

	.db C_SOLDIER   6, 9, $20
	.db C_SOLDIER   9, 9, $20

	.db C_KING	7, 12,$30
	.db 0

map2:
	.incbin "gfx/cave.map"

map2PlayerObj:
	.db 3 11

	.db 2 11
	.db 3 12
	.db 2 12
	.db 3 13
	.db 4 12
	.db 2 13
	.db 0 0

map2EnemyObj:
	.db C_HORSEMAN	7, 14,$20
	.db C_SOLDIER	5, 10,$20
	.db C_SOLDIER	8, 7, $25
	.db C_HORSEMAN	11,10,$20
	.db C_HORSEMAN	7, 4, $20

	.db C_SOLDIER	10,1, $25
	.db C_SOLDIER	12,1, $20
	.db C_KING	11,1, $35
	.db 0

.ENDS
