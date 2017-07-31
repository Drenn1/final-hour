.RAMSECTION "wram0" SLOT 2
	wFrameCounter: db
	wLCDC: db
	wWY: db
	wWX: db

	wTextOptionPositions:	dsb 4
	wNumTextOptions:	db
	wSelectedTextOption:	db

	wTextSubstitutions:	dsw 8 ; These are either numbers, or pointers to text.

	wCursorY: db
	wCursorX: db
	wLastCursorY: db
	wLastCursorX: db
	wDrawCursor: db ; nonzero if cursor should be drawn

	wCurrentMap: db

	wNameBuffer: dsb 8

	; Top-left of camera
	wCameraY: db
	wCameraX: db
	; Position camera's moving toward
	wCameraDestY: db
	wCameraDestX: db

	wSelectedObject: db ; Object being controller
	wSelectedObjectMovementCounter: db ; Nonzero while selected object is moving

	wSelectingObject: db ; Nonzero while in the "selectObject" function.
	wTargetObject:    db ; Object being attacked by wSelectedObject

	; Null-terminated list of objects (used ie. when attacking)
	wObjectList:		dsb $20
	wObjectListCount:	db
	wObjectListIndex:	db ; Object currently selected from the list

	wObjectAnimationFrame:		db
	wObjectAnimationCounter:	db

	; Used to handle object flickering when too many objects in one line
	wNumObjectsInRows:		dsb MAP_HEIGHT
	wObjectRowFlickerCounters:	dsb MAP_HEIGHT

	wAttackAnimationState:	db
	wAttackAnimationCounter: db

	wMapLayout:		dsb 32*32 ; Copied to VRAM
	; Bitset of tiles that the selected character can traverse
	wTraversibleTiles: dsb 16*16/8

	wPhase:			db ; 0 for player phase, 1 for enemy phase

	; These are used by ai routines
	wBestTarget:		db
	wBestTargetHP:		db
	wBestTargetPosition:	dw ; Position of attacker, not target

	wStack:		dsb $100
	wStackTop:	.db
.ENDS

.RAMSECTION "aligned" SLOT 2 ALIGN $100
	wBfsBuffer:	dsb $100

	wOam:		dsb 40*4

	; map used by window layer for textboxes
	; Should be aligned to $20
	wWindowMap: dsb 32*4
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

	oamAddress	db
	oamFlags	db ; ORed with the "base" oam flags
	flicker		db ; Set when selected
	animationFrame	db

	flickerIndex	db ; Used when sprites are overloaded on line

	hp		db
	maxHP		db
	morale		db
	moved		db

	aggressive	db ; For AI; if set, they charge

	name		dsb 8
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
