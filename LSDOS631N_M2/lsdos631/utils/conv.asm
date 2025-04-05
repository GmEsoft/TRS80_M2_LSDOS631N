; ***************************************************************; * Filename: CONV/ASM						*; * Revision: 06.03.01						*; * Rev Date: 10 Dec 97						*; ***************************************************************; * Convert TRSDOS 1.2 & 1.3 diskettes to LS-DOS format		*; *								*; ***************************************************************;	TITLE	<CONV - LS-DOS 6.3>;*GET	BUILDVER;	IF	@MOD2*GET	CONV2	ENDIF;	IF	@MOD4*LIST	OFF;HOME	EQU	1CHCLR	EQU	1FHETX	EQU	03HCR	EQU	0DHLF	EQU	0AH;FLAG	EQU	01000000BABB	EQU	00010000B;*GET	SVCMAC			; System SVC macros*GET	COPYCOM			; Copyright message;	ORG	2600H;BEGIN	LD	(SAVESP+1),SP	; Save SP for exiting	@@CKBRKC		; Check if break hit	JR	NZ,$ABORT	; Quit if so;	PUSH	HL		; Save cmd line pointer	LD	HL,HELLO$	; Display the sign on	@@DSPLY	LD	HL,0		; Set up to get HIGH$	LD	B,L	@@FLAGS			; IY => Flag table	BIT	1,(IY+'C'-'A')	; Okay if not CMNDR	JR	Z,NOTCMDR	; Use LOW$ otherwise	INC	BNOTCMDR	@@HIGH$			; Get HIGH$/LOW$	LD	(MYHIGH+1),HL	; Save it	PUSH	IY		; Move flags to DE	POP	DE	LD	HL,'K'-'A'	; KFLAG$ offset	ADD	HL,DE		; HL => KFLAG$	LD	(KFLG),HL	; Save the pointer	RES	0,(HL)		; Kick break bit off	LD	HL,'S'-'A'	; SFLAG$ offset	ADD	HL,DE	LD	(SFLG),HL	; Save the pointer	POP	HL		; Get cmd line back	CALL	PGRM		; Do the program;;	Exit routines;$EXIT	LD	HL,0		; Init no error$QUIT	@@CKBRKC		; Clear any BREAK bitSAVESP	LD	SP,$-$		; Get original SP back	RET			; exit;$ABORT	LD	HL,-1	JR	$QUIT;;;$DSPCR	LD	A,0DH		; Display a CR$DSP	PUSH	BC		; Display a character,	LD	C,A		;   saving BC	@@DSP	POP	BC	RET;;	Get drive numbers and partial filespec;PGRM:	LD	A,(HL)		; Check for NOT filespec	CP	'-'	JR	NZ,MVNAM1	; Go if not NOT	LD	A,0FFH		; TRUE value	LD	(NOTPRM),A	; Set if specified	INC	HLMVNAM1	LD	DE,PATTRN	; Point to possible partspec	LD	B,08H		; Max 8 chars in name	CALL	SKIPSP		; Skip spaces	CALL	MOVELT		; Move letters/digits/$	CALL	SKIPLT		; Skip letters/digits/$	LD	A,(HL)		; Check for extension	CP	'/'	JR	NZ,NOEXT	; Go if none given	INC	HL	LD	DE,PATEXT	; Point to ext field	LD	B,03H		; 3 chars in ext	CALL	MOVELT		; Move letters/digits/$	CALL	SKIPLT		; Skip letters/digits/$NOEXT	CALL	GETDRV		; Get source drive #	LD	(SDRIVE),A	; Save drive #	AND	A		; Be sure not drive 0	LD	DE,NOT0		; Error message	EX	DE,HL	JP	Z,PERR1		; Param error source is 0	EX	DE,HL		; Restore cmd line ptr	CALL	SKIPSP		; Skip spaces	CALL	GETDRV2		; Get destination drive	LD	(DDRIVE),A	; 0FFH if no dest drive	CALL	SKIPSP		; Move to '(';;	Scan parameters;	LD	DE,PRMTBL$	; Check parameters entered	@@PARAM	JP	NZ,PRMERR	; Quit on param errorDPARM	LD	HL,$-$		; Get DIR param	LD	A,H	OR	L	JR	Z,SPARM		; Go if not spec'd	LD	A,0FFH		; Set flag at DDRIVE	LD	(DDRIVE),A	; If dest is FF, read DIRSPARM	LD	HL,$-$		; Check if n params S,I,VVPARM	LD	DE,$-$IPARM	LD	BC,$-$	LD	A,L		; Get SYS	OR	E		; Merge VIS	OR	C		; Merge INV	LD	(SIV+1),A	; Save S!I!VQPARM	LD	HL,-1		; Pick up Q,N,0 paramsNPARM	LD	DE,0OPARM	LD	BC,0	LD	A,E		; Form N!O	OR	C	LD	(NORO+1),A	; Save that;;	Save old DCT;	LD	A,(SDRIVE)	; Get source drive #	LD	C,A		; Move to C reg	LD	A,(DDRIVE)	; Be sure not single drive	CP	C	LD	HL,NOTONE	; HL => error message	JP	Z,PERR1		; Go if the same	@@GTDCT			; Move DCT to HL Reg	PUSH	BC	PUSH	IY	POP	HL	LD	DE,SAVDCT	; Point to save area	LD	BC,10		; Length of DCT entry	LDIR			; Move it	POP	BC;;	Find directory track;	LD	DE,1		; Track 0, sector 1	LD	HL,DBUFF	; Buffer for sector	@@RDSEC			; Read it	JR	Z,OK0		; Go if no error	CP	06H		; Was it DAM error?	JP	NZ,IOERR	; Go if some other	CALL	CKEARLY		; Can we do this type?OK0	INC	HL		; Point to dir cyl #	LD	D,(HL)		; Get it	INC	H		; Point to TRSDOS 1.x	DEC	HL		;   version number	DEC	HL	DEC	HL	LD	A,(HL)		; Get version	LD	(TRSDOS+1),A	; Save for later;;	Read directory records into memory;	LD	E,03H		; Skip GAT and HIT	LD	B,10H		; Read 16 sectors	LD	HL,DBUFFDREAD	LD	(IY+07H),12H	; Chg # sectors/track for	@@RDSEC			;   TRSDOS & read a sector	JR	Z,OK1		; Go if no error	CP	06H		; Ignore DAM error	JP	NZ,IOERR	; Go if any other errorOK1	INC	H		; Bump sector pointer	INC	E		; Inc sector number	DJNZ	DREAD		; Loop until done;;	Loop through all entries;	LD	HL,DBUFF	; Point to 1st entryELOOP	LD	A,($-$)		; Check system break bitKFLG	EQU	$-2	BIT	0,A	JP	NZ,$ABORT	; Abort if set	LD	B,(HL)		; Get attributes	PUSH	HL	POP	IX	PUSH	HL	BIT	4,B		; Alive?	JP	Z,SKIPIT	; Skip if not	BIT	7,B		; FXDE?	JP	NZ,SKIPIT	; Skip it if so;;	Check file's attributes;SIV	LD	A,00H		; S, I or V given?	AND	A	JR	Z,NOSIV		; Go if none given	BIT	6,B		; SYS file?	JR	Z,NOTSYS	; Go if not	LD	A,(SPARM+1)	; S param given?	AND	A	JP	Z,SKIPIT	; Skip file if not	JR	NOSIV		;   else possible matchNOTSYS	BIT	3,B		; Visible or invisible?	JR	NZ,INV		; Go if invisible	LD	A,(VPARM+1)	; V param given	AND	A	JP	Z,SKIPIT	; Skip file if not	JR	NOSIV		;   else possible matchINV	LD	A,(IPARM+1)	; I param given?	AND	A	JP	Z,SKIPIT	; Skip if not;;	Check if name matches wildcard;NOSIV	LD	DE,5		; Offset to name field	ADD	HL,DE	PUSH	HL		; Compare with pattern	LD	DE,PATTRN	;   of user partspec	LD	B,11CPLOOP	LD	A,(DE)		; Get pattern byte	INC	DE	CP	'$'		; Match all?	JR	Z,MATCH		CP	(HL)		; Match?	JR	NZ,NMATCH	; Go if notMATCH	INC	HL	DJNZ	CPLOOP		; Loop for # of charsNMATCH	POP	HL		; Z if match NZ if not	CALL	NOTCHK		; Reverse flag if NOT entered	JP	NZ,SKIPIT	; Skip file if no match;	LD	DE,FCB		; Point to FCB	LD	B,08HMVNAME	LD	A,(HL)		; Move name	CP	' '		; Space?	JR	Z,GOTNAM	; Go if hit one	INC	HL	LD	(DE),A		; Move to FCB	INC	DE	DJNZ	MVNAMEGOTNAM	LD	C,B		; Offset to ext field	LD	B,0	ADD	HL,BC	LD	A,(HL)		; No extension?	CP	' '	JR	Z,GOTEXT	; Go if so	LD	A,'/'		; Put in slash	LD	(DE),A	INC	DE	LD	B,03HEXLOOP	LD	A,(HL)		; Move extension	INC	HL	CP	' '		; Finished?	JR	Z,GOTEXT	LD	(DE),A	INC	DE	DJNZ	EXLOOP		; Loop till done;GOTEXT	PUSH	DE		; Save where we are	LD	HL,FNAME	; Point do destination	CALL	COPYFCB		; Move it to FCB	POP	DE		; Get FCB pointer back	LD	A,(DDRIVE)	; Check for just printing DIR	INC	A		; Set Z if FF	JR	NZ,MOVING	; Go if not FF	CALL	SHOW	JP	SKIPIT;;	Check if file exists on destination disk;MOVING	LD	A,':'		; Now put the drive separator	LD	(DE),A		;   in the FCB	INC	DE	LD	A,(DDRIVE)	; Put in drive spec	OR	'0'		; Change number to ASCII	LD	(DE),A	INC	DE	LD	HL,FCB2		; Copy to 2nd FCB	PUSH	HL		; Save 2nd FCB	CALL	COPYFCB	POP	DE		; Get FCB2 back	LD	HL,TBUFF	; Point to transfer buffer	PUSH	HL	LD	HL,$-$		; HL => SFLAG$SFLG	EQU	$-2	SET	0,(HL)		; Set the open inhibit bit	POP	HL	@@OPEN			; Do the open	LD	B,A		; Save return code	JR	Z,NORO		; Go if opened okay	CP	18H		; File not found?	JP	NZ,IOERR	; Error if not;;	Check New and Old parameters;NORO	LD	A,00H		; N or O specified?	AND	A	JR	Z,CHECKQ	; Go if neither	LD	A,(OPARM+1)	; O param given?	AND	A	JR	Z,CKNEW		; Go if not	XOR	A	OR	B		; Did file exist?	JR	Z,CHECKQ	; Go if so (ok)CKNEW	LD	A,(NPARM+1)	; N param given?	AND	A	JR	Z,GOSKIP	; Skip file if not	XOR	A	OR	B		; Be sure it was newGOSKIP	JP	Z,SKIPIT	; Go if it wasn't;;	Ask question if Q param was given;CHECKQ	LD	A,(QPARM+1)	; Check Q param	AND	A	JR	NZ,QUERY	; Query if so	LD	HL,CONVS	; "Converting...	@@DSPLY	LD	HL,FNAME	; Filename	@@DSPLY	CALL	$DSPCR		; Carriage return	JR	TAKEIT1		; Go and move it;QUERY	LD	HL,CONVQ	; "Convert file	@@DSPLY	LD	HL,QMARK	; "? "	@@DSPLY	LD	HL,ABUFF	; Get answer	LD	BC,3<8		; 3 char max	@@KEYIN	JP	C,$ABORT	; Abort if break hit	LD	A,(HL)		; Check for 'Y'	RES	5,A		; Force upper case	CP	'Y'	JP	NZ,SKIPIT	; Skip if not Y;;	If file exists, query user;	LD	A,(FCB2)	; Was file opened okay?	BIT	7,A		; Z = not found	JR	Z,TAKEIT1	; Go if it does not exist	LD	HL,EXISTQ	; "File exists, replace?	@@DSPLY	LD	HL,ABUFF	LD	BC,3<8	@@KEYIN	JP	C,$ABORT	; Abort on break	LD	A,(HL)		; Check answer	RES	5,A	CP	'Y'	JP	NZ,SKIPIT	; Skip if not 'Y';;	Init file if it didn't exist;TAKEIT1	LD	DE,FCB2	LD	A,(DE)		; Was file opened?	BIT	7,A		; Z = not opened	JR	Z,$+5		; Remove existing file	@@REMOV			;   for new LRL	LD	DE,FCB		; Use other FCB now	LD	HL,TBUFF	LD	B,(IX+04H)	; Get Model III LRL	@@INIT			; Create the file	JR	NZ,JPIOERR	; Go on error	PUSH	DE		; Change LRL to 0 for copy	EX	(SP),IX		; IX to FCB start	RES	7,(IX+01H)	; Show full sector ops	LD	(IX+09H),00H	; Show LRL = 0	EX	(SP),IX		; Switch back	POP	DE;;	Initialize to read from source file;	POP	HL		; Point to DIR entry	PUSH	HL	LD	DE,20		; Point to ERN	ADD	HL,DE	LD	E,(HL)		; Get ERN	INC	HL	LD	D,(HL)	INC	HL		; Leave pointing to extentsTRSDOS	LD	A,00H		; Version 1.3 or later?	CP	13H	JR	C,EARLY		; Go if earlier than 1.3	LD	A,(IX+03H)	; Get EOF offset	AND	A		; Zero?	JR	Z,EARLY		; No adjustment if so	INC	DE		; If non-zero, adjust ERNEARLY	LD	B,00H		; # sectors left in extent	PUSH	DE		; Save ERN	EXX			; Switch to alternate regs;;	Preallocate file;	POP	BC	LD	A,B		; Empty file?	OR	C	JR	Z,READ		; Go if so	DEC	BC	LD	DE,FCB		; Point to FCB	@@POSN			; Position to last sector	JR	Z,OK3	CP	1CH		; Ignore EOF errors	JR	Z,OK3	CP	1DH		;   or past end errorsJPIOERR	JP	NZ,IOERR	; Quit on any othersOK3	@@WRITE			; Write it	JR	NZ,JPIOERR	; Quit on write error	@@REW			; Position to start	JR	NZ,JPIOERR	; Quit on position error;;	Read sectors;READ	LD	HL,TBUFF	; Point to transfer buffer	LD	B,L		; B = 0 sectors readMYHIGH	LD	DE,$-$		; Get end of our buffer	DEC	D		; 256 bytes backGETONE	CALL	GETSEC		; Get next sector	JR	NZ,WRITE	; Go if EOF	INC	B		; Count sector	INC	H		; Next buffer page	CALL	CPHLDE		; Compare HL and DE	LD	A,00H		; No error code	JR	NC,WRITE	; Go if mem full	JR	GETONE		;   else loop for more;;	Write sectors to destination file;WRITE	PUSH	AF		; Save completion type	LD	DE,FCB		; Point to file FCB	LD	HL,TBUFF	; Point to transfer bufferWRLOOP	LD	(FCB+3),HL	; Point FCB to buffer	LD	A,B		; Zero to write?	AND	A	JR	Z,WRDUN		; Go if so	@@WRITE			; Write to file	JR	NZ,JPERR2	; Go if write error	INC	H	DJNZ	WRLOOP		; Loop until done;;	Were we at EOF?;WRDUN	POP	AF		; Restore completion type	AND	A		; At end of file?	JR	Z,READ		; Go if not;;	Copy over EOF offset;	LD	A,(IX+03H)	; Get offset from DIR	LD	(FCB+8),A	; Put into FCB	@@CLOSE			;   and close the fileJPERR2	JR	NZ,IOERR	; Quit on close error;;	Incrememnt to next entry and loop if not done;SKIPIT	POP	HL	LD	DE,48		; 48 bytes per entry	ADD	HL,DE	LD	A,L		; End of sector?	CP	0F0H	JR	NZ,NOTEOS	; Go if not	INC	H	LD	L,D		; D = 0 from aboveNOTEOS	LD	DE,TBUFF	; Done?	CALL	CPHLDE		; CP HL,DE	JP	C,ELOOP		; Loop back if not done;;	Finished;	CALL	$DSPCR		; Display blank line	CALL	BYEBYE		; Restore DCT	JP	$EXIT;;	----- dead code ----;QUIT	CALL	BYEBYE	JR	PERR2;;	Error routines;IOERR	CALL	BYEBYE		; Restore DCTIOERR1	LD	L,A		; Entry from PRMERR	LD	H,00H	OR	0C0H		; Abbrev msg, return	LD	C,A	@@ERROR	JP	$QUIT;BYEBYE	PUSH	IY		; Move back DCT	POP	DE	LD	HL,SAVDCT	; Point to save area	LD	BC,10		; 10 bytes per entry	LDIR	RET;;;PRMERR	LD	A,44		; Init "Parameter error..."	JR	IOERR1PERR1	@@LOGOT			; Display and logPERR2	JP	$ABORT;;	Sector read routine;GETSEC	EXX			; Get alternate registers	LD	A,D		; Any records left	OR	E	JR	NZ,NOTEND	; Go i fsoBDEXT	EXX	LD	A,1CH		; EOF code	AND	A		; Set NZ	RET;NOTEND	XOR	A		; Check if used up ext	OR	B	JR	NZ,MORE		; Go if not used up	LD	A,(HL)		; Check next trk #	CP	0FFH		; Non-allocated?	JR	Z,BDEXT		; Then consider EOF	PUSH	DE		; Save DE'	LD	D,(HL)		; Get track number	INC	HL	LD	B,(HL)		; Get number of grans	INC	HL	LD	A,B		; Get starting gran	RLCA			; Move to bits 0-2	RLCA	RLCA	AND	07H		; Mask off other garbage	LD	E,A		; Multiply by 3	RLCA	ADD	A,E	INC	A		; Offset from 0	LD	E,A		;   and move to E reg	LD	(TRKSEC),DE	; Save for later	POP	DE		; Restore DE'	LD	A,B		; Get number of grans	AND	1FH	LD	B,A		; Multiply by 3	RLCA	ADD	A,B	LD	B,A		; And up in B reg;;	Read sector;MORE	DEC	B		; Count down # secs in extent	DEC	DE		; Count down # records	EXX			; Restore primary registers	PUSH	DE		; Save DE	PUSH	BC		;   and BC	LD	DE,(TRKSEC)	; Get track and sector #	LD	A,(SDRIVE)	; Get source drive	LD	C,A	LD	(IY+07H),18	; Reset sec/trk each time	@@RDSEC			; Read sector to (HL)	JR	Z,OK2		; Go if no errors	CP	06H		;   or address mark differs	JP	NZ,IOERR	; Quit on any other errorOK2	INC	E		; Step to next sector	LD	A,E	CP	19D		; End of track?	JR	NZ,NOTEOT	; Go if not	LD	E,01H		; Reset to sector 1	INC	D		; Next trackNOTEOT	LD	(TRKSEC),DE	; Save track/sector	POP	BC	POP	DE	XOR	A	RET;;	Parsing subroutines;GETDRV2	LD	A,(HL)		; Get character	CP	':'		; Drivespec entered?	LD	A,0FFH		; Not entered value	RET	NZ		; If no 2nd drive, give DIR;GETDRV	LD	A,(HL)		; Parse drivespec	CP	':'		; Was it entered?	JR	NZ,PRMERR	; Go if missing	INC	HL	LD	A,(HL)		; Get drivespec	SUB	'0'		; Convert to binary	CP	08H		; Be sure it's in range	JR	NC,PRMERR	; Go if out of range	INC	HL	RET;SKIPSP	LD	A,(HL)		; Skip spaces	CP	' '	RET	NZ	INC	HL	JR	SKIPSP;SKIPLT	LD	A,(HL)		; Skip letters/digits/$	CALL	CHKLET	RET	NZ	INC	HL	JR	SKIPLT;MOVELT	LD	A,(HL)		; Move letters/digits/$	CALL	CHKLET	RET	NZ	INC	HL		; Inc source pointer	LD	(DE),A		; Store in dest	INC	DE		; Inc dest pointer	JR	MOVELT;CHKLET	BIT	7,A		; Graphic?	RET	NZ	CP	'a'		; Lowercase?	JR	C,NOTLC		; Go if not	RES	5,A		; Force upper caseNOTLC	CP	'$'		; Dollar sign?	RET	Z	CP	'0'		; Digit?	RET	C		; Return NZ if less	CP	'9'+1	JR	NC,NOTDIG	; Go if not digit	CP	A		; Mark as letter/digit/$	RETNOTDIG	CP	'A'		; Letter?	RET	C		; Return NZ if less	CP	'Z'	RET	NC		; Z if ='Z', NZ if > 'Z'	CP	A		; Z if < 'Z'	RET;CPHLDE	PUSH	HL		; Compare HL and DE	AND	A	SBC	HL,DE	POP	HL	RET;;	If NOT (-) spec given, reverse Z flag setting;NOTCHK	PUSH	AF		; Save current setting	LD	A,(NOTPRM)	; Was NOT entered?	OR	A	JR	Z,NOTNOT	; No, restore previous	POP	AF		; Get previous	JR	Z,SETIT		; Was Z, make NZ	XOR	A		;   else was NZ, make Z	RETSETIT	OR	0FFH		; Make NZ	RETNOTNOT	POP	AF		; Get previous flags	RET;;	Display Model 3 TRSDOS disk directory;SHOW	PUSH	HL		; Save registers	PUSH	DE	PUSH	BC	LD	C,00H		; Init char count	LD	HL,FNAME	; HL => nameNMDSP	LD	A,(HL)		; Get a character	CP	03H		; Are we done?	JR	Z,NMEND		; Go if we are	CALL	$DSP		; Display this char	INC	C		; Count it	INC	HL		; Point to next char	JR	NMDSP		; Loop until ETX;NMEND	LD	HL,$-$		; Get line/char countCCOUNT	EQU	$-2	LD	A,C		; Count for this entry	ADD	A,L		; Add to previous	LD	L,A		; Save position	LD	A,16		; # spaces for entry	SUB	C		; Less number used	LD	B,A		; Save remainder to BSPLP	LD	A,' '		; Pad remainder with spaces	CALL	$DSP	INC	L		; Count it	LD	A,L		; Check char position	CP	78		; End of line?	JR	Z,ELINE		; Print CR if so	DJNZ	SPLP		;   else keep going;ESHOW	LD	(CCOUNT),HL	; Save line/char position	POP	BC		; Restore regs	POP	DE	POP	HL	RET			; Done with entry;ELINE	CALL	$DSPCR		; Hit end of line	INC	H		; Bump line position	LD	L,00H		; Start at column 0	LD	A,23		; Max lines until pause	CP	H		; There yet?	JR	NZ,ESHOW	; Nope, keep going	@@KEY			; Wait for a key;	LD	A,HOME		; Cursor home	CALL	$DSP	LD	A,CLR		; Clear to end of frame	CALL	$DSP	LD	HL,0		; Restart count	JR	ESHOW;CKEARLY	NOP	LD	A,(DBUFF+22H)	; Get type byte	CP	0FFH		; Do we know this one?	RET	Z		; Okay to continue	LD	A,(DDRIVE)	; Doesn't matter if	INC	A		;   only doing DIR	RET	Z	LD	HL,EARLYD	; Error message	JP	PERR1		; Quit;;;COPYFCB	LD	A,03H		; Put EXT at end for display	LD	(DE),A	EX	DE,HL		; Destination to DE	LD	HL,FCB		; Point to FCB as source	LD	BC,32		; 32 bytes to copy	LDIR			; Move into position	RET;;	Parameter Table;PRMTBL$	DB	80H		; Version 6.x table;	DB	ABB!FLAG!5,'QUERY',00H	DW	QPARM+1;	DB	ABB!FLAG!3,'SYS',00H	DW	SPARM+1;	DB	ABB!FLAG!3,'INV',00H	DW	IPARM+1;	DB	ABB!FLAG!3,'VIS',00H	DW	VPARM+1;	DB	ABB!FLAG!3,'OLD',00H	DW	OPARM+1;	DB	ABB!FLAG!3,'NEW',00H	DW	NPARM+1;	DB	ABB!FLAG!3,'DIR',00H	DW	DPARM+1;	DB	00H		; End of table;;	Messages and data storage;NOTPRM	DB	00HPATTRN	DB	'$$$$$$$$'PATEXT	DB	'$$$'HELLO$	DB	'CONV'*GET	CLIENTNOTONE	DB	'Source and Destination drives are the same',0DHNOT0	DB	'Source cannot be drive 0',0DHEARLYD	DB	'Can''t CONV Protected Disk',0DHEXISTQ	DB	'  File exists -- replace it'QMARK	DB	'? ',03HCONVS	DB	'Converting file: ',03HCONVQ	DB	'Convert file ';FNAME	DS	32FCB	DS	32		;EQU	2BE3HFCB2	DS	32		;EQU	2C03HSDRIVE	DS	1		;EQU	2C23HDDRIVE	DS	1		;EQU	2C24HTRKSEC	DS	2		;EQU	2C25HABUFF	DS	5		;EQU	2C27HSAVDCT	DS	10		;EQU	2C2CH;	ORG	$<-8+1<+8;DBUFF	DS	1000H		;EQU	2D00HTBUFF	EQU	$		;3D00H;*LIST	ON	ENDIF;	END	BEGIN