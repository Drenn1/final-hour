loadGfx:
	ld a,%00000111
	ldh [R_LCDC],a

	ld hl,spriteGfx
	ld de,$8000
	ld c,_sizeof_spriteGfx/32
	call loadSpriteGfx

	ld hl,tileGfx
	ld de,$9000
	ld bc,_sizeof_tileGfx
	call copyMemory

	ld hl,mapData
	ld de,$9800
	ld bc,_sizeof_mapData
	call copyMemory
	ret

loadSpriteGfx:
; =======================================================================================
; Parameters: c = number of 8x16 tiles to load, hl = src, de = dest
; =======================================================================================
--
	call @loadChunk
	push bc
	ld bc,$20*16
	add hl,bc
	pop bc
	call @loadChunk
	push bc
	ld bc,(-$20*16)+16
	add hl,bc
	pop bc
	dec c
	jr nz,--
	ret

@loadChunk:
	ld b,$10
	push hl
-
	ld a,[hli]
	ld [de],a
	inc de
	dec b
	jr nz,-
	pop hl
	ret
