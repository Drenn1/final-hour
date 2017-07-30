bfs:
; =======================================================================================
; Parameters: bc = starting position
;             a = depth to search
; =======================================================================================
	ldh [<hTmp1],a
	xor a
	ld [wBfsBufferEntries],a

	push bc
	ld hl,wTraversibleTiles
	xor a
	ld b,16*16/16
	call fillMemory16

	pop bc ; Starting Y/X position
	ld hl,wBfsBuffer ; hl = where to read from
	ld de,wBfsBuffer ; de = where to write to

	ld a,b
	ld [de],a ; Y
	inc e
	ld a,c
	ld [de],a ; X
	inc e
	xor a
	ld [de],a ; Depth
	inc e

@nextEntry
	ld a,l
	cp e
	jr z,@done

	ld b,[hl]
	inc l
	ld c,[hl]
	inc l
	ld a,[hl]
	inc l
	ldh [<hTmp2],a

	call isTileTraversible
	jr nc,@nextEntry
	call isTraversibleTilesBitSet
	jr nz,@nextEntry

	call setBitInTraversibleTiles

	push bc
	ldh a,[<hTmp1] ; Check if we've reached maximum depth
	ld b,a
	ldh a,[<hTmp2]
	cp b
	pop bc
	jr nc,@nextEntry

	inc c
	call @addToBfs
	dec c
	dec c
	call @addToBfs
	inc c
	inc b
	call @addToBfs
	dec b
	dec b
	call @addToBfs

	jr @nextEntry

@done
	ret

@addToBfs:
	ld a,b
	ld [de],a ; Y
	inc e
	ld a,c
	ld [de],a ; X
	inc e
	ldh a,[<hTmp2]
	inc a
	ld [de],a ; Depth
	inc e
	ret


getTraversibleTilesBitHelper:
	xor a
.rept 4
	rr b
	rr a
.endr
	or c
	ld c,a
	push af
.rept 3
	rr b
	rr c
.endr
	ld a,c

	ld hl,wTraversibleTiles
	call addAToHL
	pop af
	and 7
	ld bc,bitTable
	call addAToBC
	ret

setBitInTraversibleTiles:
; =======================================================================================
; Parameters: bc = position bit to set
; =======================================================================================
	push bc
	push hl

	call getTraversibleTilesBitHelper
	ld a,[bc]
	or [hl]
	ld [hl],a

	pop hl
	pop bc
	ret

isTraversibleTilesBitSet:
; =======================================================================================
; Parameters: bc = position bit to set
; Returns:    zflag = set if that bit is not set
; =======================================================================================
	push bc
	push hl
	call getTraversibleTilesBitHelper
	ld a,[bc]
	and [hl]
	pop hl
	pop bc
	ret

bitTable:
	.db $01 $02 $04 $08 $10 $20 $40 $80
