;LBDO/ASM - Library 'DO' command	TITLE	<DO - LS-DOS 6.3>;JFCB$	EQU	0C0H		; Low core EQU*;;SMALL	EQU	0CR	EQU	13*GET	BUILDVER*GET	SVCEQU			; SVC equates;	ORG	2400H;DO	EQU	$;;	Note: The first 80 bytes (until PARSINP) are;	uses as a line buffer during processing.;JCLBUF2	EQU	$	LD	(SPSAV+1),SP	; Save stack pointer;	IF	SMALL	JR	NOCPLS		; No compile if small	ENDIF	LD	(INBUF+1),HL	; Save start of command*LIST OFF	IFEQ	SMALL,0*LIST ON	LD	A,@FLAGS	; Get flag table pointer	RST	28H	LD	A,(HL)	CP	'*'		; Execute last DO file?	JP	Z,NOCPL2	CP	'='		; Execute without compile?	JP	Z,NOCPL	CP	'$'		; Compile only?	JR	NZ,GETSPEC	LD	(NOEXEC?+1),A	INC	HL	LD	A,(HL)	CP	' '		; Bypass space separator	JR	NZ,GETSPEC	;   if present	INC	HLGETSPEC	LD	DE,DOFCB	; Get DO filespec	LD	A,@FSPEC	RST	28H	JP	NZ,SPCREQ	; Go if bad/missing filespec	PUSH	HL		; Save INBUF$ pointer	IF	@BLD631	CALL	DEFEXT		; Set default extension	ELSE	LD	HL,SYSJCL+7	;Default ext to "/JCL"	LD	A,@FEXT	RST	28H	ENDIF	LD	HL,INPBUF	; Open DO file	LD	B,L		; LRL = 256	SET	0,(IY+'S'-'A')	; Inhibit file open bit	LD	A,@OPEN	RST	28H	JP	NZ,IOERR;	IF	@BLD631;;	Look for a drive available to put SYSTEM/JCL on;	LD	C,-1		; Start checking at 0DRVLOOP	INC	C		; Increment drive number	LD	A,C		; Move it to A	CP	08H		; Too far?	JP	NC,DSKFUL	; Go if so;	LD	A,@CKDRV	; Check drive available	RST	28H	JR	NZ,DRVLOOP	; Loop if drive not ready	JR	C,DRVLOOP	;   or if write protected	LD	A,C		; Get drive number	ADD	A,'0'		; Convert to ASCII	IF	@BLD631G	CALL	SETDRV		; Stuff it in filename	ELSE	LD      (DRVNUM),A	; Set drive number in filespec	ENDIF	ENDIF;	CALL	MOVFCB		; Move system/jcl into FCB	LD	DE,JFCB$	; Init FCB pointer	LD	HL,OUTBUF;;	Try to open output file;	LD	A,@INIT	RST	28H	JP	NZ,DSKFUL	; Jump on error	POP	HL		; Get inbuf$ ptr back;;	Routine to parse a command line;PARSINP	LD	A,(HL)		; Get line char	CP	CR		; End of line?	JP	Z,TSTLBL	INC	HL		; Bump pointer	CALL	CKSPCOM		; Ignore spaces and commas	JR	Z,PARSINP	CP	'('		; Beginning of params?	JP	Z,PARAM	CP	';'		; Line continuation?	JP	NZ,PRMERR	LD	C,'?'		; Prompt for line continue	LD	A,@DSP	RST	28HINBUF	LD	HL,0		; Input continuation line	DEC	L		; Backup to start	DEC	L	LD	BC,79<8		; Max 79 chars input	LD	A,@KEYIN	RST	28H	JP	C,PRMERR	; Jump if break	LD	A,@LOGER	; Log the line	RST	28H	JR	PARSINP		; Go parse it;;	Routine to move to a higher level nest;UNNEST	LD	HL,(NESTPTR)	; Shift the last nest's	DEC	HL		;   FCB into FCB area	LD	DE,DOFCB+31	LD	BC,32	LDDR	INC	HL	LD	(NESTPTR),HL	; Reset current FCB ptr	LD	DE,DOFCB	; Reread last sector of	LD	A,@RREAD	;   nested FCB	RST	28H	IF	@BLD631	RET	Z		; Return on no errorJPIOERR	JP	IOERR		; Else go	ELSE	JP	NZ,IOERR	RET	ENDIF;CKNEST	LD	HL,(NESTPTR)	; Get current FCB pointer	LD	DE,NESTFCB	; Is it the first nest?	XOR	A	SBC	HL,DE	JR	Z,CPLFIN	; Jump if so & exit	CALL	UNNEST		;   processing	JP	CPLJCL;;	Finished compilation - Close 'er up;CPLFIN	LD	DE,JFCB$	; Close SYSTEM/JCL file	LD	A,@CLOSE	RST	28H	IF	@BLD631	JR	NZ,JPIOERR	ELSE	JP	NZ,IOERR	ENDIFNOEXEC?	LD	A,00H		; Set to non-zero on	OR	A		;   compile only	LD	HL,0	RET	NZ		; Exit on compile only	ENDIF*LIST ON;CPLFIN1	LD	DE,JFCB$	; Point to SYSTEM/JCL FCB	LD	HL,0		; Correct bufptr later	LD	B,L		; LRL = 256	SET	0,(IY+'S'-'A')	; Inhibit file open bit	LD	A,@OPEN		; Open it up	RST	28H	IF	@BLD631	JR	NZ,JPIOERR	; Jump on error	ELSE	JP	NZ,IOERR	; Jump on error	ENDIF	LD	BC,(JFCB$+6)	; Get SBUFF$	LD	A,@DIRRD	RST	28H	LD	A,H		; Stuff high order to	LD	(JFCB$+4),A	;   use for JFCB$ buffer	LD	A,9DH		; Call SYS11, entry 1	RST	28H;;	Process execution without compilation;NOCPL	INC	HLNOCPLS	LD	A,(HL)		; Bypass space separator	CP	' '		;   if present	JR	Z,NOCPLNOCPL1	LD	DE,JFCB$	; Fetch DO filespec	LD	A,@FSPEC	RST	28H	JP	NZ,SPCREQ	; Jump on error	IF	@BLD631	CALL	DEFEXT		; Set default extension	ELSE	LD	HL,SYSJCL+7	; Default to /JCL	LD	A,@FEXT	RST	28H	ENDIF	JR	CPLFIN1		; Go execute file*LIST OFF	IFEQ	SMALL,0*LIST ONNOCPL2	CALL	MOVFCB		; Execute SYSTEM/JCL	JR	CPLFIN1		;   file;;;MOVFCB	LD	HL,SYSJCL	; Move SYSTEM/JCL into	LD	DE,JFCB$	;   FCB areaMVFCB01	LD	BC,32	LDIR	RET;;	Found a parameter entered;PARAM	CALL	PARSNAM		; Parse symbol -> current	JR	NZ,PARAM1	; Jump if bad symbol	PUSH	AF		; Save separator charFNDLBL	LD	A,00H		; Test if a label	OR	A		;   was found	JR	NZ,MOVLBL	CALL	FINDSYM		; Search symbol table	JP	Z,MULDEF	; Multiple definition if in	CALL	MOVNAME		; Add symbol to table	POP	AF		; Get separator back	CP	'='		; Assignment?	JR	Z,PARAM2PARAM1	CALL	CKSPCOM		; Ck space or comma	JR	Z,PARAM	CP	')'		; Exit param scan on	JP	Z,PARSINP	;   closing paren	CP	CR		; Also accept closing CR	JR	Z,TSTLBL	JP	PRMERR		; Else param error;PARAM2	CALL	PARSVAL		; Parse value into buffer	PUSH	AF		; Save separator char	CALL	MOVALUE		; Symbol value into tableGETSEP	POP	AF		; Recover separator	JR	PARAM1		; Loop;MOVLBL	PUSH	HL	LD	HL,CURSYM	; Point to curr sym buf	LD	DE,LBLSAV	;   & save label for	LD	BC,8		;   later testing	LDIR	XOR	A		; Turn off "found label"	LD	(FNDLBL+1),A	POP	HL		; Get line ptr back	JR	GETSEP		; And go back for more;;	Got to end of JCL command line;TSTLBL	LD	A,(GOTLBL+1)	; Was @LABEL a param?	OR	A	JR	Z,CPLJCL	; If not, don't look;;	Find the procedure block named @LABEL;FINDLBL	CALL	RDJCL		; Read JCL line	JR	Z,GOTLIN	; Go if line read	LD	HL,(NESTPTR)	; See if nested	LD	DE,NESTFCB	;   in an include file	XOR	A	SBC	HL,DE	JP	Z,NOFIND	; If not, label not found	CALL	UNNEST		;   else continue search	JR	FINDLBL;GOTLIN	LD	HL,JCLBUF1	; Point to start	LD	A,(HL)		; Is 1st char a label	CP	'@'		;   indicator?	JR	NZ,FINDLBL	; Back for more if not;;	Found a label - is it the one we want?;	INC	HL		; Point to 1st char	EX	DE,HL		; Move pointer to DE	LD	HL,LBLSAV	LD	BC,808H		; Symbol & field len = 8	CALL	FNDPRM		; A match?	JR	NZ,FINDLBL	; No match?  Look for next	JR	CPLJCL		;   else this is the one;CONDCPL	CALL	TSTCONDCPLJCL	CALL	RDJCL		; Read line from JCL file	JP	NZ,CKNEST	; Exit on end of file	LD	HL,JCLBUF1	; Parse the line just read	LD	DE,JCLBUF2	LD	A,(HL)	INC	HL	CP	'@'		; End procedure if found	JP	Z,CKNEST	;   another label	CP	'/'		; Slash?	JR	NZ,CPLJCL1	CP	(HL)		; Double slash?	JP	Z,MACRO		; Jump on double slash;;	Modification for HEX string;CPLJCL1	CP	'#'		; Substitution?	JR	Z,CPLJCL4	CP	'%'		; Hex value?	JR	NZ,CPLJCL2	; Back to take char if not	CALL	CPLJCL7		; Go test double %	JR	CPLJCL3;CPLJCL7	CP	(HL)		; Double %?	JR	Z,CPLJCL6	CALL	CVRTHEX		; Convert digit	INC	HL		; Bump to next char	RLCA	RLCA	RLCA	RLCA			; Rotate into left nybble	LD	C,A		; Save for now	CALL	CVRTHEX		; Convert 2nd digit	OR	C		; Merge left nybble	JR	CPLJCL6CPLJCL2	LD	(DE),A		; Nothing special, transfer	INC	DE	CP	CR	JR	Z,CONDCPL	; Exit on end of lineCPLJCL3	LD	A,(HL)		; Get next input char	INC	HL	JR	CPLJCL1		;   and loopCPLJCL4	CALL	CPLJCL5		; Check on double '#'	JR	CPLJCL3		; Substitute if not '##'CPLJCL5	CP	(HL)		; Double #?	JR	NZ,SUBSYM	; Jump to substitute ifCPLJCL6	INC	HL		;   only single #	LD	(DE),A		;   else transfer char	INC	DE	RET;CVRTHEX	LD	A,(HL)		; Get the digit	SUB	'0'		; Start conversion	JR	C,CVRTHE1	; Error if < 0	CP	10	RET	C		; Go if 0-9	RES	5,A		; Force upper case	SUB	7		; Adjust A-F > 10-15	CP	16	RET	C		; Go if 10-15CVRTHE1	JR	BADHDR;;	Symbol substitution routine;SUBSYM	PUSH	HL	PUSH	DE	CALL	PARSNAM		; Parse symbol	CP	'#'		; Must have closing '#'	JR	NZ,BADHDR	; Bad format if not	EX	(SP),HL		; Put new pos on stack	PUSH	HL		;   & get HL=start pos	CALL	FINDSYM		; Get symbol value	JR	NZ,SUBSYM1	; Bypass if not in table	LD	A,(DE)		; Get symbol length	OR	A	JR	Z,SUBSYM1	; Bypass if zero length	LD	B,00H	LD	C,A	INC	DE		; Point to 1st symbol char	POP	HL		; Recover where we need to	EX	DE,HL		;   substitute, then move	LDIR			;   symbol value into pos	POP	HL	POP	AF	RET;SUBSYM1	POP	DE		; Symbol not in table, so	POP	AF		;   leave as is in the DO	POP	HL		;   file.	LD	A,'#'		; Starting #SUBSYM2	LD	(DE),A	INC	DE		; Inc buffer ptr	LD	A,(HL)		; Get char from line	INC	HL	CP	CR		; If a CR before closing #	JR	Z,BADHDR	;   then abort	CP	'#'		; End of substitution?	JR	NZ,SUBSYM2	; Get more if not	LD	(DE),A	INC	DE	RET;;	Check if conditional is at top level;CKCOND	LD	DE,(CONDPTR)	; Get conditional pointer	LD	HL,CONDFLG	; Test if still on 1st one	XOR	A	SBC	HL,DE	EX	DE,HL		; Pointer back to HL	RET	NZ		; Okay if nested, else error;;	Output invalid JCL format message;BADHDR	LD	DE,BADHDR$+5	; Show bad JCL line found	LD	HL,(LINENO)	; Put decimal line #	LD	A,@HEXDEC	;   into message	RST	28H	LD	HL,BADHDR$	; Display bad line #	LD	A,@LOGOT	RST	28HBADH1	LD	HL,BADJCL$	;   and abort message	JP	EXTERR;;	Compile a "//" line;MACRO	INC	HL	CALL	PARSNAM		; Get symbol value	JR	NZ,MACRO2	; Go if not JCL macro	CALL	CK4COND		; Chk for IF,ELSE,END	PUSH	DE		; Stack the routine entry	RET	Z		;   & branch if found	POP	DE		;   else remove RET &...;;	Test the conditional logic state;	LD	DE,(CONDPTR)	; Get conditional pointer	LD	A,(DE)		;   and conditional state	OR	A	JP	NZ,CPLJCL	; Jump if logical FALSE	CALL	CK4ASSN		; Test for SET, RESET,				;   ASSIGN, INCLUDE, QUIT	PUSH	DE		; Stack the routine entry	RET	Z		;   and branch if found	POP	DEMACRO2	LD	DE,JCLBUF1	; Point to where we left	XOR	A		;   off and continue to	SBC	HL,DE		;   parse the input line	LD	B,H		;   from the JCL file	LD	C,L	LD	HL,JCLBUF1	LD	DE,JCLBUF2	LDIR	JP	CPLJCL3;;	Read a line from the JCL file;RDJCL	LD	HL,(LINENO)	; Bump line counter	INC	HL	LD	(LINENO),HL	LD	HL,JCLBUF1	; Point to line buffer	LD	DE,DOFCB	; Point to FCB	LD	B,80		; Max of 80 charsRDJCL1	LD	A,@GET		; Get a char	RST	28H	JR	NZ,RDJCL2	; Go on error	OR	A	JR	Z,RDJCL3	; Bypass on null byte	LD	(HL),A		; Move byte to line buffer	INC	HL	CP	CR		; End of line?	RET	Z	DJNZ	RDJCL1		; Loop if not;;	If falls through, line was too long;	LD	(HL),CR		; Stuff C/R & provide	LD	HL,LINLNG$	;   error log message	LD	(BADH1+1),HL	JR	BADHDR;RDJCL2	CP	1CH		; EOF?	JP	NZ,IOERR	; Jump on any other errorRDJCL3	LD	A,1CH	OR	A	RET;;	Act on JCL line if conditional state = TRUE;TSTCOND	LD	HL,(CONDPTR)	; Grab conditional pointer	LD	A,(HL)		; Get conditional state	OR	A	RET	NZ		; Return if logical FALSE	LD	HL,JCLBUF2	; Point to processed line	LD	DE,JFCB$	; SYSTEM/JCL FCB	LD	A,(HL)		; Check on double /	CP	'/'	JR	NZ,WRCPLD	; Done if not /	INC	HL	CP	(HL)		; Check for double /	DEC	HL	JR	NZ,WRCPLD	; Jump if not //	LD	A,(JCLBUF2+2)	; Check on comment	CP	'.'		; "//." found?	JR	NZ,WRCPLD	; Bypass if not comment	LD	A,@DSPLY	; Else display the comment	RST	28H	RET;;	Write compiled line to SYSTEM/JCL;WRCPLD	LD	C,(HL)		; Get a character	LD	A,@PUT		; Write it out	RST	28H	JP	NZ,IOERR	; Jump on error	LD	A,(HL)		; Grab again to test	INC	HL		; Bump pointer	CP	CR		; End if line?	JR	NZ,WRCPLD	; Loop if not	RET;;	Parameter tables;CONDTBL	DB	'IF   '	DW	IF01	DB	'ELSE '	DW	ELSE1	DB	'END  '	DW	END1	DB	00H		; End of table;ASSNTBL	DB	'SET     '	DW	SET1	DB	'RESET   '	DW	RESET1	DB	'ASSIGN  '	DW	ASSIGN	DB	'INCLUDE '	DW	INCLUD	DB	'QUIT    '	DW	QUIT	DB	00H		; End of table;;	Process IF command;IF01	CALL	IF05		; Parse expression	JR	Z,IF02		; Z=true, NZ=false	CP	CR		; False & end of line?	JR	Z,IF03	CP	'+'		; Logical OR?	JR	Z,IF01;;	Test for FALSE  and logical AND (&);	CP	'&'		; Separator AND?	JR	NZ,BADHDR0	; Invalid format if notIF01A	INC	HL		; Ignore rest of line	LD	A,(HL)	CP	CR	JR	NZ,IF01A	JR	IF03;IF02	XOR	A		; Logic = true	JR	IF04;IF03	LD	A,0FFH		; Logic = falseIF04	LD	HL,(CONDPTR)	; Get conditional pointer	OR	(HL)		; Set logic state	INC	HL		; Bump pointer	LD	(HL),A		; Stuff state result	LD	(CONDPTR),HL	; Save pointer	JR	GOJCL;;	Process ELSE command;ELSE1	CALL	CKCOND		; Check nest of conditional	LD	A,(HL)		; Flip state of flag based	CPL			;   on previous test	DEC	HL	OR	(HL)		; OR in previous state	INC	HL	LD	(HL),A		; Save new value	JR	GOJCL;;	Process END command;END1	CALL	CKCOND		; Check nest level	DEC	HL		; Back up conditional one	LD	(CONDPTR),HL	;   level & reset pointer	JR	GOJCL;;	Parse conditional expression logic;IF05	CALL	IF06		; Get if symbol is true	RET	NZ		;   or false & ret if false	CP	'&'		; Logical AND separator?	JR	Z,IF05		; If TRUE AND -> chk next	XOR	A		; TRUE and not AND,	RET			;   return TRUE;IF06	LD	A,(HL)	CP	'-'		; Logical NOT?	JR	NZ,IF08	INC	HL		; Bypass '-'	CALL	IF08		; Grab symbol logic state	JR	NZ,IF07		; Z=true, NZ=false	DB	0F6H		; Was true, not => falseIF07	XOR	A		; Was false, not => true	LD	A,B		; Recover separator	RET;IF08	CALL	PARSNAM		; Get symbol name into buf	RET	NZ		; Ret if bad symbol	PUSH	AF	PUSH	HL	CALL	FINDSYM		; Find symbol in table	POP	HL	POP	BC	LD	A,B		; Put zero in A & use flag	RET			;   from search;;	Process the SET command;SET1	CALL	PARSNAM		; Parse symbol nameBADHDR0	JP	NZ,BADHDR	; Jump if bad symbol	CALL	FINDSYM		; Find in table	CALL	NZ,MOVNAME	; Move name into tableGOJCL	JP	CPLJCL;;	Process the RESET command;RESET1	CALL	PARSNAM		; Parse symbol name	JR	NZ,BADHDR0	CALL	FINDSYM		; Find symbol in table	JR	NZ,GOJCL	; No problem if not there	LD	HL,-8		; Point to start of name	ADD	HL,DE		;   and put in a blank	LD	(HL),' '	;   to remove symbol	JR	GOJCL;;	Process ASSIGN command;ASSIGN	CALL	PARSNAM		; Parse symbol name	JR	NZ,BADHDR0	; Jump on bad name	PUSH	AF		; Save separator char	CALL	FINDSYM		; Find in table	CALL	NZ,MOVNAME	; Add to table if not in	POP	AF		; Get separator back	CP	'='		; Error if not '='	JR	NZ,BADHDR0	CALL	PARSVAL		; Parse value of symbol	JR	NZ,BADHDR0	CALL	MOVALUE		; Place value into table	JR	GOJCL;;	Process INCLUDE command;INCLUD	PUSH	HL	LD	DE,(NESTPTR)	; Point to next FCB save	LD	HL,NESTEND	;   area & check if room	XOR	A		;   to store another FCB	SBC	HL,DE	JP	Z,NESTS		; Error if 5 nests already	LD	HL,DOFCB	; Shift curr FCB into	IF	@BLD631	CALL	MVFCB01		;   INCLUDE FCB save area	ELSE	LD	BC,32		;  INCLUDE FCB save area	LDIR	ENDIF	LD	(NESTPTR),DE	; Update new nest pointer	POP	HL	LD	DE,DOFCB	; Point to FCB	LD	A,@FSPEC	; Fetch included file	RST	28H	JR	NZ,BADHDR0	; Jump on error	IF	@BLD631	CALL	DEFEXT		; Set default ext of /JCL	ELSE	LD	HL,SYSJCL+7	;Default to /JCL	LD	A,@FEXT	RST	28H	ENDIF	LD	HL,INPBUF	; Open the included file	LD	B,L	SET	0,(IY+'S'-'A')	; Inhibit file open bit	LD	A,@OPEN	RST	28H	JR	NZ,BADHDR0	JR	GOJCL;;	Process the QUIT command;QUIT	LD	HL,JCLBUF1	; Log the //QUIT line	JP	EXTERR;;	Parse symbol name;	A <= Separator char;	Z  = ok, NZ = bad symbol char;PARSNAM	PUSH	DE	LD	B,8		; 8 chars max	LD	DE,CURSYM	; Symbol buffer area	CALL	PARSER		; Parse it	POP	DE	RET;;	Parse a symbol value;PARSVAL	PUSH	DE	LD	B,32		; 32 chars max	LD	DE,VALBUF	; Value buffer	CALL	XFRSTR		; Transfer from input	PUSH	AF	PUSH	HL	EX	DE,HL		; Calculate length of	LD	DE,VALBUF	;   the string	XOR	A	SBC	HL,DE	LD	A,L	CP	33	JP	NC,TOOLNG	; Jump if > 32 chars	LD	(STRLEN),A	; Stuff string length	POP	HL	POP	AF	POP	DE	RET;;	Transfer a string field;XFRSTR	CALL	PARSER		; Xfer max of 32 charsXFRSTR1	CALL	CKSPCOM		; Return on space	RET	Z		;   or comma	CP	CR	RET	Z		; Return on end of line	CP	'='	RET	Z		; Return on '='	CP	'('	RET	Z		; Return on left paren	CP	')'	RET	Z		; Return on right paren	CP	'#'	JR	NZ,XFRSTR	; Loop if not #	CALL	CPLJCL5		; Check on substitution	LD	A,(HL)	JR	XFRSTR1		; Then loop;;	Parse a field;PARSER	LD	A,B		; Set max length of field	LD	(PAR6+1),A	INC	BPAR2	LD	A,(HL)		; Get entry char	CP	03H		; ETX?	JR	Z,PAR5	CP	CR		; Carriage return?	JR	Z,PAR5	INC	HL		; Not ending char, bump ptr	CP	'"'		; Check on string quote	JR	NZ,NOTQT	XOR	'"'		; Chk if opening or closingSTUFQT	EQU	$-1	LD	(STUFQT),A	JR	PAR2		; Loop until terminatorNOTQT	LD	C,A		; Save char & test if	LD	A,(STUFQT)	;   within quoted string	OR	A	LD	A,C		; Get the char back	JR	Z,PAR3		; Allow all within "...";	CP	'@'		; Start of a label?	JR	NZ,NOLBLGOTLBL	SUB	00H		; Make sure only one	JP	Z,LBLERR	LD	(GOTLBL+1),A	; Stuff '&' into test	LD	(FNDLBL+1),A	;  and also for check	JR	PAR2		; Loop through start;NOLBL	CP	'.'		; Accept (./0-9:)	JR	C,PAR5	CP	':'+1	JR	C,PAR3	CP	'A'		; Test for A-Z	JR	C,PAR5	CP	'Z'+1	JR	C,PAR3	CALL	CKLCA2Z		; Test for a-z	JR	C,PAR5PAR3	DEC	B		; Char count down	JR	Z,PAR4	LD	(DE),A		; Save the char	XOR	A		; Show we found at	LD	(PAR6+1),A	;  least one valid char	INC	DE		; Bump receiving buffer	JR	PAR2		; Loop;PAR4	INC	B		; Ignore trailing chars	JR	PAR2;PAR5	LD	C,A		; Found char out of range	PUSH	DE		; Save currend end of buff	JR	PAR5B;PAR5A	LD	A,' '		; Fill out remaining field	LD	(DE),A		;   with blanks	INC	DEPAR5B	DJNZ	PAR5A	POP	DE		; Recover pointer to lastPAR6	LD	A,00H		; char xfered, get max len	OR	A		; Note if we found a char	LD	A,C		; Xfer separator char	RET;;	Transfer symbol name to table and init value;MOVNAME	PUSH	HL	LD	HL,CURSYM	; Current symbol buffer	LD	BC,8		; 8 chars to move	LDIR	XOR	A		; Zero accumulator	LD	(DE),A		; Show symbol length = 0	LD	HL,33		; Point to 1st byte	ADD	HL,DE		;   of next symbol pos and	LD	(HL),A		;   show it spare	POP	HL	RET;;	Place symbol value into table;MOVALUE	PUSH	HL	LD	HL,STRLEN	; Current value buffer	LD	BC,33		; Length & value	LDIR	POP	HL	RET;;	Find symbol in table;FINDSYM	PUSH	HL	LD	DE,CURSYM	; Symbol buffer	LD	HL,SYMTAB	; Start of table	LD	BC,8<8!41	; CP8, Field (8,1,32)	CALL	FNDPRM		; Search in progress	LD	D,H		; Xfer pointer of symbol	LD	E,L		;   or to spare slot	POP	HL	RET;;	Routine to check for IF, ELSE and END;CK4COND	PUSH	HL	LD	HL,CONDTBL	; Param table	LD	BC,5<8!7	; 5 chars, 7 char field	JR	CK4AS1;;	Check on SET, RESET, ASSIGN, INCLUDE and QUIT;CK4ASSN	PUSH	HL	LD	HL,ASSNTBL	; Param table	LD	BC,8<8!10	; Param len, field lenCK4AS1	LD	DE,CURSYM	; Buffer area	CALL	FNDPRM		; Check for match	LD	E,(HL)		; Transfer vector address	INC	HL	LD	D,(HL)	POP	HL	RET;;	Scan parameter table for match;FNDPRM	LD	A,(HL)		; End of param table	OR	A	JR	NZ,FND1		; Jump if not	INC	A		;   else show not found	RETFND1	LD	A,(DE)		; Char match?	CALL	CKLCA2Z		; Convert a-z to A-Z	CP	(HL)	JR	Z,FND3		; Jump if 1st matchesFND2	PUSH	BC		;   else bypass complete	LD	B,00H		;   field & go to next one	ADD	HL,BC	POP	BC	JR	FNDPRMFND3	PUSH	HL		; 1st matches, check rest	PUSH	DE	PUSH	BC	DEC	B		; Adjust for 1st matchFND4	INC	DE	INC	HL	LD	A,(DE)	CP	' '	JR	Z,FND7		; Stop checking on space	CP	CR	JR	Z,FND7		;   or end of line	CALL	CKLCA2Z		; Convert to upper case	CP	(HL)		; Compare remaining chars	JR	NZ,FND6		; Jump on mismatch	DJNZ	FND4		; Loop to countFND5	POP	BC		; Must have matched	POP	DE		; Bypass remaining part	POP	HL		;   of field and point to	PUSH	BC		;   address vector of param	LD	C,B		;   in param table	LD	B,00H	ADD	HL,BC	POP	BC	XOR	A	RETFND6	CP	'0'		; No match, is it ASCII?	JR	C,FND7	CP	'9'+1		; 0-9?	JR	C,FND8	CP	'A'		; A-Z?	JR	C,FND7	CP	'Z'+1	JR	C,FND8FND7	LD	A,(HL)		; If table entry also a	CP	' '		;   space, we have a match	JR	Z,FND5FND8	POP	BC	POP	DE	POP	HL	JR	FND2	ENDIF;;	Routine to check on space or comma;CKSPCOM	CP	' '		; Space?	RET	Z	CP	','	RET;;	Routine to convert a-z to A-Z and set C flag;CKLCA2Z	CP	'a'		; Back with C flag if	RET	C		;   not a-z	CP	'z'+1	CCF	RET	C	XOR	20H		; Force U/C and reset CF	RET*LIST ON;;;	Error processing;IOERR	LD	L,A		; Move err num to HL	LD	H,00H	OR	0C0H		; Set brief, return	LD	C,A	LD	A,@ERROR	; Display error	RST	28H	JR	ERREXIT;SPCREQ	LD	HL,SPCREQ$	; Filespec required;*LIST OFF	IFEQ	SMALL,0*LIST ON	DB	0DDHNESTS	LD	HL,NESTS$	DB	0DDHTOOLNG	LD	HL,TOOLNG$	; Symbol too long	DB	0DDHNOFIND	LD	HL,NOFIND$	; Proc not found	DB	0DDHLBLERR	LD	HL,LBLERR$	; Too many proc labels	DB	0DDHDSKFUL	LD	HL,DSKFUL$	; can't create system/jcl	DB	0DDHPRMERR	LD	HL,PRMERR$	; Parameter error	DB	0DDHMULDEF	LD	HL,MULDEF$	; mult definition	ENDIF*LIST ON;EXTERR	LD	A,@LOGOT	RST	28H	LD	HL,-1		; Set error exitERREXIT	LD	DE,JFCB$	; If the output JCL file	LD	A,(DE)		;   is open, then we need	BIT	7,A		;   to close it	JR	Z,SPSAV	LD	A,@CLOSE	RST	28HSPSAV	LD	SP,$-$	RET;	IF	@BLD631DEFEXT	LD	HL,DFLTEX$	; Default to /JCL	LD	A,@FEXT	RST	28H	RET	ENDIF;*LIST OFF	IFEQ	SMALL,0*LIST ONDOFCB	DS	32CURSYM	DS	8STRLEN	DS	1VALBUF	DS	32LBLSAV	DS	8	NOP			; Must be zero!	ENDIF;*LIST ONLINENO	DW	0		; JCL Line numberSYSJCL	DB	'SYSTEM/'DFLTEX$	DB	'JCL'	IF	@BLD631		;Since 6.3.1	IF	@BLD631G	;Since 6.3.1G	DB	3	ELSE			;Pre-6.3.1G	DB	':'	ENDIF;	@BLD631GDRVNUM	DB	'0',3	ENDIF;	@BLD631SPCREQ$	DB	'File spec required',CR*LIST OFF	IFEQ	SMALL,0*LIST ONLINLNG$	DB	'Line too long',CRTOOLNG$	DB	'Symbol string too long',CRNOFIND$	DB	'Procedure not found',CRLBLERR$	DB	'Too many Proc labels',CRDSKFUL$	DB	'Can',27H,'t create SYSTEM/JCL file',CRMULDEF$	DB	'Multiply defined 'PRMERR$	DB	'Parameter error',CR	IF	@BLD631GBADJCL$	DB	'Bad JCL format, process aborted',CR;SETDRV	LD	H,A		; Stuff drive number	LD	L,':'		; into system/jcl	LD	(DRVNUM-1),HL	; filename	RET			; and return;	ELSEBADJCL$	DB	'Invalid JCL format, processing aborted',CR	ENDIF;NESTS$	DB	'Too many nested INCLUDEs',CRNESTPTR	DW	NESTFCB		; Pointer to nest FCBNESTFCB	DS	32*5		; Space for 5 levelsNESTEND	EQU	$		; Test for too many includesCONDPTR	DW	CONDFLG		; Conditional pointerCONDFLG	DB	0		; Init 1st state to true	DS	31		; 32 conditional levelsBADHDR$	DB	'Line xxxxx -->'JCLBUF1	DS	80	ORG	$<-8+1<+8INPBUF	DS	256OUTBUF	DS	256SYMTAB	DB	00H	ENDIF*LIST ONCORE$	DEFL	$;	END	DO