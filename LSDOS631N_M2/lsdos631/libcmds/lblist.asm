;LBLIST/ASM - List command	TITLE	<LIST - LS-DOS 6.3>;*GET	BUILDVER*GET	SVCEQU			; DOS SVC equates*GET	VALUES			; Misc equates;	ORG	2400HSTART	LD	A,@CKBRKC	RST	28H	JR	Z,LISTA	LD	HL,-1	RET;;	Break not hit - Execute module;LISTA	LD	(SAVESP+1),SP	CALL	LISTSAVESP	LD	SP,$-$	LD	A,@CKBRKC	RST	28H	RET;;	I/O Error processing - display and abort;IOERR	LD	H,00H	LD	L,A	OR	0C0H	LD	C,A	LD	A,@ERROR	RST	28H	JR	SAVESP;;	Internal error message display routine;SPCREQ	LD	HL,SPCREQ$	LD	A,@LOGOT	RST	28HABORT	LD	HL,-1	JR	SAVESP;;	LIST - List a file in hex or ASCII;LIST	CALL	RESKFL;;	Find parameter entries if existant;	PUSH	HLFPLP	LD	A,(HL)	CP	'('	JR	Z,GETPRM	CP	CR+1	JR	C,RESTPTR	INC	HL	JR	FPLP;;	Process any parameters entered;GETPRM	LD	DE,PRMTBL$	LD	A,@PARAM	RST	28H	JP	NZ,IOERRRESTPTR	POP	HL;;	Skip command line blanks;IGSPC	LD	A,(HL)	INC	HL	CP	' '	JR	Z,IGSPC	DEC	HL;;	Check if filespec is in legal format;	LD	DE,FCB1	LD	A,@FSPEC	RST	28H	JP	NZ,SPCREQ;;	If this is a device, don't list it;	LD	A,(DE)	CP	'*'	JP	Z,SPCREQ;;	Save original filespec;	EX	DE,HL	LD	DE,FCB2	LD	BC,20H	PUSH	HL	LDIR	POP	DE;;	Stuff default extension of /TXT to source;	LD	HL,TXTEXT	LD	A,@FEXT	RST	28H;;	Open the file with LRL of 256;	LD	B,00H	CALL	OPEN	JR	Z,INITLRL;;	Error - was it "file not found"?;	CP	18H	JP	NZ,IOERR;;	Open orignal filespec instead of TXT;	LD	C,32	PUSH	DE	PUSH	HL	LD	HL,FCB2	LDIR	POP	HL	POP	DE;;	Open original filespec without extension	CALL	OPEN	JP	NZ,IOERR;;	Pick up the DEC from the FCB;INITLRL	PUSH	DE	POP	IX	LD	B,(IX+07H)	LD	C,(IX+06H)	LD	A,@DIRRD	RST	28H;;	Was the LRL parameter specified?;	LD	A,(LRESP)	OR	A	JR	NZ,SKIPLRL;;	No LRL parameter - get it from the directory;	LD	A,L	ADD	A,04H	LD	L,A;;	Get LRL and put it in LRL parameter;	LD	A,(HL)	LD	(LPARM+1),A;;	Get LRL and put it into the FCB;SKIPLRL	LD	A,(LPARM+1)	LD	(IX+09H),A	SET	7,(IX+01H);;	Check if TAB (T) parameter is flag or value;	LD	A,(TRESP)	AND	40H	LD	A,(TPARM+1)	JR	Z,NOTFLG;;	Flag response - Chec if it's on (T=8) or off (T=1);	INC	A	JR	NZ,NOTFLG	LD	A,08H;;	Get TAB (T) param value and put it in routine;NOTFLG	LD	(TABEXP+1),A	DEC	A	CP	32	LD	A,PAR_ERR	JP	NC,IOERR;;	Was the PRINT (P) parameter entered?;PPARM	LD	BC,$-$	LD	A,B	OR	C	JR	Z,HPARM	IF	@BLD631	LD	(NSPARM+1),BC		; Force non-stop	ENDIF;;	Stuff the @PRT svc into the output routine;	LD	A,@PRT	LD	(PUTOUT1+1),A;;	Hex parameter entered?;HPARM	LD	BC,$-$	LD	A,B	OR	C	JP	NZ,RPARM;;	Do some initialization;	LD	(BYTCTR),A	IF	@BLD631	LD	(KILLCLS),A	; Kill the @CLS call	LD	A,17H		; 23	LD	(NSPR01+1),A	LD	(NSPR02+1),A	ENDIF;;	Routine to list a file in ASCII;LINPRM	LD	BC,1	DEC	BC	LD	A,B	OR	C	JR	Z,BGNLIN	LD	DE,FCB1;;	Ignore all lines until specified start position;FND1ST	LD	A,@GET	RST	28H	JP	NZ,IOERR	CP	CR	JR	NZ,FND1ST;;	Finished with line - decrement the LINE count;	DEC	BC	LD	A,B	OR	C	JR	NZ,FND1ST;;	Start listing the file;BGNLIN	LD	HL,(LINPRM+1)	LD	BC,VARDOT	CALL	CVTDEC;;	Read in a character from the file;GETCHR	LD	DE,FCB1	LD	A,@GET	RST	28H	JR	NZ,GOTERR	LD	(PUCHAR+1),A;;	Test if NUM parameter was entered;NPARM	LD	BC,$-$	LD	A,B	OR	C	JR	Z,PUCHAR;;	N param entered - print line num and increment it;	LD	HL,VARDOT	PUSH	HL	CALL	PUTLINE	POP	HL	CALL	INCNUM;;	Pick up character and check if high bit is set;PUCHAR	LD	A,00HDLOOP	RLCA;;	Reset high bit unless A8 parameter entered;A8PARM	LD	DE,$-$	INC	D	DEC	D	JR	NZ,A8BIT	SRL	A	DB	1EHA8BIT	RRCA;;	Is the character a tab?;	PUSH	AF	CP	TAB	JR	NZ,NOTTAB;;	Character is a tab - was T=N specified?;TPARM	LD	DE,8	INC	E	DEC	E	JR	Z,NOTTAB;;	Get column # and calc # spaces to pad;	LD	A,(BYTCTR)TABEXP	LD	C,08HCLOOP	SUB	C	JR	NC,CLOOP	NEG;;	Output REG-A blank spaces for tab expansion;	LD	B,ATP1	LD	A,' '	CALL	PUTOUT	DJNZ	TP1	JR	WASTAB;;	Character was not a tab, display it;NOTTAB	CALL	PUTOUTWASTAB	LD	A,(BYTCTR)	OR	A	CALL	Z,CKPAWS;;	Check for pause if hi bit set on character;	POP	AF	CALL	C,CKPAWS;;	If character = C/R then read in another line;	CP	CR	JR	Z,GETCHR;;	Get another byte from the file;	LD	DE,FCB1	LD	A,@GET	RST	28H	JR	Z,DLOOP;;	I/O Error on @GET - output a carriage return;GOTERR	PUSH	AF	LD	A,CR	CALL	PUTOUT	POP	AF;;	If end of file error - exit normally;	LD	HL,$-$	CP	1CHGTBK	JP	Z,SAVESP	CP	1DH	JR	Z,GTBK	JP	IOERR;;	List a file in HEX format;RPARM	LD	BC,$-$	LD	DE,FCB1	LD	A,@POSN	RST	28H	JP	NZ,IOERR;;	Reset byte counter to zero;DOHEX	XOR	A	LD	(DOHEX1+1),A	LD	DE,(RPARM+1)	LD	HL,VARCLN+1	LD	A,@HEX16	RST	28H;;	Bump record number and stuff into RPARM;	INC	DE	LD	(RPARM+1),DE;LPARM	LD	BC,$-$;;	Convert byte counter to hex and stuff in buffer;DISBYTE	PUSH	BCDOHEX1	LD	C,00H	LD	HL,VAREQU	LD	A,@HEX8	RST	28H	POP	BC;;	Display record number / starting byte string;	LD	HL,VARCLN	CALL	PUTLINE;;	Get byte counter and add 16 (BPL) and save it;	LD	A,(DOHEX1+1)	LD	B,10H	ADD	A,B	LD	(DOHEX1+1),A;	LD	HL,LINBUF;;	Get a byte from the file;DOHEX2	LD	DE,FCB1	LD	A,@GET	RST	28H	JR	Z,DOHEX4;;	End of file error?;	PUSH	AF	CP	1CH	JR	Z,DOHEX3;;	Past end of file error?;	CP	1DH	JP	NZ,IOERR;;	Recover flags and check type of error;DOHEX3	POP	AFDOHEX4	JR	NZ,DOHEX5;;	Stuff character in buffer and bump;	LD	(HL),A	INC	HL;;	Output byte in hex and follow with a space;	CALL	CVTHEX	LD	A,' '	CALL	PUTOUT;;	Outptu an extra space if halfway in the line;	LD	A,B	CP	09H	CALL	Z,WR1SPA;;	Dec chars per line # num chars left in rec;	DEC	B	DEC	C	JR	Z,DOHEX5;;	Finished with line?;	LD	A,B	OR	A	JR	NZ,DOHEX2;;	Finished with line or logical record;DOHEX5	PUSH	AF	LD	A,B	CP	10H	JR	Z,PRTLIN2;;	Display ASCII equivalent of line;	PUSH	BC;;	Multiply # chars not printed by three;	LD	A,B	ADD	A,A	ADD	A,B	LD	B,A;;	Add two extra spaces if more than halfway;	CP	27	CCF	LD	A,01H	ADC	A,B;;	Position to ASCII portion of the line;	LD	B,A	CALL	WRSPA	POP	BC;;	Calculate number of characters to print;	LD	A,10H	SUB	B	LD	B,A	LD	HL,LINBUF	PUSH	BC	LD	C,08H;;	Display ASCII part of the line;PRTLIN1	LD	A,(HL)	INC	HL	CALL	CVTDOT	DEC	C	CALL	Z,WR1SPA	DJNZ	PRTLIN1	POP	BC;;	End of line - output a C/R and check for EOF;PRTLIN2	LD	A,CR	CALL	PUTOUT	POP	AF	LD	A,1CH	JP	NZ,GOTERR;	CALL	CKPAWS;;	Are we done with the record?;	LD	A,C	OR	A	JP	NZ,DISBYTE;;	Finished with the record - output space and CR;	LD	A,' '	CALL	PUTOUT	LD	A,CR	CALL	PUTOUT;;	Increment line number;	LD	HL,VARCLN	CALL	INCNUM	JP	DOHEX;;	CVTDOT - Output chars & convert non-printables;CVTDOT	CP	' '	JR	C,CVTDOT1	CP	7FH	JR	C,PUTOUTCVTDOT1	LD	A,'.'	JR	PUTOUT;;	CVTHEX - convert A to hex ASCII and output it;CVTHEX	PUSH	AF	RRCA	RRCA	RRCA	RRCA	CALL	CVTH1	POP	AF;CVTH1	AND	0FH	ADD	A,90H	DAA	ADC	A,40H	DAA;;	PUTOUT - Output a byte to *DO or *PR;PUTOUT	PUSH	BC	LD	C,A;;	Output the byte to the appropriate device;PUTOUT1	LD	A,@DSP	RST	28H	JP	NZ,IOERR;;	Increment the byte counter;	PUSH	HL	LD	HL,BYTCTR	INC	(HL)	IF	@BLD631	LD	A,(HL)	SUB	80	JR	C,NOT80C	LD	(HL),A;NOT80C	LD	A,C	SUB	10	JR	Z,WASLFCR	SUB	03H	JR	NZ,NOTLFCRWASLFCR	LD	(HL),ANOTLFCR	INC	(HL)	DEC	(HL)	POP	HL	POP	BC	RET	NZ;;	Check on Non-stop (NS) parameter;NSPARM	LD	DE,$-$		; Get non-stop param	LD	A,D		; Is it non-zero?	OR	E	RET	NZ		; Return if it's notNSPR01	LD	A,11H		; 17 (gets 23?)	DEC	A		; Decrement it	LD	(NSPR01+1),A	; Save it back	RET	NZ		; Return if not zero	LD	A,@KEY		; Wait for a key	RST	28H	CP	80H		; Break?	JP	Z,GOTBRK	; Got break - exit	SUB	'C'		; Continuous?	JR	Z,STUFCNT	; Go if Continuous	SUB	20H		; Lower case "c"?	JR	NZ,DOCLS	; Go if it wasn'tSTUFCNT	LD	(NSPARM+1),DEDOCLS	LD	A,@CLS		; Clear the screenKILLCLS	RST	28HNSPR02	LD	A,11H	LD	(NSPR01+1),A	RET	ELSE	LD	A,C		;P/u byte	CP	CR		;End of line ?	JR	NZ,NOTCR	;No - rest regs & RETurn;	LD	(HL),0		;Reset byte counterNOTCR	POP	HL		;Restore registers	POP	BC	RET			;  & RETurn	ENDIF;;	Output B spaces to display or printer;WRSPA	CALL	WR1SPA	DJNZ	WRSPA	RET;;	Output a space to display or printer;WR1SPA	LD	A,' '	JR	PUTOUT;;	PUTLINE - Output a line to display or printer;	HL => line of data to be output;PUTLINE	LD	A,(HL)	INC	HL	CP	ETX	RET	Z	CALL	PUTOUT	IF	.NOT.@BLD631	CP	CR		;Check for CR	RET	Z		;  return if so	ENDIF	JR	PUTLINE;;	CKPAWS - Check for pause (Shift-@);CKPAWS	LD	A,@FLAGS	RST	28H;;	Was the break key pressed?;	LD	A,@CKBRKC	RST	28H	JR	NZ,GOTBRK;;	Was SHIFT-@ pressed?;	BIT	1,(IY+0AH)	RET	Z;;	Pause - wait for a key to continue;CKWAIT	LD	A,@KEY	RST	28H	CP	60H	JR	Z,CKWAIT	CP	80H	JR	Z,GOTBRK;;	Reset <PAUSE> and <ENTER> bits and return;RESKFL	LD	A,@FLAGS	RST	28H	LD	A,(IY+KFLAG$)	AND	0F9H	LD	(IY+KFLAG$),A	RET;;	BREAK key hit - display a C/R and abort;GOTBRK	LD	A,CR	CALL	PUTOUT	JP	ABORT;;	CVTDEC - Convert HL to decimal and stuff in BC;CVTDEC	LD	DE,10000	CALL	CVD1	LD	DE,1000	CALL	CVD1	LD	DE,100	CALL	CVD1	LD	DE,10	CALL	CVD1	LD	DE,1;;	Divide quotient in HL by value in DE;CVD1	XOR	ACVD2	SBC	HL,DE	JR	C,CVD3	INC	A	JR	CVD2;;	Add divisor to neg rem and convert A to ASCII;CVD3	ADD	HL,DE	ADD	A,'0'	CP	'0'	JR	NZ,CVD4;;	Char is a zero - use space if leading zero;	DEC	BC	LD	A,(BC)	INC	BC	CP	' '	JR	Z,CVD4	LD	A,'0';;	Stuff numeric ASCII character into buffer;CVD4	LD	(BC),A	INC	BC	RET;;	INCNUM - Increment line number in buffer (HL);INCNUM	INC	HL	INC	HL	INC	HL	INC	HL;;	Loop to increment digit and return if done;INCNUM1	LD	A,(HL)	OR	'0'	INC	A	LD	(HL),A	SUB	'9'+1	RET	C	LD	(HL),'0'	DEC	HL	JR	INCNUM1;;	OPEN - Open a file;OPEN	LD	A,@FLAGS	RST	28H	SET	0,(IY+SFLAG$)	LD	HL,IOBUFF	LD	A,@OPEN	RST	28H	RET;;	Messages;SPCREQ$	DB	'File spec required',CRVARDOT	DB	'     . ',03HVARCLN	DB	' '	DB	'    :'VAREQU	DB	'XX =  ',03HTXTEXT	DB	'TXT';;	Parameter table;PRMTBL$	DB	80H	DB	FLAG!6	DB	'ASCII8'	DB	00H	DW	A8PARM+1;	DB	FLAG!2	DB	'A8'	DB	00H	DW	A8PARM+1;	DB	NUM!4	DB	'LINE'	DB	00H	DW	LINPRM+1;	IF	@BLD631;	NUM (N) - Flag input only ;	DB	FLAG!3	ELSE;	NUM (N) - Flag input only;	DB	FLAG!ABB!3	ENDIF	DB	'NUM'	DB	00H	DW	NPARM+1;	IF	@BLD631;;	NS (N) - Flag input only	DB	FLAG!ABB!2	DB	'NS'	DB	00H	DW	NSPARM+1	ENDIF;	DB	FLAG!ABB!3	DB	'HEX'	DB	00H	DW	HPARM+1;	DB	NUM!ABB!3	DB	'REC'	DB	00H	DW	RPARM+1;	DB	NUM!ABB!3	DB	'LRL'LRESP	DB	00H	DW	LPARM+1;	DB	FLAG!1	DB	'P'	DB	00H	DW	PPARM+1;	DB	FLAG!ABB!3	DB	'TAB'TRESP	DB	00H	DW	TPARM+1	DB	00H;BYTCTR	DS	1LINBUF	DS	16FCB1	DS	32FCB2	DS	32;	ORG	$<-8+1<+8;IOBUFF	DS	256;	END	START