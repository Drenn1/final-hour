bfs:
; =======================================================================================
; Parameters: bc = starting position
;             a = depth to search
;             [wSelectedObject] = object that's moving
; Returns:    wTraversibleTiles = bitset of tiles that can be walked on
; =======================================================================================
	push bc
	push de
	push hl

	ldh [<hTmp1],a

	push bc
	ld hl,wTraversibleTiles
	xor a
	ld b,_sizeof_wTraversibleTiles/16
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

	call isTileTraversible ; Check if it's solid
	jr nc,@nextEntry

	push hl
	push de
	call findObjectAtPosition ; Check if there's already something there
	jr nz,+

	ld a,[wSelectedObject]
	ld d,a
	ld e,Object.side
	ld l,e
	ld a,[de]
	cp [hl] ; It's ok if the object is on the same side
	pop de
	pop hl
	jr nz,@nextEntry
	jr ++
+
	pop de
	pop hl
++
	call isTraversibleTilesBitSet ; Check if we've already iterated on this
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
	pop hl
	pop de
	pop bc
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
; Parameters: bc = position bit to check
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
