	.inesprg	1
	.ineschr	1
	.inesmap	0
	.inesmir	0

	.bank	0
	.org	$C000

RESET:
	sei			; disable irqs
	cld			; disable decimal mode (nes doesn't support it)
	ldx	#$40
	stx	$4017	; disable apu frame irq
	ldx	#$FF
	txs			; set up stack
	inx
	stx	$2000	; disable nmi
	stx	$2001	; disable rendering
	stx	$4010	; disable dmc irqs

	jsr WaitForVBlank
	jsr WaitForVBlank

LoadPalettes:
	lda	$2002	; read ppu status to reset high/low latch
	lda	#$3F
	sta	$2006	; write high
	lda	#$00
	sta	$2006	; write low
	ldx	#$00
LoadPalettesLoop:
	lda	palette, x ; load data from (palette + x)
	sta	$2007
	inx
	cpx	#$20
	bne	LoadPalettesLoop

HelloWorld:
	lda	#$00
	sta	$2001	; reset latch
	ldx	#0
	lda	$2002
	lda	#$20
	sta	$2006	; write high
	stx	$2006	; write low
HelloWorld_TopBlank:
	sta	$2007	; write character
	inx
	bne	HelloWorld_TopBlank
HelloWorld_PrintHello:
	lda	hello_string, x
	sta	$2007
	inx
	cpx	#$10
	bne HelloWorld_PrintHello
	ldx	#$00
HelloWorld_DinoTop:
	lda	dino_top, x
	sta	$2007	; write character
	inx
	cpx	#$4
	bne	HelloWorld_DinoTop
	lda	#$20
	ldx	#$0
HelloWorld_DinoLine:
	sta	$2007
	inx
	cpx	#$1C
	bne HelloWorld_DinoLine
	ldx	#$00
HelloWorld_DinoBot:
	lda dino_bot, x
	sta	$2007
	inx
	cpx	#$4
	bne	HelloWorld_DinoBot
	; then fill the rest of screen with blanks
	ldx	#$74	; $10 + $8 + $1C printed chars and $40 attribute bytes
	ldy	#3		; 3 times
	lda	#$20	; spaces
HelloWorld_BottomBlank:
	sta	$2007
	inx
	bne HelloWorld_BottomBlank
	dey
	bne	HelloWorld_BottomBlank

	; set attribute tables ( palette table is after screen )
	ldx	#$40
	lda	#$0
HelloWorld_AttributeTable:
	sta	$2007
	dex
	bne	HelloWorld_AttributeTable

	; set scrolling position and enable screen
	sta	$2005
	sta	$2005
	lda	$001000 ; enable background
	sta	$2001
	lda	#$20
	sta	$0010

MainGameLoop:
	;jsr	killtime
	lda	$0010
	pha
	jsr	Print_Dino1
	pla
	;jsr	killtime
	lda	$0010
	pha
	jsr Print_Dino2
	pla
	ldy	#$00
CheckInput:
	lda	#$01
	sta	$4016
	lda	#$00
	sta	$4016
	lda	$4016
	lda	$4016
	lda	$4016
	lda	$4016
	lda	$4016
	lda	$4016
	lda	$4016
	and #$03
	cmp	#$01
	beq	MoveLeft
	lda	$4016
	and #$03
	cmp	#$01
	beq	MoveRight
	iny
	cpy	#$FF
	beq	MainGameLoop
	jmp	CheckInput
MoveLeft:
	ldx	$0010
	dex
	stx	$0010
	jmp MainGameLoop
MoveRight:
	ldx	$0010
	inx
	stx	$0010
	jmp MainGameLoop

; ---------
; functions
; ---------

WaitForVBlank:
	bit	$2002
	bpl	WaitForVBlank
	rts

killtime:
	ldy #$8f
	ldx #$8f
killtime_1:
	jsr killtime_2
	dex
	bne killtime_1
	dey
	bne killtime_1
killtime_2:
	rts

Print_Dino1:
	jsr WaitForVBlank
	jsr WaitForVBlank

	lda	#$00
	sta	$2001	; reset latch
	lda	$2002
	lda	#$20
	sta	$2006	; write high
	tsx
	inx
	inx
	inx
	lda	$0100, x	
	sta	$2006	; write low
	ldx	#0

Print_DinoTop1:
	lda	dino_top, x
	sta	$2007	; write character
	inx
	cpx	#$5
	bne	Print_DinoTop1
	lda	#$20
	ldx	#$0
Print_DinoLine1:
	sta	$2007
	inx
	cpx	#$1B
	bne Print_DinoLine1
	ldx	#$00
Print_DinoBot1:
	lda dino_bot, x
	sta	$2007
	inx
	cpx	#$5
	bne	Print_DinoBot1
	; set scrolling position and enable screen
	lda	#$00
	sta	$2005
	sta	$2005
	lda	$001000 ; enable background
	sta	$2001
	rts

Print_Dino2:
	jsr WaitForVBlank
	jsr WaitForVBlank

	lda	#$00
	sta	$2001	; reset latch
	lda	$2002
	lda	#$20
	sta	$2006	; write high
	tsx
	inx
	inx
	inx
	lda	$100, x	
	sta	$2006	; write low
	ldx	#0

Print_DinoTop2:
	lda	dino_top, x
	sta	$2007	; write character
	inx
	cpx	#$5
	bne	Print_DinoTop2
	lda	#$20
	ldx	#$0
Print_DinoLine2:
	sta	$2007
	inx
	cpx	#$1B
	bne Print_DinoLine2
	ldx	#$00
Print_DinoBot2:
	lda dino_bot2, x
	sta	$2007
	inx
	cpx	#$5
	bne	Print_DinoBot2
	; set scrolling position and enable screen
	lda	#$00
	sta	$2005
	sta	$2005
	lda	$001000 ; enable background
	sta	$2001
	rts

; ---------
; game data
; ---------

	.bank	1
	.org	$E000
palette:
	;.db $0F,$19,$2B,$39, $0F,$17,$16,$06, $0F,$39,$3A,$3B, $0F,$3D,$3E,$0F
	;.db $30,$10,$05,$0A, $0F,$27,$06,$2D, $0F,$0A,$29,$25, $0F,$02,$38,$3C
	;.incbin "charset.pal"
	.db $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A
	.db $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A

hello_string:
	.db "  Hello World!!!", $00 
dino_top:
	.db $EC, $ED, $EE, $EF, $20, $00
dino_bot:
	.db $FC, $FD, $FE, $FF, $20, $00
dino_bot2:
	.db $DC, $DD, $DE, $DF, $20, $00

	; jump vectors
	.org	$FFFA
	.dw		0		; nmi
	.dw		RESET	; reset
	.dw		0		; brk

; --------
; tilesets
; --------

	.bank	2
	.org	$0000
	.incbin	"charset.chr" ; includes 8KB graphics file

