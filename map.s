loadMap:
; =======================================================================================
; Call this while the LCD is off.
; Parameters: hl = map data
; =======================================================================================
	push hl
	ld de,wMapLayout
	ld bc,32*32
	call copyMemory

	pop hl
	ld de,$9800
	ld bc,32*32
	call copyMemory
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

@solid:
	pop hl
	xor a
	ret

@nonSolid:
	pop hl
	scf
	ret
