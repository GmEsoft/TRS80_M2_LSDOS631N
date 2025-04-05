;LBRESET/ASM - RESET command	TITLE	<RESET - LS-DOS 6.3>;*GET	BUILDVER*GET	SVCEQU			; System SVC equates*GET	VALUES			; Misc equates;INH	EQU	0		; Inhibit LRL fault;	ORG	2400HRESET	LD	(SAVESP+1),SP	; Save stack pointer	IF	@BLD631	LD	A,@CKBRKC	; Check if break hit	RST	28H	JR	NZ,ABORT	; Abort if so	ENDIF	CALL	RESET0		; Call main code	LD	HL,0		; Set no error	JR	Z,SAVESP	;   and exit;;	I/O Error handling;IOERR	LD	L,A		; Move error code to HL	LD	H,00H	OR	0C0H		; Short error msg & return	LD	C,A	LD	A,@ERROR	; Log the error	RST	28H	JR	SAVESP		;   and get out;;	Internal message exit;SPCREQ	LD	HL,SPCREQ$	; "filespec required"	LD	A,@LOGOT	; Log it	RST	28H;ABORT	LD	HL,-1		; Set error flagSAVESP	LD	SP,0		; Get stack pointer back	LD	A,@CKBRKC	; Clear any BREAK hit	RST	28H	RET			;   and exit;;	RESET0 - Check command line for parameters;RESET0	IF	@BLD631	PUSH	HL		; Save command lineRESET0A	LD	A,(HL)		; Get cmd char	CP	'('		; Params?	JR	Z,GETPRMS	CP	CR+1		; End of line?	JR	C,RESET1	; Continue on	INC	HL		; Bump cmd line pointer	JR	RESET0A		;   and loop for more	ENDIF;;	Parse the command line parameters;GETPRMS	IF	@BLD631	LD	DE,PRMTBL$	; Point to param table	LD	A,@PARAM	; Parse parameters	RST	28H	JR	NZ,IOERR	; Exit on param error;;	RESET1 - Reset a filespec or devspec;RESET1	POP	HL		; Get command line back	LD	DE,FCBDEV	; Get file/device spec	LD	A,@FSPEC	RST	28H	JR	NZ,SPCREQ	; Must reset something	ELSE	LD	DE,FCBDEV	;Get file/device spec	@@FSPEC	JP	NZ,SPCREQ	;Must reset something	ENDIF	LD	A,(DE)		; File reset used to	CP	'*'		;   reset the "file open	JP	NZ,RESFIL	;   bit", LRL, or date;;	It's a device;	LD	DE,(FCBDEV+1)	; Get device name	LD	A,@GTDCB	; Find in device tables	RST	28H	RET	NZ		; NZ - device not available	PUSH	HL		; Save pointer to table	CALL	CLSFILS		; Reset routes to files	POP	HL		; Get DCB pointer	RET	NZ		; NZ -> I/O error;;	Unhook the device chain;	PUSH	HL	DI			; No interruptions, please	CALL	FIXDCB		; Fix up the DCB	EI			; Now you can interrupt	LD	HL,FCBDEV	; Determine if system	LD	D,H		;   device by attempting	LD	E,L		;   to rename it	LD	A,@RENAM	; The error code will be	RST	28H		;   either 19 or 40	POP	HL	CP	40		; Protected system device?	JR	Z,SYSDVC	LD	(HL),08H	; Show device is NIL	XOR	A		; Set Z flag	RET			; Return success;;	RESET of a system device;SYSDVC	PUSH	HL		; Save DCB pointer	INC	L		; If DCB vector is 0	LD	A,(HL)		;   then do not reset	INC	L		;   the NIL bit	OR	(HL)	POP	HL	RET	Z		; Return if vector is 0	RES	3,(HL)		; Make sure NIL is off	XOR	A		; Set Z flag	RET			;   and return;;	Reset the "file open bit" of a file;RESFIL	LD	A,@FLAGS	; Get system flags	RST	28H	SET	0,(IY+'S'-'A')	; Inhibit file open bit	LD	A,@OPEN	RST	28H	RET	NZ		; NZ -> I/O error	IF	@BLD631	PUSH	DE		; Move FCB to IX	POP	IX	LD	A,(IX+01H)	; Get protection level	AND	07H		; Mask off other bits	CP	05H		; Is it at least UPDATE?	JR	NC,ILLACC	LD	A,(LRESP)	; Get LRL response byte	AND	80H		; Must be numeric only	LD	B,A		; Save LRL flag in B	LD	A,(DRESP)	; Get Date response	AND	40H		; Must be flag only	OR	B		; Merge the two flags	JR	NZ,GOTDORL	; Got D or LCLOSEIT	SET	6,(IX+00H)	; Set close authority	LD	A,@CLOSE	;   to reset DIR bit	RST	28H	RETILLACC	LD	A,37		; "Illegal access..."	OR	A		; Set NZ status	RET			;   and return;;	Got DATE or LRL parameter(s) - handle them;GOTDORL	LD	BC,(FCBDEV+6)	; Get Drive and DEC of file	LD	A,@DIRRD	; Read dir record	RST	28H	RET	NZ		; Return on error	PUSH	HL		; Move DIRREC pointer	POP	IY		;   to IY register	LD	A,(LRESP)	; Get LRL response	AND	80H		; Is it set?	JR	Z,NOLRL		; No LRL value specifiedLPARM	LD	DE,0		; Pick up LRL value	LD	(IY+04H),E	; Store it in DIR record;;	No LRL param entered - check on date;NOLRL	LD	A,(DRESP)	; Get DATE response	AND	40H		; Is it set?	JR	Z,NODATE	; Go if not setDPARM	LD	DE,0		; Pick up DATE param	LD	(IY+12H),96H	; if DATE=N set old USER	LD	(IY+13H),42H	;   password to blank	PUSH	IX		; Save FCB pointer	LD	A,D		; Was param (DATE=N)?	OR	E		;   Z flag set if so	POP	DE		; Get FCB back in DE	SET	2,(IX+00H)	; Set the MOD flag in FCB	CALL	NZ,CLOSEIT	; Call close if needed	RET	NZ		; Return if no errorNODATE	LD	A,@DIRWR	; Write dir record back	RST	28H		;   out to disk	RET			; And return	ELSE	LD	A,(HL)		;Make sure access level	AND	7		;  is at least UPDATE	CP	5	LD	A,37		;Init "Illegal access...	RET	NZ		;NZ - I/O error	EX	DE,HL	SET	6,(HL)		;Set "close authority	EX	DE,HL		;  to reset dir bit	@@CLOSE	RET			;Return w/ condition	ENDIF;;	Find the last device route and close any open file;CLSFILS	BIT	4,(HL)		; Jump if no route	JR	Z,CLSFIL1	INC	HL		; Else get link address	LD	A,(HL)		;   and test that one	INC	HL		;   for a chain	LD	H,(HL)	LD	L,A	JR	CLSFILS;CLSFIL1	BIT	7,(HL)		; Is it a file?	RET	Z		; Return if it's not	LD	DE,FCBFIL	; Point to FCB area	PUSH	DE	LD	BC,32	LDIR			; Fill from device vector	POP	DE		; Recover start	LD	A,@CLOSE	; Close the file	RST	28H	RET			; and return with status;;	Routine to fix up a system DCB;FIXDCB	BIT	4,(HL)		; If routed, recover the	JR	Z,FIX1		;   original data from	PUSH	HL		;   DCB+3 to DCB+5	LD	D,H		; Set DE to DCB start	LD	E,LFIX0	INC	L		; Point to old stored	INC	L		;   information	INC	L	LD	BC,3	LDIR			; Transfer to DCB	POP	HL	RES	4,(HL)		; Reset routed bit	JR	FIXDCB;FIX1	BIT	5,(HL)		; If linked, recover the	JR	Z,FIX2		;   original data from	PUSH	HL		;   the link DCB source &	INC	L		;   clear the link DCB	LD	E,(HL)		; Get the link vector	INC	L	LD	D,(HL)	POP	HL		; Get the DCB pointer back	PUSH	HL	EX	DE,HL		; Link to HL, DCB to DE	PUSH	HL		; Save link for clearing	LD	BC,3	LDIR	POP	HL	LD	B,08H	IF	@BLD631FIX1A	LD	(HL),C		; Clear the link DCB	ELSEFIX1A	LD	(HL),0		;Clear the LINK DCB	ENDIF	INC	L	DJNZ	FIX1A	POP	HL		; Recover the DCB pointer	JR	FIXDCB;FIX2	BIT	6,(HL)		; If filtered, recover the	RET	Z		;   original data by	PUSH	HL		;   swapping back the	LD	D,H		;   first 3 bytes with	LD	E,L		;   the filter DCB	INC	L	LD	A,(HL)	INC	L	LD	H,(HL)	LD	L,A	LD	BC,4		; HL now points to the	ADD	HL,BC		;   entry point.  Get its	LD	C,(HL)		;   DCB address by peeking	INC	C		;   past the name field	ADD	HL,BC	LD	A,(HL)		; Get low order	INC	HL	LD	H,(HL)		; Get high order	LD	L,A	PUSH	HL		; If DCB is itself, then	SBC	HL,DE		;   bring in the NIL	POP	HL	JR	Z,FIX0	LD	B,03H		;   else swap the 1st threeFIX2A	LD	C,(HL)		;   bytes of the DCBs	LD	A,(DE)	LD	(HL),A	LD	A,C	LD	(DE),A	INC	L	INC	E	DJNZ	FIX2A	POP	HL	JR	FIXDCB;;	Parameter Table;	IF	@BLD631PRMTBL$	DB	80H		; Ver 6.x param table;	DB	NUM!ABB!3	DB	'LRL'LRESP	DB	00H	DW	LPARM+1;	DB	FLAG!ABB!4	DB	'DATE'DRESP	DB	00H	DW	DPARM+1	DB	00H	ENDIF;;	The error message;SPCREQ$	DB	'Device spec required',0DH;	IF	.NOT.@BLD631	DC	32,0		;Patch space	ENDIFFCBDEV	DB	0	DS	31FCBFIL	DB	0	DS	31;	END	RESET