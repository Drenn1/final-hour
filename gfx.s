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

clearBackground:
; =======================================================================================
; Clear BG map.
; =======================================================================================
	ld hl,$9800
	ld b,$400/16
	ld a,$60
	jp fillMemory16


fadeOut:
; =======================================================================================
; Fade BG, Object palettes out.
; =======================================================================================
	ldh a,[R_BGP]
	sla a
	sla a
	ldh [R_BGP],a
	call wait10

	ld c,3
--
	ldh a,[R_BGP]
	sla a
	sla a
	ldh [R_BGP],a

	ldh a,[R_OBP0]
	srl a
	srl a
	ldh [R_OBP0],a

	ldh a,[R_OBP1]
	srl a
	srl a
	ldh [R_OBP1],a

	call wait10

	dec c
	jr nz,--
	ret

wait10:
	ld b,10
-
 	call updateBasics
	call waitForVblank
	dec b
	jr nz,-
	ret

fadeIn:
; =======================================================================================
; Fade BG, Object palettes in.
; =======================================================================================
	ld c,%11100100
	ld h,%00011111
	ld l,%00101111
	ld d,4
--
	ldh a,[R_BGP]
	rr c
	rr a
	rr c
	rr a
	ldh [R_BGP],a

	ldh a,[R_OBP0]
	rl h
	rl a
	rl h
	rl a
	ldh [R_OBP0],a

	ldh a,[R_OBP1]
	rl l
	rl a
	rl l
	rl a
	ldh [R_OBP1],a

	call wait10
	dec d
	jr nz,--
	ret

loadNormalPalettes:
	ld a,%11100100
	ldh [R_BGP],a
	ld a,%00011111
	ldh [R_OBP0],a
	ld a,%00101111
	ldh [R_OBP1],a
	ret

clearPalettes:
	xor a
	ldh [R_BGP],a
	ldh [R_OBP0],a
	ldh [R_OBP1],a
	ret
