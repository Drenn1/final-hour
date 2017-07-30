.NAME "FINALHOUR"

.ROMDMG
.ROMBANKSIZE $4000
.ROMBANKS 2
.CARTRIDGETYPE 0
.RAMSIZE 0

.NINTENDOLOGO
.COMPUTEGBCHECKSUM
.COMPUTEGBCOMPLEMENTCHECK


.ASCIITABLE
MAP "0" TO "9" = $81
MAP "A" TO "Z" = $8b
MAP "a" TO "z" = $8b
MAP "." = $a5
MAP "!" = $a6
MAP "-" = $a7
MAP " " = $a8
MAP ":" = $a9
MAP "<" = $aa
MAP ">" = $ab
MAP "'" = $ac
; $ad = cursor
MAP "/" = $ae

MAP "%" = $02 ; Marker for options
MAP "#" = $03 ; Marker for number substitution
MAP "@" = $04 ; Marker for text substitution
.ENDA
