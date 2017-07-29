.RAMSECTION "wram0" SLOT 2
	wFrameCounter: db

	wCursorY: db
	wCursorX: db
	wLastCursorY: db
	wLastCursorX: db

	; Top-left of camera
	wCameraY: db
	wCameraX: db
	; Position camera's moving toward
	wCameraDestY: db
	wCameraDestX: db

	wSelectedObject: db
	wSelectedObjectMovementCounter: db ; Nonzero while selected object is moving

	; Bitset of tiles that the selected character can traverse
	wTraversableTiles: dsb 32*32/8

	wStack:		dsb $100
	wStackTop:	.db
.ENDS

.RAMSECTION "oam" SLOT 2 ALIGN $100
	wOam:		dsb 40*4
.ENDS


; wram bank 1 consists of objects (up to 15)
.STRUCT ObjectStruct
	enabled		db

	y		db
	yh		db
	x		db
	xh		db
	tileY		db
	tileX		db
	speedY		dw
	speedX		dw

	wHP		db
	wMoved		db

	name		dsb 6
	class		db
	side		db ; 0 = player, 1 = enemy
.ENDST

.enum 0
	Object: instanceof ObjectStruct
.ende

.define FIRST_OBJECT_INDEX $d0
.define LAST_OBJECT_INDEX $de


; xpmck occupies the end of wram bank 1
.define XPMP_RAM_START $dec0
