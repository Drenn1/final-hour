.BANK 0 SLOT 0
.SECTION mapLoading FREE

loadMap:
; =======================================================================================
; Parameters: a = map index
; =======================================================================================
	ld [wCurrentMap],a

	call disableLcd

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

	ld e,Object.tileX
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

mapObjTable:
	.dw map0PlayerObj
	.dw map0EnemyObj
	.dw map1PlayerObj
	.dw map1EnemyObj

map0:
	.incbin "gfx/castle.map"

map0PlayerObj:
	.db 2 1
	.db 1 0
	.db 2 0
	.db 3 0
	.db 12 0

; Format: class,Y,X,Health
map0EnemyObj:
	.db C_SOLDIER,	1, 4, $20
	.db C_SOLDIER,	4, 4, $15
	.db C_SOLDIER,	12,8, $8
	.db 0

map1:
	.incbin "gfx/forest.map"

map1PlayerObj:
	.db 7 1
	.db 6 0
	.db 7 0
	.db 8 0
	.db 9 0

map1EnemyObj:
	.db C_SOLDIER	4, 3, $20
	.db C_SOLDIER	11, 3, $20
	.db 0

.ENDS
