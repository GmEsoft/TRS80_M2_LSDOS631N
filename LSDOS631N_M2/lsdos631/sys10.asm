;****************************************************************;* Filename: SYS10/ASM						*;* Rev Date: 30 Nov 97						*;* Version : 6.3.1						*;****************************************************************;* Code to remove a file or device.  Handles @REMOV SVC.	*;*								*;****************************************************************;	TITLE	<SYS10 - LS-DOS 6.3>;*LIST	OFF*GET	SYSRES/EQU*LIST	ONLF	EQU	10CR	EQU	13;*GET	COPYCOM;	ORG	1E00H;SYS10	AND	70H		; Strip bit 7	RET	Z		; Back on zero entry	CP	10H		; Remove all for now	RET	NZ		; Return if any other entry	LD	A,(DE)		; Test device/file	BIT	7,A		; File open or device?	JR	Z,CLOSDCB	; Jump if device	CALL	CKOPEN@		; Test for open file	LD	A,(IX+01H)	;   & link the FCB to IX	AND	07H		; Test for REMOVE access	CP	02H	JR	C,REMOV1	; Jump if access granted	LD	A,25H		;   else init error code	OR	A	RET;REMOV1	LD	C,(IX+06H)	; Get drive #	LD	B,(IX+07H)	; Get dir entry code	CALL	@GATRD		; Read GAT into DIRBUF$REMOV2	CALL	Z,@DIRRD	; Read dir for this DEC	RET	NZ		; Ret if read error	LD	A,22		; Point to 1st extent	ADD	A,L	LD	L,AREMOV3	LD	E,(HL)		; Get relative cylinder	INC	L	LD	D,(HL)		; Get granule allocation	LD	(EXTINFO+1),DE	; Modify later instruction	LD	A,E		; Check if extent in use	CP	0FEH	JR	NC,FIXDIR	; Jump if not used	INC	L	CALL	RMVEXT		; Deallocate ext from GAT	JR	REMOV3		; Loop to next extent;;	Deallocated last extent; clean up directory;FIXDIR	LD	A,L		; Point to 1st byte	AND	0E0H		;   of DIR entry	LD	L,A	RES	4,(HL)		; Show dir entry spare	CALL	@DIRWR		; Write the dir record	CALL	Z,@HITRD	; Grab HIT -> SBUFF$	LD	H,SBUFF$<-8	; Point to HIT entry	LD	L,B		;   & zero out DEC pos	LD	(HL),00H	CALL	Z,@HITWR	; Write HIT back to disk	RET	NZ		; Return if read/write errorEXTINFO LD	DE,0		; Get last extent info;;	If extended directory record in use,;	D -> DEC of FXDE record;	E -> FE if FXDE, FF if extent unused;	LD	B,D		; Check for FXDE in use	LD	A,E	CP	0FEH		; X'FE' -> FXDE in use	JR	Z,REMOV2	; Jump if in use	CALL	@GATWR		;   else write the GAT	RET	NZ		; Ret if write error	PUSH	IX		; Transfer FCB address	POP	HL		;   to HL & zero out FCB	LD	B,32		; Init for 32 byte field	XOR	A		; Zero the accumulatorZERLP1	LD	(HL),A		; Go for it!	INC	HL	DJNZ	ZERLP1	RET;;	REMOVE will only close a logical device;CLOSDCB CP	10H		; Is this an open DCB?	LD	A,'&'		; Init "File not open"	RET	NZ	CALL	LNKFCB@		; Link to DCB (DE->IX)	LD	C,(IX+6)	; Get device name	LD	B,(IX+7)	LD	(IX+0),'*'	; Stuff device indicator	LD	(IX+1),C	; Stuff 1st char of name	LD	(IX+2),B	; Stuff 2nd char of name	LD	(IX+3),3	; Terminate with ETX	XOR	A	RET;;	Deallocate an extent;RMVEXT	PUSH	HL	PUSH	BC	LD	A,08H		; Get the # of grans per	CALL	@DCTBYT		;   cylinder into reg A	RLCA			; Shift into bits 0-2	RLCA	RLCA	AND	07H		; Remove all else	INC	A		; Adjust for zero offset;;	Check for 2-sided operation;	LD	L,A		; Save current grans/cyl	LD	A,04H	CALL	@DCTBYT		; Get 2-sided flag	BIT	5,A		; Test 2-sided	LD	A,L		; Xfer value back	JR	Z,RMVEX0	; Bypass if 1 sided	ADD	A,A		;   else multiply by 2RMVEX0	LD	(GRNSCYL+1),A	; Modify later instruction	LD	L,E		; Relative cylinder -> L	LD	H,DIRBUF$<-8	; Point to GAT byte	LD	A,D		; Rel gran & # of grans	AND	1FH		; Get # of grans	LD	C,A		; Into reg C & adjust	INC	C		;   for zero offset	XOR	D		; Get rel gran & shift	RLCA			;   into bits 0-2	RLCA	RLCARMVEX1	PUSH	AF		; Save rel starting gran	LD	B,(HL)		; Get allocation byte	CALL	RMVGRN		; Turn off bit for a gran	LD	(HL),B		; Update GAT byte	POP	AF		; Recover starting gran	INC	A		; Bump upGRNSCYL CP	00H		; Check w/ grans per cyl	JR	NZ,DECGRNS	; Go if still on this cyl	XOR	A		;   else zero gran counter	INC	L		; Bump to next cyl in GATDECGRNS DEC	C		; Decrement # of grans	JR	NZ,RMVEX1	; Go if more to deallocate	POP	BC		;   else recover regs	POP	HL		;   & go home	RET;;	Remove a bit to deallocate & free up a gran;RMVGRN	AND	07H		; Max 8-grans per cyl	RLCA			; Shift to create RES	RLCA	RLCA	OR	80H		; Merge rest of RES code	LD	(RMVGRN1+1),A	; Stuff into instructionRMVGRN1 RES	0,B		; Reset proper bit	RET;LAST	EQU	$	IFGT	$,DIRBUF$	ERR	'Module too big'	ENDIF	ORG	MAXCOR$-2	DW	LAST-SYS10	; Overlay size;	END	SYS10