
.RAMSECTION "hram" SLOT 4
	hInterruptType:		db
	hOamProcedure:		dsb 10

	; Used with wOam
	hNumOamEntries:	db

	hTmp1:			db
.ENDS
