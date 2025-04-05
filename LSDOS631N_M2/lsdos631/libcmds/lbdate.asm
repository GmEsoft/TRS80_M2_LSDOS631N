; LBDATE/ASM - Date/Time commands	TITLE	<DATE/TIME - LSDOS 6.3>;*GET	BUILDVER*GET	SVCMAC*GET	LOWCORE/EQU;CR	EQU	13@ADTSK	EQU	29	; Add task SVC@RMTSK	EQU	30	; Remove task SVCCLK_SLT	EQU	5	; Clock task slot #;;;	DATE$ storage;; DATE$+0	Year; DATE$+1	Day of month (1-31); DATE$+2	Month (1-12); DATE$+3	Bits 0-7 of day of year; DATE$+4	Bit 0 = bit 8 of day of year;		Bits 1-3 contain day of week;		Bit 7 set if leap year;;	TIME$ Storage;; TIME$+0	Seconds	(0-59); TIME$+1	Minutes	(0-59); TIME$+2	Hours	(0-23);;	ORG	2400H;;	Branch to time entry point;	JP	TIME;	SUBTTL	'<LBDATE - DATE Code>';DATE	@@CKBRKC		; Break key down?	JR	Z,BEGINA	; Okay if not	LD	HL,-1		;   else abort	RET;;	DATE - Pick up DATE$+0 pointer & stuff in IY;BEGINA	PUSH	HL		; Save command pointer	LD	HL,DUMBUF	@@DATE	POP	HL		; Get cmd ptr back	PUSH	DE		; Xfer ptr to IY	POP	IY;;	Was a date entered on the command line?;	LD	A,(HL)		; Get char	CP	CR+1		; Date entry?	JP	C,DSPDATE;;	Date entered - check if legal format;	LD	C,'0'		; Init separator	CALL	PARSDAT	JP	NZ,BADFMT;;	Legal date - if Intl date, swap DTBUF$+1 & 2;	IF	@INTL	INC	DE		; DE => DTBUF+1	LD	H,D		; HL => DTBUF+1	LD	L,E	LD	C,(HL)		; C = Intl month	INC	HL		; HL => DTBUF+2	LD	A,(HL)		; A = Intl day	LD	(DE),A		; Set DTBUF+1 = day	LD	(HL),C		; Set DTBUF+2 = month	DEC	DE		; DE => DTBUF+0	ELSE	DC	9,0		; Pad US ver to match Intl	ENDIF;;	Is the year legal?;	LD	A,(DE)		; Get year entry	IF	@BLD631	IF	@BLD631L	CP	50H		; 0 through 79?	ELSE	CP	0CH		; 0 through 11?	ENDIF	JR	NC,NOT2000	; Go if not	ADD	A,100		; Adjust it to 2000 range	LD	(DE),A		; Save value back	ENDIFNOT2000	SUB	80		; Allow 1980-2011	JP	C,BADFMT	; Go if less then 1980	IF	@BLD631	IF	@BLD631L	CP	100		; <=2079	ELSE	CP	32		; <=2011	ENDIF	ELSE	CP	20		; >99 ?	ENDIF	JR	NC,BADFMT2	; Jump if bad;;	If Year is 1980 or 84 then set FEB = 29 days;	AND	03H		; Leap year?	LD	HL,MAXDAYS+2	; Point to Feb	JR	NZ,NOTLEAP	; Go if not	INC	(HL)		; Set Feb to 29 days;;	Check range of month - must be 1-12;NOTLEAP	LD	A,(DTBUF+2)	; Get month	DEC	A		; Set month = 0-11	CP	12		; Valid month?	JR	NC,BADFMT2	; Abort if 0 or > 12;;	Valid month, point HL to max days / month;	DEC	HL		; Point to Max day table	ADD	A,L		; Add month # to start	LD	L,A		; HL => max days for month;;	Check for Day entry validity;	LD	A,(DTBUF+1)	; Get day entry	DEC	A		; Reduce for test	CP	(HL)		; More than max days?BADFMT2	JP	NC,BADFMT	; Go if too large (or 0);;	Transfer date into buffer;	EX	DE,HL		; Point HL to DTBUF	PUSH	IY		; Point DE to DATE$	POP	DE	LD	C,3		; 3 bytes to move	LDIR;;	Display "No date in system" message;DSPDATE	LD	A,(IY+2)	; Get month	LD	HL,NODATE$	OR	A		; Better not be 0	JP	Z,LOGABRT	; Log and abortGOTDATE	LD	B,A		; Xfer month to B	LD	HL,MAXDAYS+2	LD	A,(HL)	SUB	29	JR	Z,PUDAY;;	Pick up year & inc max days if leap year;	LD	A,(IY)		; Get year	AND	03H		; Leap year?	JR	NZ,PUDAY	INC	(HL);;	Set HL = # day this month, DE => Max table;PUDAY	LD	L,(IY+1)	; Get day # this month	LD	H,00H	LD	DE,MAXDAYS;;	Loop to count up total # days up to now;DAYLP	LD	A,(DE)	ADD	A,L	LD	L,A	ADC	A,H	SUB	L	LD	H,A	INC	DE	DJNZ	DAYLP;;	Stuff days (9 bits) into DATE$;	LD	(IY+3),L	; Store low byte	LD	A,H		; Get bit "8"	OR	(IY+4)		; Merge in rest	LD	(IY+4),A	;   and put it back;;	Get year in E;	LD	A,(IY)		; Get year	SUB	80		; Offset from 80	LD	E,A	ADD	A,3		; Ck for year >= 84	RRCA	RRCA	IF	@BLD631	IF	@BLD631L	AND	3FH		; Keep bits 0-5	ELSE	AND	0FH		; Keep bits 0-3	ENDIF	ELSE	AND	7		;Keep bits 0,1,2	ENDIF	ADD	A,E		; Add back to year	LD	E,A		; And save in DE	LD	D,00H	ADD	HL,DE		; Add to days in year	INC	HL		; To start in right place;;	HL = desired # to divide by 7;	LD	BC,7		; Now divide by 7	XOR	ADIV7	SBC	HL,BC		; Subtract weeks	JR	NC,DIV7		;   until underflow;;	Correct # for division, & put in bits 1-3;	LD	A,L	ADD	A,8		; Add back to get 1-7	LD	B,A		; Save day of week	RLCA			; Shift to bits 1-3	LD	C,A		;   to store in DATE$;;	Merge day of week with bit 9 of day of year;	LD	A,(IY+04H)	; Get date$+4	AND	0F1H		; Keep year & bit 0	OR	C		; Merge day of week	LD	(IY+04H),A	; Save it back;;	Transfer day string into display buffer;	LD	HL,DAYTBL	; HL => Day string table	LD	DE,DATEBUF	; Date display buffer	PUSH	DE		; Save start	CALL	DSPMDY		; Write out the day;;	Position DE to month destination in buffer;	INC	DE	INC	DE;;	Get month & stuff  string into buffer;	LD	A,(IY+02H)	; Get month	LD	B,A		; Stuff in B	LD	HL,MONTBL	; HL => Month string table	CALL	DSPMDY		; Write out the month name;;	Get day of month & convert to ASCII;	INC	DE		; DE => Day destination	LD	A,(IY+01H)	; Get day	LD	B,-1		; Init # of tens to -1;;	Divide day of month by 10;DIV10	INC	B		; Divide by 10	SUB	10		; With quotient in B	JR	NC,DIV10	; Subtract until carry;;	Convert tens digit to ASCII;	PUSH	AF		; Save 10-remainder	LD	A,B		; Get quotient	ADD	A,'0'		; Change to ASCII;;	Change to space if leading zero;	CP	'0'		; Zero?	JR	NZ,NOTLD0	; No, use it	LD	A,' '		; Convert to spaceNOTLD0	LD	(DE),A		; Stuff in buffer;;	Convert remainder to ASCII & stuff in buffer;	INC	DE		; DE => Ones destination	POP	AF		; Get remainder back	ADD	A,3AH		; Convert to ascii	LD	(DE),A		; Store it;;	Get year & stuff it;	LD	A,(IY)		; Get year	IF	@BLD631	LD	HL,1900		; Base year	ADD	A,L		; Add them	LD	L,A		; do stuff	ADC	A,H	SUB	L	LD	H,A		; HL now holds year	LD	DE,DATEBUF+12	; Point to year string	@@HEXDEC		; Convert to ASCII	ELSE	SUB	80		;A = 0-19	CP	10		;In 1980's?	JR	C,WAS80	LD	B,A	LD	A,'9'		;Nope, 1990's	LD	(DATEBUF+15),A	LD	A,B		;Get back year offset	SUB	10		;Sub off decadeWAS80	ADD	A,'0'		;Make ascii	LD	(DATEBUF+16),A	;Stuff year	ENDIF;;	Set B=0 (normal exit);LOGDT	LD	B,00H		; B=0 for normal exit	POP	HL		; HL => Date/Time string;;	Display date or time string;LOGMSG	PUSH	BC		; Save err #, B (exit)	@@LOGOT			; Log message	POP	BC;;	If B=0 then exit HL=0 else HL=-1;	LD	H,B		; Set HL to -1 or -	LD	L,B	@@CKBRKC		; Clear any break	RET			; Return with conditioning;;	Bad format - display error and abort;BADFMT	LD	HL,BADDAT$	; Illegal date/timeLOGABRT	LD	B,-1		; Abort condition	JR	LOGMSG		; Log message;	SUBTTL	'<LBDATE - TIME code>'	PAGE;TIME	@@CKBRKC		; Break key down?	JR	Z,BEGINB	; Okay if not	LD	HL,-1		;   else abort	RET;;	TIME entry point - any parms entered?;BEGINB	PUSH	HL		; Save pointerTLOOP	LD	A,(HL)		; Get char	CP	'('		; Any params?	JR	Z,GETPRMS	; Yes - get them	CP	CR		; End of line?	JR	Z,CLRSTK	; Yes - go check time	INC	HL		; Bump pointer	JR	TLOOP		; Do til terminator;;	Process any parameters;GETPRMS	LD	DE,PRMTBL$	; DE => Parameter table	@@PARAM			; Get parameters;;	Stuff "Illegal time" msg in error routine;CLRSTK	LD	HL,BADTIM$	; Chg "Bad date format"	LD	(BADFMT+1),HL	;   to "Bad time format"	POP	HL		; Get cmd ptr back	JR	Z,GDPARMS	; Z - okay to continue;;	Parameter error - display and abort;IOERR	LD	L,A		; Xfer err code to HL	LD	H,00H	OR	0C0H		; Short err msgs	LD	C,A		; Xfer to C	@@ERROR	RET;;	Was there a TIME string entered?;GDPARMS	LD	A,(HL)		; Get character	CP	'('		; Params only?	JP	Z,DSPTIME	; Display old time	CP	CR		; End of line?	JP	Z,DSPTIME	; Display old time;;	Requested time set - check if legal format;	XOR	A	LD	(PRSERC+1),A	LD	(DTBUF),A;;	The above three lines new in 6.3;	LD	C,'0'		; Init separator	CALL	PARSDAT		; Parse entry	JR	NZ,BADFMT	; Bad - abort;;	Legal format - check if hours are legal;	LD	HL,DTBUF+2	; HL => Hours byte	LD	A,23		; Greater than 23?	CP	(HL)	JR	C,BADFMT	; Yes - bad format;;	Hours legal - check if minutes legal;	DEC	HL		; Point to minutes	LD	A,59		; Greater than 59	CP	(HL)	JR	C,BADFMT	; Yes - bad format;;	Minutes legal - check if seconds legal;	DEC	HL		; Point to seconds	CP	(HL)		; Greater than 59?	JR	C,BADFMT	; Yes - bad format;;	Legal input - transfer to TIME$ storage area;	PUSH	HL		; Save time buffer ptr	LD	HL,DUMBUF	; HL => Dummy buffer	@@TIME			; Get TIME$ into DE	POP	HL		; Get time ptr back	LD	BC,3		; 3 bytes to move	LDIR			; Do it;;	Was the CLOCK (C) parameter entered?;DOCLOCK	LD	HL,0		; HL = 0 (normal exit)	LD	A,(CRESP)	; Get response flag	OR	A		; Set?	RET	Z		; Return if not;;	CLOCK (C) parameter entered - ON of OFF;CLOCK	LD	DE,$-$		; Parm - FFFF or 0000	@@FLAGS			; Get FLAGS in IY;;	Just set/reset CLOCK bit if Model IV version;	IF	@MOD4	SET	4,(IY+'V'-'A')	; Set clock bit	INC	E		; Return if CLOCK=YES	RET	Z		;	RES	4,(IY+'V'-'A')	;  otherwise reset bit	DEC	E		; Set Z flag	RET			; Done - return	ENDIF;;	Also add or remove task if Model II version;	IF	@MOD2	RES	4,(IY+'V'-'A')	; Reset clock bit	LD	C,CLK_SLT	; Set C = Clock Slot #	LD	A,@RMTSK	; Remove task SVC	INC	E		; Clock off?	JR	NZ,CLOFF	; Yes, remove taskCLON	LD	DE,DO_CLOCK	; Clock on - DE => Address	SET	4,(IY+'V'-'A')	; Set clock bit	LD	A,@ADTSK	; Add task SVCCLOFF	RST	28H	XOR	A		; Set Z for no error	LD	H,A		; Pass to HL for	LD	L,A		;   normal exit	RET	ENDIF;;	Display the time;DSPTIME	LD	HL,DATEBUF+9	; Put to space for time str	PUSH	HL		; Save pointer	@@TIME			; Xfer time into buffer	CALL	DOCLOCK		; Set/Reset clock bit	JP	LOGDT		; Log it and exit;	SUBTTL	'<LBDATE - DATE/TIME Common Routines>'	PAGE;;	DSPMDY - Xfer 3 char string from table to buffer;;	B  => Entry # in table to display;	HL => Table to fetch data from;	DE => Buffer to receive string;DSPMDY	DEC	B		; B = entry # (0-6)	LD	A,L		; Get LSB of table start	ADD	A,B		; Entries are 3 bytes long	ADD	A,B		; Adjust for position	ADD	A,B	LD	L,A		; HL => Table entry;;	Transfer string into buffer;	LD	B,3		; Three chars to xferDSPM1	LD	A,(HL)		; Get char	LD	(DE),A		; Stuff in buffer	INC	HL		; Bump pointers	INC	DE	DJNZ	DSPM1		; Done - return	RET;;	PARSDAT - Parse TIME/DATE string entry;;	HL => Buffer containing string to parse;	C  => Delimiter (<"0" = DATE, <"0" or =":" = time;;	DTBUF-DTBUF+2 <= Data in compressed format;	Z <= set if successful;PARSDAT	LD	DE,DTBUF+2	; Point to buf end	LD	B,03H		; Process three bytes;;	Parse a field - return NZ if bad;PRS1	PUSH	DE		; Save pointer	CALL	PRS2		; Get a digit pair	POP	DE		; Get pointer back	RET	NZ		; Ret if bad digit pair;;	Good field - stuff in buf, dec ptr & count;	LD	(DE),A		; Stuff the value	DEC	B		; Loop countdown	RET	Z		; Do for 3 fields	DEC	DE		; Backup the pointer;;	Parsed a field - is the separator valid?;	LD	A,(HL)		; Get separator	INC	HL		; Bump pointer	CP	':'		; Check for ':'	JR	Z,PRS1		; Loop if so	CP	C		; Correct?	JR	NC,PRSRET	; NC = bad	CP	0DH		; Enter?	JR	NZ,PRS1		; Loop if notPRSERC	LD	A,0FFH		; Set Z or NZ	OR	A	JR	NZ,PRSRET	; Return;;	Ignore seconds if not entered;	LD	A,B		; Get count	DEC	A		; Last one?	RET	Z		; Return if soPRSRET	OR	A		; Set error flag	RET			; and return;;	PRS2 - Parse a pair of digits at HL;PRS2	CALL	PRS4		; Get a digit	JR	NC,PRS3		; Illegal - return;;	Legal digit - multiply by 10;	LD	E,A		; Multiply by 10	RLCA			; * 2	RLCA			; * 4	ADD	A,E		; * 5	RLCA			; * 10	LD	E,A		; Save in E;;	Get another digit;	CALL	PRS4		; Get ones digit	JR	NC,PRS3		; Bad - return NZ;;	Legal add to tens digit and set Z flag;	ADD	A,E		; Accumulate new digit	LD	E,A		; Save 2 digit value	CP	A		; Set Z flag	RET			; And return;;	Force NZ & return;PRS3	OR	A		; Set NZ	RET			; Return;;	Pick up a digit and convert to binary;PRS4	LD	A,(HL)		; Get digit	INC	HL		; Bump pointer	SUB	'0'		; Convert to binary	CP	10		; Legal?	RET			; Return;;	Parameter table;NUM	EQU	80H		; Numeric parameterFLAG	EQU	40H		; Flag parameterSTR	EQU	20H		; String parameterABB	EQU	10H		; Abbreviations allowed;PRMTBL$	DB	80H		; Ver 6.x param table;	DB	FLAG!ABB!5,'CLOCK'CRESP	DB	00H	DW	CLOCK+1	DB	0;	ORG	$<-8+1<+8;DAYTBL	DB	'SunMonTueWedThuFriSat'MONTBL	DB	'JanFebMarAprMayJunJulAugSepOctNovDec'DATEBUF	DB	'Day, Mon xx, 198x',CRMAXDAYS	DB	0,31,28,31,30,31,30,31,31,30,31,30,31NODATE$	DB	'Date not in system',CRBADDAT$	DB	'Bad Date format',CRBADTIM$	DB	'Bad Time format',CR;;DTBUF	EQU	$DUMBUF	EQU	$+3;	END	DATE