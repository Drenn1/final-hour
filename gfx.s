loadGfx:
	ld a,%11000111
	ld [wLCDC],a

	ld a,%01000000 ; LYC interrupt
	ldh [R_STAT],a

	ld hl,spriteGfx
	ld de,$8000
	ld c,_sizeof_spriteGfx/32
	call loadSpriteGfx

	ld hl,tileGfx
	ld de,$9000
	ld bc,_sizeof_tileGfx
	call copyMemory

	ld hl,textGfx
	ld de,$8800
	ld bc,$800
	ld bc,_sizeof_textGfx
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
