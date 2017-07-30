
.RAMSECTION "hram" SLOT 4
	hInterruptType:		db
	hOamProcedure:		dsb 10

	; Used with wOam
	hNumOamEntries:	db

	hUpdateWindowMap:	db ; If nonzero, one 3rd of the window is updated at vblnk

	; When nonzero, the hblank interrupt does the death animation on this address in
	; the oam
	hOamFlicker:		db
	hOamFlickerLine:	db
	hOamFlickerSize:	db

	hTmp1:			db
	hTmp2:			db
	hTmp3:			db
.ENDS
