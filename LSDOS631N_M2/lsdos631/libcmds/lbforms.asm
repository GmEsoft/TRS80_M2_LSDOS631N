;LBFORMS/ASM - FORMS command	TITLE	<FORMS - LS-DOS 6.3>;PAR_ERR	EQU	44	; Parameter error codeFLAGBT	EQU	7	; Flag byte offsetADDLF	EQU	7	; Add Line Feed = bit 0FFHARD	EQU	7	; Form Feed Hard = bit 1TABV	EQU	7	; Tab expansion = bit 2CHARS	EQU	8	; Characters per lineINDENT	EQU	6	; Indent after wrap aroundLINES	EQU	2	; Max lines to printMARGIN	EQU	9	; Left hand margin valuePAGE	EQU	0	; Max lines per pageXLATEF	EQU	4	; Translate fromXLATET	EQU	5	; Translate to;PDEF	EQU	66	; Page default = 66LDEF	EQU	66	; Line default = 66;CURON	EQU	0EH	; Cursor onCUROFF	EQU	0FH	; Cursor offSKIP	EQU	0DDH	; Skip 2 byte instruction;*GET	SVCEQU		; Get SVC macro equates*GET	VALUES		; Misc equates;	ORG	2400H;START	LD	(SAVESP+1),SP	CALL	FORMSEXIT	LD	HL,0	JR	SAVESP;;	I/O error handling;PRMERR	LD	A,PAR_ERRIOERR	LD	L,A	LD	H,00H	OR	0C0H	LD	C,A	LD	A,1AH	RST	28H	JR	SAVESP;;	Internal error message handling;NOPF	LD	HL,NOPF$	LD	A,0CH	RST	28HABORT	LD	HL,-1SAVESP	LD	SP,0	LD	A,@CKBRKC	RST	28H	RET;;	Forms - process the forms filter parameters;FORMS	CALL	DOINIT;;	Ignore leading spaces;	DEC	HLIGSPCS	INC	HL	LD	A,(HL)	CP	' '	JR	Z,IGSPCS;;	Any parameters entered?;	CP	CR+1	JR	NC,GETPRM;;	Display current parameter settings;DISPFRM	CALL	DSFORMS	CALL	DSPLY	RET;;	Display parameter error if illegal input;GETPRM	LD	DE,PRMTBL$	LD	A,11H	RST	28H	JP	NZ,PRMERR;;	Create translate from data area;	LD	A,(XTRESP)	LD	(XFRESP),A	LD	HL,XTPARM+1	LD	A,(HL)	LD	(HL),00H	LD	(XFPARM),A;;	Override all other params if <D>efaults;	LD	A,(DRESP)	OR	A	JR	Z,CHECKQ;;	Overwrite $FF data area with default values;	LD	DE,(DATAREA+2)	LD	BC,10	LD	HL,DEFTAB	PUSH	HL	PUSH	BC	LDIR	POP	BC	POP	HL	LD	DE,DUPDA	LDIR	JR	DISPFRM;;	Prompt for any parms not entered and stuff;CHECKQ	CALL	INITVAL	CALL	DSFORMS	LD	A,(QRESP)	OR	A	CALL	Z,CKCOMM	CALL	NZ,PROMPTSTUFFIN	CALL	STFPRMS	JP	EXIT;;	Display current FORMS value settings;DSFORMS	BIT	0,(IX+ADDLF)	LD	DE,SADDLF	CALL	NZ,XFERON;;	Display "OFF" if zero, or value if not 0;	LD	A,(IX+CHARS)	OR	A	LD	DE,SCHARS	CALL	NZ,HEXDEC	JR	NZ,DOFFHRD;CHAROFF	LD	HL,OFFSTR	CALL	XFERDOFFHRD	BIT	1,(IX+FFHARD)	LD	DE,SFFHARD	CALL	NZ,XFERON;;	Xfer INDENT value into string;	LD	A,(IX+INDENT)	LD	DE,SINDENT	CALL	HEXDEC;;	Transfer LINES value into string;	LD	A,(IX+LINES)	LD	DE,SLINES	CALL	HEXDEC;;	Transfer MARGIN value into string;	LD	A,(IX+MARGIN)	LD	DE,SMARGIN	CALL	HEXDEC;;	Transfer PAGE value into string;	LD	A,(IX+PAGE)	LD	DE,SPAGE	CALL	HEXDEC;;	Transfer "ON" into string if Tab set;	BIT	2,(IX+TABV)	LD	DE,STAB	CALL	NZ,XFERON;;	Is Xlate FROM = Xlate TO?;	LD	A,(IX+XLATEF)	LD	B,(IX+XLATET)	CP	B	JR	Z,NOSHOW;;	Two distinct values - convert to hex;	LD	HL,DOXLATE	LD	(HL),LF	LD	HL,SXLFROM	CALL	HEX8	LD	A,B	LD	HL,SXLTO	CALL	HEX8;;	Point HL to string and return;NOSHOW	LD	HL,VALUES	RET;;      -------------------------------------;	Check command line parameter values;      -------------------------------------;CKCOMM	LD	E,0AH	LD	IY,STRTAB;CKCOMML	LD	L,(IY+01H)	LD	H,(IY+02H);;	Set BC = Parameter response;	LD	A,(HL)	OR	A	INC	HL	LD	C,(HL)	INC	HL	LD	H,(HL)	LD	L,C	LD	C,(HL)	INC	HL	LD	B,(HL);;	Call routine to range check parameter entry;	LD	L,(IY+05H)	LD	H,(IY+06H)	LD	(CALLINS+1),HLCALLINS	CALL	NZ,$-$	JP	NZ,PRMERR;;	Position to next table entry;	LD	BC,9	ADD	IY,BC	DEC	E	JR	NZ,CKCOMML	RET;;;	PROMPT - for any vals not entered on command line;PROMPT	LD	B,10	LD	IY,STRTAB;;	Get type byte from table and set length = 1;PROMPTL	LD	A,(IY)	INC	A	LD	(FAKETAB+1),A;;	Get address of response byte;REINPUT	LD	E,(IY+01H)	LD	D,(IY+02H);;	Get the prompt string address and display it;DOPRMPT	LD	L,(IY+03H)	LD	H,(IY+04H)	CALL	DISPROM;;	Input response and stuff into param table;	CALL	INPUT	PUSH	BC	CALL	NZ,STUFVAL	POP	BC	JR	NZ,REINPUT;;	Position to next table entry;NEXTPR	LD	DE,9	ADD	IY,DE	DJNZ	PROMPTL	RET;;	DISPROM - Display prompt;DISPROM	PUSH	DE	PUSH	BC	LD	C,CUROFF	CALL	DSP	LD	B,32;PRLP	LD	C,(HL)	INC	HL	DEC	B	CALL	DSP	LD	A,C	CP	'{'	JR	NZ,PRLP	CALL	STUFDEF	LD	A,B	ADD	A,C	LD	B,A	LD	C,' ';SPLP	CALL	DSP	DJNZ	SPLP;	LD	HL,ENDPROM	CALL	DSPLY	POP	BC	POP	DE	RET;;	STUFDEF - Stuff default value in prompt;STUFDEF	LD	L,(IY+07H)	LD	H,(IY+08H)	LD	C,05HPNLP	LD	A,(HL)	INC	HL	CP	LF	JR	Z,DUNLP	CP	' '	JR	Z,PNLP	CALL	DISPA;PNLP2	DEC	C	JR	NZ,PNLP;DUNLP	LD	A,'}'DISPA	PUSH	BC	LD	C,A	CALL	DSP	POP	BC	RET;;	STUFVAL - Stuff values into param table;STUFVAL	PUSH	DE	LD	HL,FAKEPRM	LD	DE,FAKETAB	LD	A,@PARAM	RST	28H	POP	HL	RET	NZ;;	Stuff response into parameter table;	PUSH	HL	LD	A,(FAKERES)VALUE	LD	BC,0	INC	HL	LD	E,(HL)	INC	HL	LD	D,(HL)	EX	DE,HL	LD	(HL),C;;	Call range checking routine;	LD	HL,RETADR	PUSH	HL	LD	L,(IY+05H)	LD	H,(IY+06H)	JP	(HL)RETADR	POP	HL	RET	NZ	LD	(HL),80H	RET;;	--------------------------------------------------;	 STFPRMS - Stuff numeric and flag params into $FF;	--------------------------------------------------;;	Point HL to response byte addr and offset table;STFPRMS	LD	HL,RESPTABDATAREA	LD	IX,0	LD	B,07H;;	Get resp byte and offset byte to $FF data;STUFLP	LD	E,(HL)	INC	HL	LD	D,(HL)	INC	HL	LD	C,(HL)	INC	HL;	LD	A,(DE)	OR	A;;	Param entered - calulate its location;	INC	DE	EX	DE,HL	LD	A,(HL)	INC	HL	LD	H,(HL)	LD	L,A;;	Stuff param response into $FF data region;	LD	A,C	LD	C,(HL)	EX	DE,HLNOPOUT	JR	Z,NOPARM	LD	(IXINST+2),AIXINST	LD	(IX+0),C;NOPARM	DJNZ	STUFLP;;	Set flag bits in $FF data area if params set;GETFLAG	LD	B,03HFLOOP	LD	E,(HL)	INC	HL	LD	D,(HL)	INC	HL	LD	A,(DE)	OR	A	JR	Z,NEXTFLG;;	Response - if true (SET), if false (RES);	INC	DE	EX	DE,HL	LD	A,(HL)	INC	HL	LD	H,(HL)	LD	L,A	EX	DE,HL	LD	C,10000110B	; Default = RES bit inst	LD	A,(DE)	OR	A	JR	Z,SKIPSET	SET	6,C		; Change to SET instr;;	Create Post opcode for IX instruction;SKIPSET	LD	A,B	DEC	A	RLCA	RLCA	RLCA	OR	C	LD	(IXINST2+3),AIXINST2	RES	$-$,(IX+FLAGBT)	; Set/Reset bit B in $FFNEXTFLG	DJNZ	FLOOP	RET;;	------------------------------;	INITVAL - Initial Param Values;	------------------------------;INITVAL	LD	B,05H	LD	HL,RESPTAB;SDLP	LD	E,(HL)	INC	HL	LD	D,(HL)	INC	HL	LD	A,(DE);;	Get param table address - DE = (DE);	EX	DE,HL	INC	HL	LD	C,(HL)	INC	HL	LD	H,(HL)	LD	L,C	EX	DE,HL;;	Get default value from $FF data area;	PUSH	DE	PUSH	HL	LD	E,(HL)	LD	D,00H	LD	HL,(DATAREA+2)	ADD	HL,DE	LD	C,(HL)	POP	HL	POP	DE;;	If Param wasn't entered - stuff default value;	INC	HL	OR	A	JR	Z,STFDEF	LD	A,(QRESP)	OR	A	JR	Z,PRMENTSTFDEF	LD	A,C	LD	(DE),APRMENT	DJNZ	SDLP	RET;;;	Range checking code of values;;RPAGE	CALL	MORE0?	RET	NZ	LD	A,(LPARM)	DEC	A	CP	C	PUSH	AF	LD	A,(QRESP)	OR	A	JR	NZ,PQUERY	POP	AF	JR	VALID2?PQUERY	POP	AF	JR	C,SETZ	LD	A,C	LD	(DUPDA+LINES),A	LD	(LRESP),A	LD	(LPARM),A	CALL	DSFORMSSETZ	CP	A	RET;;	Is the lines printed per page valid?;RLINES	CALL	MORE0?	RET	NZ	DEC	A	LD	HL,PPARM	JR	VALID1?;;	Is the chars printed per line valid?;RCHARS	BIT	6,A	JR	NZ,SETZ	CALL	MORE0?	RET	NZ	LD	A,(QRESP)	OR	A	RET	Z;;	<Q>uery - Make sure CHARS > INDENT + MARGIN;	LD	HL,MPARM	LD	A,(IPARM)	ADD	A,(HL)	CP	C	JR	C,SETZ	XOR	A	LD	(DUPDA+INDENT),A	LD	(DUPDA+MARGIN),A	LD	(IPARM),A	LD	(MPARM),A	INC	A	LD	(MRESP),ACHNGIND	LD	(IRESP),A	CALL	DSFORMS	XOR	A	RET;;	Is margin less than characters per line?;RMARGIN	CALL	NUMERIC	RET	NZ	CALL	VALID?	RET	NZ	LD	A,(IPARM)	ADD	A,C	CALL	VALID?	RET	Z	XOR	A	LD	(IPARM),A	LD	(DUPDA+INDENT),A	INC	A	JR	CHNGIND;;	Is margin + indent less than chars per line?;RINDENT	CALL	NUMERIC	RET	NZ	LD	A,(MPARM)	ADD	A,CVALID?	LD	HL,CPARMVALID1?	CP	(HL)VALID2?	JR	NC,SETNZ	CP	A	RETSETNZ	XOR	A	INC	A	RET;;	Is the response a number between 1 and 255?;MORE0?	CALL	NUMERIC	RET	NZ	OR	A	JR	Z,SETNZ	CP	A	RET;;	Is the response a 1 byte number?;NUMERIC	AND	80H	XOR	80H	RET	NZ	INC	B	DEC	B	LD	A,C	RET;;	Is the response a flag? (ON/YES or OFF/NO);FLAG?	AND	40H	XOR	40H	RET;;;	XFER - Transfer string @ HL to DE;	XFERON - Transfer "ON" string to DE;;XFERON	LD	HL,ONSTRXFER	LD	BC,3	LDIR	RET;;;	DSP - Display a byte;;DSP	PUSH	DE	LD	A,@DSP	RST	28H	JR	EXDSP;;;	DSPLY - Display a string;;DSPLY	PUSH	DE	LD	A,@DSPLY	RST	28HEXDSP	POP	DE	RET	Z	JP	IOERR;;;	DOINIT - Sign on message and get data area;;DOINIT	PUSH	HL	LD	A,@FLAGS	RST	28H;;	Point IX to Filter Data area;	LD	DE,$FF	LD	A,@GTMOD	RST	28H	JP	NZ,NOPF;	EX	DE,HL	LD	BC,4	ADD	HL,BC	LD	(DATAREA+2),HL	LD	DE,DUPDA	PUSH	DE	LD	C,10	LDIR	POP	IX	POP	HL	RET;;;	HEXDEC - Convert hex number to decimal ascii;	A => 8 bit hex number to convert;	DE => destination of ASCII characters;;HEXDEC	PUSH	BC	PUSH	HL	PUSH	AF;;	Transfer ASCII chars into temporary buffer;	PUSH	DE	LD	DE,TEMBUF	LD	H,00H	LD	L,A	LD	A,@HEXDEC	RST	28H	DEC	DE	DEC	DE	DEC	DE	POP	HL	EX	DE,HL	LD	BC,3	LDIR;	POP	AF	POP	HL	POP	BC	RET;;;	HEX8 - Convert hex number in A to hex at HL;;HEX8	PUSH	BC	LD	C,A	LD	A,@HEX8	RST	28H	POP	BC	RET;;;	INPUT - Input a string into INBUFF$;;INPUT	PUSH	HL	PUSH	DE	PUSH	BC;	LD	BC,3<8	LD	HL,INBUFF$	LD	A,@KEYIN	RST	28H	JP	C,ABORT;	INC	B	DEC	B;	POP	BC	POP	DE	POP	HL	RET;;	Default value table;DEFTAB	DB	PDEF,0,LDEF,0,0,0,0,00000100B,0,0;;	Parameter table;PRMTBL$	DB	80H		; Ver 6.x @PARAM;	DB	FLAG!ABB!5	DB	'ADDLF'ARESP	DB	00H	DW	APARM;	DB	FLAG!ABB!NUM!5	DB	'CHARS'CRESP	DB	00H	DW	CPARM;	DB	FLAG!ABB!6	DB	'FFHARD'FRESP	DB	00H	DW	FPARM;	DB	NUM!ABB!6	DB	'INDENT'IRESP	DB	00H	DW	IPARM;	DB	NUM!ABB!5	DB	'LINES'LRESP	DB	00H	DW	LPARM;	DB	NUM!ABB!6	DB	'MARGIN'MRESP	DB	00H	DW	MPARM;	DB	NUM!ABB!4	DB	'PAGE'PRESP	DB	00H	DW	PPARM;	DB	FLAG!ABB!5	DB	'QUERY'QRESP	DB	00H	DW	QPARM;	DB	FLAG!ABB!3	DB	'TAB'TRESP	DB	00H	DW	TPARM;	DB	NUM!ABB!5	DB	'XLATE'XTRESP	DB	00H	DW	XTPARM;	DB	FLAG!ABB!7	DB	'DEFAULT'DRESP	DB	00H	DW	DPARM	DB	00H;;QPARM	DW	0CPARM	DW	0IPARM	DW	0LPARM	DW	0MPARM	DW	0PPARM	DW	0XTPARM	DW	0;APARM	DW	0FPARM	DW	0TPARM	DW	0DPARM	DW	0;XFRESP	DB	0	DW	XFPARMXFPARM	DW	0;;;	Response table - Response, Addr, $FF offset;;	8 bit numeric responses;RESPTAB	DW	CRESP	DB	CHARS	DW	IRESP	DB	INDENT	DW	LRESP	DB	LINES	DW	MRESP	DB	MARGIN	DW	PRESP	DB	PAGE	DW	XTRESP	DB	XLATET	DW	XFRESP	DB	XLATEF;;	Flag Response Table;	DW	TRESP	DW	FRESP	DW	ARESP;FAKEPRM	DB	'(F='INBUFF$	DS	12;;;	STRTAB - 10 entries each with 9 bytes;;	1 byte : Type of expected repsonse - flag or numeric;	2 bytes: Address of response byte;	2 bytes: Address of prompt string;	2 bytes: Address of routine to range check response;	2 bytes: Address of default value string;;STRTAB	EQU	$	DB	NUM		; PAGE	DW	PRESP,PPROMPT,RPAGE,SPAGE;	DB	NUM		; LINES	DW	LRESP,LPROMPT,RLINES,SLINES;	DB	NUM		; CHARS	DW	CRESP,CPROMPT,RCHARS,SCHARS;	DB	NUM		; MARGIN	DW	MRESP,MPROMPT,RMARGIN,SMARGIN;	DB	NUM		; INDENT	DW	IRESP,IPROMPT,RINDENT,SINDENT;	DB	FLAG		; ADDLF	DW	ARESP,APROMPT,FLAG?,SADDLF;	DB	FLAG		; FFHARD	DW	FRESP,FPROMPT,FLAG?,SFFHARD;	DB	FLAG		; TAB	DW	TRESP,TPROMPT,FLAG?,STAB;	DB	NUM		; XLATE from	DW	XFRESP,XPROMF,NUMERIC,SXLFROM-2;	DB	NUM		; XLATE to	DW	XTRESP,XPROMT,NUMERIC,SXLTO-2;;	Fake parameter table for prompts (QUERY);FAKETAB	DB	80H		; 6.2 @PARAM	DB	0		; Type byte	DB	'F'FAKERES	DB	00H	DW	VALUE+1		; Destination	DB	0;;;$FF	DB	'$FF',ETXONSTR	DB	' ON'OFFSTR	DB	'OFF';NOPF$	DB	'Forms Filter not Resident',CR;ENDPROM	DB	'? ',CURON,ETXVALUES	DB	'PAGE   = 'SPAGE	DB	' 66',LF,'LINES  = 'SLINES	DB	' 66',LF,'CHARS  = 'SCHARS	DB	'OFF',LF,'MARGIN = 'SMARGIN	DB	'  0',LF,'INDENT = 'SINDENT	DB	'  0',LF,'ADDLF  = 'SADDLF	DB	'OFF',LF,'FFHARD = 'SFFHARD	DB	'OFF',LF,'TAB    = 'STAB	DB	'OFF',LFDOXLATE	DB	CR,'XLATE  = X',APSXLFROM	DB	'00',AP,' => X',APSXLTO	DB	'00',AP,LF,CR;;APROMPT	DB	'Add Line Feed after C/R {'CPROMPT	DB	'Maximum Characters per Line {'FPROMPT	DB	'Real Form Feeds {'IPROMPT	DB	'Indent after Wrap-around {'LPROMPT	DB	'Lines Printed per Page {'MPROMPT	DB	'Margin Setting {'PPROMPT	DB	'Physical Page Length {'TPROMPT	DB	'Tab Expansion {'XPROMF	DB	'Xlate From {'XPROMT	DB	'Xlate To {';;	DB	' 'TEMBUF	DS	5DUPDA	DS	10;	END	START