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

EntryLoadPalettes:
	lda	$2002	; read ppu status to reset high/low latch
	lda	#$3F
	sta	$2006	; write high
	lda	#$00
	sta	$2006	; write low
	ldx	#$00
EntryLoadPalettesLoop:
	lda	palette, x ; load data from (palette + x)
	sta	$2007
	inx
	cpx	#$20
	bne	EntryLoadPalettesLoop
	lda	#$00
	sta	$2001	; reset latch
	ldx	#0
	lda	$2002
	lda	#$20
	sta	$2006	; write high
	stx	$2006	; write low
	ldx	#$50
	ldy	#$03
	lda	#$20
EntryBlankScreen:
	sta	$2007
	inx
	bne EntryBlankScreen
	dey
	bne	EntryBlankScreen

	; set attribute tables ( palette table is after screen )
	ldx	#$40
	lda	#$0
EntryWriteAttributeTable:
	sta	$2007
	dex
	bne EntryWriteAttributeTable	

	; set scrolling position and enable screen
	sta	$2005
	sta	$2005
	lda	$001000 ; enable background
	sta	$2001
	;lda	#$20
	;sta	$0010
EntryInitializeShit:
	; dino position
	lda	#$03
	sta	$0028
	sta	$0029
	lda	#$00
	sta	$002A
	sta	$002B
	sta	$002C
	lda	#$23
	sta	$002E
	lda	#$20
	sta	$002F

MainGameLoop:
	lda	#$00
	sta	$002D
	jsr CheckInputs
	jsr GameLogic
	lda	#$01
	jsr Render
	jsr killtime
	jmp MainGameLoop

CheckInputs:
	lda	#$01
	sta	$4016
	lda	#$00
	sta	$4016
	ldx	#$20
LoadInput:
	lda	$4016
	and	#$03
	sta	$00, x
	inx
	cpx	#$28
	bne	LoadInput
	rts

GameLogic:
	; Pause Button
	lda	$0022
	cmp	#$01
	jsr	GamePause
	; Up
	lda	$0024
	cmp	#$01
	bne	dontJump
	jsr	Jump
dontJump:
	; Down
	lda	$0025
	; Left
	lda	$0026
	cmp	#$01
	bne dontMoveLeft
	jsr	MoveLeft
dontMoveLeft:
	; Right
	lda	$0027
	cmp	#$01
	bne	dontMoveRight
	jsr	MoveRight
dontMoveRight:
	; Check if moved
	lda	$002D
	cmp	#$0
	bne notMovedThisFrame
	lda	#$00
	sta	$002C
notMovedThisFrame:
	jsr	DoJumping
	jsr	DoFalling
	rts

Jump:
	;lda	#$20
	;sta	$0001
	;jsr	SubtractFromOffset
	;rts
	lda	$002B
	cmp	#$00
	bne	nopeAlreadyJumping
	lda	$002A
	cmp	#$00
	bne	nopeAlreadyJumping ; actually falling
	lda	#$04
	sta	$002B
nopeAlreadyJumping:
	rts

DoJumping:
	lda	$002B
	cmp	#$00
	beq	dojumping_Done
	tax
	lda	#$20
	sta	$0001
	jsr	SubtractFromOffset
	dex
	txa
	cmp	#$00
	beq	dojumping_SetFall
	stx	$002B
	rts
dojumping_SetFall:
	lda	#$04
	sta	$002A
	stx	$002B
dojumping_Done:
	rts

DoFalling:
	lda	$002A
	cmp	#$00
	beq	dofalling_Done
	tax
	lda	#$20
	sta	$0001
	jsr	AddToOffset
	dex
	stx	$002A
dofalling_Done:
	rts

MoveRight:
	ldx	#$01
	stx	$002D
	lda	#$01
	sta	$0001
	jsr	AddToOffset
	jsr	DinoIsMoving
	rts
MoveLeft:
	ldx	#$01
	stx	$002D
	lda	#$01
	sta	$0001
	jsr	SubtractFromOffset
	jsr	DinoIsMoving
	rts

; parameter
;	0x0001 number to sub
SubtractFromOffset:
	sec
	lda	$002F
	sbc	$0001
	sta	$002F
	lda	$002E
	sbc	#$00
	sta	$002E
	rts

; parameter
;	0x0001 number to sub
AddToOffset:
	lda	$002F
	clc
	adc	$0001
	sta	$002F
	lda	$002E
	adc	#$00
	sta	$002E
	rts

DinoIsMoving:
	lda	$002C
	cmp	#$02
	beq	dinoismoving_SetAnim1
	dinoismoving_SetAnim2:
		lda	#$02
		sta	$002C
		rts
	dinoismoving_SetAnim1:
		lda	#$01
		sta	$002C
		rts

Render:
	jsr	WaitForVBlank

	lda	#$00
	sta	$2001	; reset latch
	ldx	#0
	lda	$2002
	;lda	#$23
	;sta	$2006	; write high
	; #$40 left of screen
	; #$5E right
	;jsr OffsetFromXY
	;lda	#$20
	;lda	$002E
	lda	$002E
	sta	$2006	; write high
	lda	$002F
	sta	$2006	; write low

; Parameters:
;	0x0020 dino animation #
DrawDino:
	lda	$002C
	cmp	#$1
	beq	drawdino_Anim1
	cmp	#$2
	beq	drawdino_Anim2
	cmp	#$3
	beq	drawdino_Anim3
	jmp drawdino_Anim0
	drawdino_Anim1:
		ldx	#$0C
		jmp	DrawDinoForReal
	drawdino_Anim2:
		ldx	#$18
		jmp	DrawDinoForReal
	drawdino_Anim3:
		ldx	#$20
		jmp	DrawDinoForReal
	drawdino_Anim0:
		ldx	#$00
DrawDinoForReal:
	stx	$0003
	lda #$20
	sta	$2007
	inx
	lda #$20
	sta	$2007
	inx
	lda #$20
	sta	$2007
	inx
	lda #$20
	sta	$2007
	ldy #$04
	jsr	PrintLine
	ldx	$0003
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	;lda	dino_sprites, x
	;sta	$2007
	;inx
	ldy	#$03
	jsr	PrintLine
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	;lda	dino_sprites, x
	;sta	$2007
	;inx
	ldy	#$03
	jsr	PrintLine
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	lda	dino_sprites, x
	sta	$2007
	inx
	;lda	dino_sprites, x
	;sta	$2007
	;inx

	; set attribute tables ( palette table is after screen )
	ldx	#$40
	lda	#$0
WriteAttributeTable:
	sta	$2007
	dex
	bne WriteAttributeTable	

	; set scrolling position and enable screen
	lda	#$00
	sta	$2005
	sta	$2005
	lda	$001000 ; enable background
	sta	$2001
	rts

; 2340 is bottom left
; 2320 is one line above
OffsetFromXY:
	ldx	$0028
	ldy	$0029
	sty	$0000
	lda	#$23
	
	adc	#$40
	sta	$002E
	rts

; parameters:
;	0x0010 offset
PrintLine:
	ldy #$1D
	lda	#$20
subtractdone:
	sta	$2007
	dey
	cpy	#$00
	bne	subtractdone
	rts

GamePause:
	rts

;	jmp	MainGameLoop

WaitForVBlank:
	bit	$2002
	bpl	WaitForVBlank
	rts

killtime:
	ldy #$10
	ldx #$10
killtime_1:
	jsr killtime_2
	dex
	bne killtime_1
	dey
	bne killtime_1
killtime_2:
	rts

; ---------
; game data
; ---------

	.bank	1
	.org	$E000
palette:
	.db $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A
	.db $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A, $30,$10,$05,$0A

; ---------------
; dino animations
; ---------------
; 0 - still
; 1 - run 1
; 2 - run 2
; 3 - jump

dino_sprites:
dino_0_top:
	.db	$D0, $D1, $D2, $20
dino_0_mid:
	.db $E0, $E1, $E2, $20
dino_0_bot:
	.db $F0, $F1, $F2, $20
dino_1_top:
	.db	$D3, $D4, $D5, $20
dino_1_mid:
	.db $E3, $E4, $E5, $20
dino_1_bot:
	.db $F3, $F4, $F5, $20
dino_2_top:
	.db	$D6, $D7, $D8, $20
dino_2_mid:
	.db $E6, $E7, $E8, $20
dino_2_bot:
	.db $F6, $F7, $F8, $20
dino_3_top:
	.db	$D9, $DA, $DB, $20
dino_3_mid:
	.db $E9, $EA, $EB, $20
dino_3_bot:
	.db $F9, $FA, $FB, $20



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
	.incbin	"dinoset.chr" ; includes 8KB graphics file
