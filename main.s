.include "include/header.s"
.include "libgb/libgb.s"

.include "include/constants.s"
.include "include/wram.s"
.include "include/hram.s"
.include "include/macros.s"

.include "interrupts.s"

.BANK 0 SLOT 0

.ORG $0

; rst $00: aka rst_jumpTable
	pop hl
	add a
	call addAToHL
	ldi a,[hl]
	ld h,[hl]
	ld l,a
	jp hl

.ORG $10
.rept $30
	.db 0 ; Prevent sections from claiming this
.endr

.ORGA $100 ; Entry point
	jp begin

.ORGA $150

.SECTION "Main" SEMIFREE

begin:
	ld sp,wStackTop
	call disableLcd

	; Initialize memory, graphics
	call clearVram
	call clearMemory
	call loadGfx

	; Copy oam subroutine to hram
	ld hl,oamProcedure
	ld de,hOamProcedure
	ld bc,10
	call copyMemory

	; Set palettes
	ld a,%11100100
	ldh [R_BGP],a
	ld a,%00011111
	ldh [R_OBP0],a ; Ally sprites
	ld a,%00101111
	ldh [R_OBP1],a ; Enemy sprites

	; Re-enable screen + interrupts
	call enableLcd
	ld a,INT_VBLANK | INT_TIMER | INT_LCD
	ldh [R_IE],a
	ei

	; Initialize audio
; 	ld a, %111
; 	ldh (R_TAC), a
; 	ld a, 1
; 	ld hl, xpmp_song_tbl
; 	call xpmp_init

	jp runGame


; Procedure copied to hram
oamProcedure:
	ld a,>wOam
	ldh [R_DMA],a
	ld a,$28
@loop
	dec a
	jr nz,@loop
	ret

.include "gfx.s"
.include "game.s"
.include "objects.s"
.include "sprites.s"
.include "bfs.s"
.include "ai.s"
.include "party.s"

.ENDS

.include "map.s"
.include "text.s"


.BANK 1 SLOT 1
.ORGA $4000

.SECTION gfx

tileGfx:
	.incbin "gfx/tiles.2bpp"

spriteGfx:
	.incbin "gfx/sprites.2bpp"

textGfx:
	.incbin "gfx/text.2bpp"

.ENDS
