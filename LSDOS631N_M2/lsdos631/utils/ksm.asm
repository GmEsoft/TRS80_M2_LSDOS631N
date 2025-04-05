; ***************************************************************; * Filename: KSM/ASM						*; * Revision: 06.03.01						*; * Rev Date: 18 Dec 97						*; ***************************************************************; * Keystroke Multiplier Filter for LS-DOS			*; *								*; ***************************************************************;	TITLE	<KSM/FLT - LS-DOS 6.3>;LF	EQU	10CR	EQU	13;*GET	COPYCOM			; Copyright message*GET	SVCMAC			; System SVC Macros;	ORG	2400H;KSM	@@CKBRKC		; Check for break	JR	Z,KSMA		; Continue if not	LD	HL,-1		; Init abort code	RET			;   and quit;KSMA	LD	(KSMDCB),DE	; Save pointer to DCB	PUSH	HL		; Save pointer to cmd line	@@DSPLY	HELLO$		; Display copyright msg	@@FLAGS			; Get system flags	POP	HL		; Recover cmd line ptr;;	Check if entry was from SET command;	BIT	3,(IY+'C'-'A')	; System request?	JP	Z,VIASET	LD	DE,KSMFCB	; Point to FCB	@@FSPEC			; Fetch the KSM filespec	JP	NZ,SPCREQ	; Jump on bad spec	PUSH	DE		; Save FCB pointer	LD	DE,PRMTBL$	; Parse parameters	@@PARAM	POP	DE		; Recover FCB	JP	NZ,IOERR	; Quit on param error	LD	HL,DFTKSM	; Init to default ext	@@FEXT;;	Transfer requested ENTER char to test location;EPARM	LD	HL,';'		; Set default ";"	LD	A,(ERSP)	; Test param response	BIT	6,A		; Flag is no good!	JP	NZ,PRMERR	BIT	5,A		; Test if string or value	LD	A,(HL)		; Get assumed string	JR	NZ,$+3		; Go if string entry	LD	A,L		; Get hex or dec entry	LD	(ECHAR+1),A	; Stuff it in there	PUSH	DE	LD	DE,KSM$		; Check if filter is	@@GTMOD			;   already resident	LD	(KSMMEM+1),HL	; Stuff start	EX	DE,HL		; Put DCB ptr in HL	POP	DE	JR	NZ,OPENKSM	; Go if not resident;;	Make sure that the new DCB is same as the old;	PUSH	HL		; Save where to put it	LD	C,(HL)		; Get DCB pointer LSB	INC	HL	LD	B,(HL)		; Get DCB pointer MSB	LD	HL,6		; Get old DCB name &	ADD	HL,BC		;   stuff into error msg	LD	A,(HL)		;   in case different	INC	L		;   DCBs	LD	H,(HL)	LD	L,A	LD	(DCBNAM$),HL	OR	H		; If DCB name is null.	LD	HL,(KSMDCB)	PUSH	HL		; Save pointer to stuff	JR	Z,UPDPTR	;   then okay to use	OR	A	SBC	HL,BC		; Same DCB pointer?UPDPTR	POP	BC		; Recover pointer to stuff	POP	HL		; Recover addr to put ptr	JP	NZ,DCBERR	; Quit if filter in use;;	Same DCB - Okay to stuff it;	LD	(HL),C		; Store the DCB pointer	INC	HL	LD	(HL),BKSMMEM	LD	HL,$-$		; If resident, ptr to start	LD	BC,ECHAR-DVRBGN+1	ADD	HL,BC		; Resident, stuff ECHAR	LD	A,(ECHAR+1)	;   where it is in memory	LD	(HL),A		; Stuff in upper memOPENKSM	LD	HL,KSMBUF	; Point to buffer area	LD	B,00H		; Init LRL=256	@@OPEN			; Open the file	JP	NZ,IOERR	; Quit on open error	LD	HL,DVREND	; Place file in memory first	LD	B,26		; Init for 26 linesKSM1	@@GET			; Get a char from file	JR	NZ,KSM2		; Jump on error	LD	(HL),A		; Stuff into memory	INC	HL		; Inc memory pointer	CP	0DH		; Found end of line?	JR	NZ,KSM1		; Loop if not	DJNZ	KSM1		; Decrement the A-Z loop	DEC	HL		; Backup over last CR and	INC	B		;   adjust for one more	LD	A,1CH		; No error here, just EOFKSM2	PUSH	AF		; Save error code	@@CLOSE			; Close the file	POP	AF		; Get error code back	CP	1CH		; End of file??	JP	NZ,IOERR	; Quit if not EOFKSM3	LD	(HL),0DH	; End with an <ENTER>	INC	HL		;   for all remaining	DJNZ	KSM3		;   "letters" not entered	LD	IX,(KSMDCB)	; Get user DCB entry	LD	DE,DVREND	; Calculate the length	XOR	A		;   of the KSM file	SBC	HL,DE		;   just loaded	LD	B,H		; Put length in BC	LD	C,L	LD	HL,(KSMMEM+1)	; If not previously res,	LD	A,L		;   move to HIGH$	OR	H	JR	Z,MOVTOHI	PUSH	BC		; Save length	PUSH	HL		; Save old start	ADD	HL,BC		; Start + data	JR	C,KSM3A		; Bad if wrap past 0	LD	BC,DVREND-DVRBGN+1	ADD	HL,BC		; Start + data + filter	JR	C,KSM3A		; Bad if wrap past 0	EX	DE,HL		; Save in DE	POP	HL		; Recover old start	INC	HL		; Point to last byte used	INC	HL	LD	A,(HL)		; Get last byte used	INC	HL		;   into HL	LD	H,(HL)	LD	L,A	PUSH	HL	XOR	A		; Clear carry flag	SBC	HL,DE		; Is req > available?KSM3A	POP	HL		; Get old start to reuse	POP	BC		; Recover length of req	JP	C,NOROOM	JR	KSM0A;;	Move driver into position;MOVTOHI	PUSH	BC		; Save data length	LD	HL,0		; Get current high mem	LD	B,L	@@HIGH$	POP	BCKSM0A	LD	(DVRBGN+2),HL	; Stuff last byte used	LD	(RX1),HL	; Stuff ptr to flag byte	LD	(HL),00H	; Init KSM char ptr	DEC	HL		;   to zero to show no	LD	(HL),00H	;   char avail at startup	DEC	HL	LD	DE,DVREND	; Move data to highMOVLP	LD	A,(DE)		; Data is in reverse order	LD	(HL),A	DEC	HL		; Dec himem pointer	INC	DE		;   and inc char ptr	DEC	BC		; Reduce char count	LD	A,B		;   and check if done	OR	C	JR	NZ,MOVLP	; Loop back if not;	LD	BC,DVREND-DVRBGN ; Get driver length	XOR	A		; Reduce potential HIGH$	SBC	HL,BC		;   by driver length	LD	A,(KSMMEM+1)	; Don't update HIGH$ if	OR	A		;   previously resident	JR	Z,DOHIGH	; Go if not resident;;	Module already resident;	LD	DE,(KSMMEM+1)	; Get module entry point	LD	HL,KSMRPL$	;   & resume the filter	JR	KSM8;;	Stuff new HIGH$ value (Note: B=0 for driver;	length so there is no damage on the @@HIGH$ SVC;DOHIGH	LD	B,00H	@@HIGH$	INC	HL		; Point to driver start	EX	DE,HL	PUSH	DE		; Save start of driver	LD	HL,KSMDCB-DVRBGN	ADD	HL,DE		; Point to filter DCB ptr	LD	(RX2),HL	LD	HL,DVRBGN	; Move params also	LDIR	POP	DE		; Recover driver entry pt	LD	HL,KSMACT$	; "KSM installedKSM8	LD	(IX+00H),40H!5	; Set DCB type to "input"	LD	(IX+01H),E	;   & filter and  stuff the	LD	(IX+02H),D	;   filter address	SET	6,(IY+'D'-'A')	; Turn on device flag bit	@@LOGOT			; Display installation msg	LD	HL,0		; Set no error	RET			; Back to the user;;	Error processing;VIASET	LD	HL,VIASET$	; "Install with set...	DB	0DDHDCBERR	LD	HL,DCBERR$	; "Filter in use...	DB	0DDHNOROOM	LD	HL,NOROOM$	; "Memory frozen...	DB	0DDHSPCREQ	LD	HL,SPCREQ$	; "Missing filespec...	@@LOGOT			; Display the error	LD	HL,-1		; Set abort code	RET;PRMERR	LD	A,44		; Param errorIOERR	LD	L,A		; Error code to HL	LD	H,00H	OR	0C0H		; Short msg, return	LD	C,A	@@ERROR	RET;;	Data and Message Area;KSM$	DB	'$KSM',03HDFTKSM	EQU	$		; Default extension, too.  :)HELLO$	DB	'KSM Filter'*GET	CLIENTVIASET$	DB	'Must install via SET',0DHSPCREQ$	DB	'Filespec required',0DHKSMACT$	DB	'KSM is now operational',0DHKSMRPL$	DB	'KSM filter data replaced',0DHDCBERR$	DB	'KSM filter already attached to *'DCBNAM$	DB	'xx',0DHNOROOM$	DB	'Request exceeds available memory',0DH;PRMTBL$	DB	'R'!80H	DB	0F5H	DB	'ENTER'ERSP	DB	00H	DW	EPARM+1	DB	00H;KSMFCB	DS	32KSMBUF	DS	256;;	Key-stroke Multiplication Driver;DVRBGN	JR	START		; Branch around header	DW	$-$		; Last byte used	DB	04H,'$KSM'KSMDCB	DW	0		; Pointer to KSM's DCB	DW	0START	LD	HL,0		; Get possible addressRX1	EQU	$-2	LD	D,(HL)		;   a KSM that was parsed	DEC	HL		;   to a ";" logical ENTER	LD	E,(HL)		; If this vector is zero,	DEC	HL		;   no KSM continuation is	EX	DE,HL		;   pending - find a new	PUSH	AF		;   entry.  Save flags.	LD	A,H		;   If <> 0, grab the KSM	OR	L		;   line continuation	JR	NZ,DVR4A	POP	AF		; Recover flags	PUSH	DE		; Save ptr to 'A'-KSM	LD	IX,(KSMDCB)	; Chain to next DCB moduleRX2	EQU	$-2	@@CHNIO	POP	DE		; Recover 'A'-KSM pointer	RET	NZ		; Back if nothing or error	BIT	7,A		; Is it a CLEAR function?	RET	Z		; Return if CLEAR not down	PUSH	AF		; Save key entry	CP	'A'+80H		; Check for range A-Z	JR	C,DVR2		; Exit if < 'A'	CP	'Z'+1+80H	JR	C,DVR3		; Use it if A-ZDVR2	POP	AF		; Recover original flag	CP	A		; Set Z flag	RET;;	Key code entry includes <CLEAR> key;DVR3	POP	AF		; Recover orignal flag	LD	H,D		; Put ptr to 'A'-KSM	LD	L,E		;   into HL	SUB	'A'+80H		; Adjust offset to index	JR	Z,DVR5		; Bypass if it was 'A'	LD	B,A		; Set loop counter	LD	A,0DH		; Read past the KSM linesDVR4	CP	(HL)		;   for letters preceding	DEC	HL		;   key entry to find the	JR	NZ,DVR4		;   KSM line for entered	DJNZ	DVR4		;   key code	DB	3EH		; Ignore next instruction;;	Routine to pick up the next KSM character;	and return it to the system KI request;DVR4A	POP	AF		; Clean the stackDVR5	LD	A,(HL)		; Get the next KSM char	DEC	HL		; Dec pointer to the next one	EX	DE,HL		; Put either a pointer to	INC	HL		;   the next KSM char, or	CP	0DH		;   if got last, zero the	JR	Z,DVR6		;   data pointer	LD	(HL),E		; Stuff pointer to next char	INC	HL		;   to fetch	LD	(HL),DECHAR	CP	';'		; Check on logical line end	JR	NZ,DVR7		;   and convert to ENTER if	LD	A,0DH		;   it was semi-colonDVR7	CP	A		; Tell the system we have	RET			;   retrieved a char;;	Got the terminating X'0D' - Clear the pointer;DVR6	XOR	A		; Clear the KSM char pointer	LD	(HL),A		;   as next request is new	INC	HL	LD	(HL),A	CP	0FFH		; Set NZ and A=0	RETDVREND	EQU	$;	END	KSM;