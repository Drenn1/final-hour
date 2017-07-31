; Written by XPMC at 18:18:54 on Monday July 31, 2017.

.IFDEF XPMP_MAKE_GBS

.MEMORYMAP
	DEFAULTSLOT 1
	SLOTSIZE $4000
	SLOT 0 $0000
	SLOT 1 $4000
.ENDME

.ROMBANKSIZE $4000
.ROMBANKS 2
.BANK 0 SLOT 0
.ORGA $00

.db "GBS"
.db 1		; Version
.db 1		; Number of songs
.db 1		; Start song
.dw $0400	; Load address
.dw $0400	; Init address
.dw $0408	; Play address
.dw $fffe	; Stack pointer
.db 0
.db 0
.db "Main theme", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db "Drenn", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db "#OCTAVE-REV 0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.INCBIN "gbs.bin"

.ELSE

.DEFINE XPMP_EPMAC_NOT_USED
.DEFINE XPMP_ENMAC_NOT_USED
.DEFINE XPMP_EN2MAC_NOT_USED
.DEFINE XPMP_CHN0_USES_MP
.DEFINE XPMP_CHN2_USES_MP
xpmp_dt_mac_tbl:
xpmp_dt_mac_loop_tbl:

xpmp_v_mac_0:
.db $07, $06, $05, $04, $03, $02, $01, $80
xpmp_v_mac_0_loop:
.db $00, $80
xpmp_v_mac_1:
.db $07, $07, $07, $07, $07, $06, $06, $06, $06, $06, $05, $05, $05, $05, $05, $04, $04, $04, $04, $04, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $80
xpmp_v_mac_1_loop:
.db $00, $80
xpmp_v_mac_30:
.db $02, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $80
xpmp_v_mac_30_loop:
.db $00, $80
xpmp_v_mac_tbl:
.dw xpmp_v_mac_0
.dw xpmp_v_mac_1
.dw xpmp_v_mac_30
xpmp_v_mac_loop_tbl:
.dw xpmp_v_mac_0_loop
.dw xpmp_v_mac_1_loop
.dw xpmp_v_mac_30_loop

xpmp_VS_mac_tbl:
xpmp_VS_mac_loop_tbl:

xpmp_EP_mac_tbl:
xpmp_EP_mac_loop_tbl:

xpmp_EN_mac_tbl:
xpmp_EN_mac_loop_tbl:

xpmp_MP_mac_5:
.db $28, $03, $02
xpmp_MP_mac_tbl:
.dw xpmp_MP_mac_5

xpmp_CS_mac_tbl:
xpmp_CS_mac_loop_tbl:

xpmp_WT_mac_tbl:
xpmp_WT_mac_loop_tbl:

xpmp_waveform_data:
.db $00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

xpmp_callback_tbl:


xpmp_pattern_tbl:

xpmp_s1_channel_A:
.db $14,$9A,$09,$00,$21,$F5,$01,$0C,$48,$00,$39,$9A,$09,$00,$09,$6C
.db $00,$07,$0C,$00,$09,$0C,$00,$07,$0C,$00,$06,$48,$00,$04,$48,$00
.db $06,$81,$10,$00,$F1,$02,$06,$81,$10,$00,$39,$9A,$09,$00,$09,$6C
.db $00,$04,$24,$00,$07,$48,$00,$06,$48,$00,$04,$81,$10,$00,$F1,$02
.db $04,$81,$10,$00,$F9,$0A,$00
xpmp_s1_channel_B:
.db $13,$9A,$12,$00,$F1,$02,$20,$9A,$12,$00,$0C,$48,$00,$6C,$62,$64
.db $69,$6B,$0C,$36,$00,$0C,$81,$10,$00,$6C,$62,$64,$69,$6B,$0C,$36
.db $00,$0C,$81,$10,$00,$6C,$62,$64,$69,$6B,$0C,$36,$00,$0C,$81,$10
.db $00,$6C,$62,$64,$67,$69,$0C,$36,$00,$0C,$81,$10,$00,$F9,$0D,$00
xpmp_s1_channel_C:
.db $13,$9A,$09,$00,$33,$F1,$03,$EC,$01,$F5,$01,$9F,$F4,$0C,$48,$00
.db $32,$9A,$09,$00,$09,$6C,$00,$07,$0C,$00,$09,$0C,$00,$07,$0C,$00
.db $06,$48,$00,$04,$48,$00,$06,$81,$10,$00,$F1,$03,$06,$81,$10,$00
.db $32,$9A,$09,$00,$09,$6C,$00,$04,$24,$00,$07,$48,$00,$06,$48,$00
.db $04,$81,$10,$00,$F1,$03,$04,$81,$10,$00,$F9,$10,$00
xpmp_s1_channel_D:
.db $18,$9A,$09,$00,$20,$F1,$01,$0C,$48,$00,$0C,$81,$10,$00,$0C,$81
.db $10,$00,$0C,$81,$10,$00,$00,$24,$00,$00,$0C,$00,$00,$0C,$00,$00
.db $0C,$00,$00,$24,$00,$0C,$24,$00,$F9,$0A,$00

xpmp_song_tbl:
.dw xpmp_s1_channel_A
.dw xpmp_s1_channel_B
.dw xpmp_s1_channel_C
.dw xpmp_s1_channel_D
.ENDIF