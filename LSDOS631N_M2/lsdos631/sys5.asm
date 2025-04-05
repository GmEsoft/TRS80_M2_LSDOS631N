;****************************************************************;* Filename: SYS5/ASM						*;* Rev Date: 30 Nov 97						*;* Revision: 6.3.1						*;****************************************************************;* System debugger						*;*								*;****************************************************************;	TITLE	<SYS5 - LS-DOS 6.3>;*LIST	OFF*GET	SYSRES/EQU*LIST	ONLF	EQU	10CR	EQU	13;*GET	COPYCOM;	ORG	0A0H;;	References to save area in low core;SAVONE	DS	1SAVTWO	DS	1	DS	1		; Space for saved byte (1)NXTADR	DS	2NXTBYT	DS	1DSPADR	DS	2AFREG	DS	2		; AF  Register save area	DS	2		; BC	DS	2		; DEHLREG	DS	2		; HL	DS	8		; AF', BC', DE', HL'IXREG	DS	2		; IXIYREG	DS	2		; IYSPREG	DS	1		; SPREGSAV	DS	1PCREG	DS	2		; PC	IF	.NOT.@BLD631;;Special patch insertion;	ORG	23BDH;@PRTBYT	PUSH	AF		;Print a byte routine	CALL	@PRT		; to support SYS9	POP	AF	RET	ENDIF;	ORG	1E00H;SYS5	AND	70H		; If entry = 0, return	RET	Z	POP	AF		; Discard return to SYS0	POP	AF		; Get original reg AF	PUSH	AF	PUSH	IY		; Save remaining regs	PUSH	IX	EX	AF,AF'	EXX	PUSH	HL	PUSH	DE	PUSH	BC	PUSH	AF	EX	AF,AF'	EXX	PUSH	HL	PUSH	DE	PUSH	BC	PUSH	AF	LD	HL,0	ADD	HL,SP		; Place SP into HL	LD	DE,AFREG	LD	BC,24		; Move the 24 bytes saved	LDIR	LD	(SPREG),HL	LD	SP,HL	LD	HL,(PCREG)	DEC	HL	LD	A,(HL)		; Get the byte at PC	CP	0F7H		;   & check for breakpoint	JR	NZ,$?1		; Go if not a breakpoint	LD	(PCREG),HL;;	This next routine picks up the data stored in the;	instruction storage areas used to hold the;	address and byte of the inserted RST's used to;	control the single step mode.  If the address;	save area is zero, then an RST was not inserted.;	Two areas are needed because DEBUG inserts;	RST 48's at both CALL origin and destination.;$?1	LD	HL,SAVONE	LD	B,2		; Set up loop for 2 areas$?2	XOR	A		; Clear register A & flags	LD	E,(HL)		; Get next 2 bytes	LD	(HL),A		;   (where an address	INC	HL		;   would be stored) while	LD	D,(HL)		;   simultaneously setting	LD	(HL),A		;   the save area to zero	INC	HL	LD	A,E		; Ck if area was zero	OR	D	JR	Z,$?3		; If zero, no RST entry	LD	A,(DE)		; Address save <> 0	CP	0F7H		;   ck byte for RST 48	JR	NZ,$?3	LD	A,(HL)		;   Was RST 48, restore	LD	(DE),A		;   the program byte$?3	INC	HL	DJNZ	$?2		; Loop through 2 save areasCMND	LD	SP,(SPREG)	; Set up the stack	CALL	WRREGS		;   & display normal CRT	LD	HL,16<8!0	; Move cursor to 16,0	LD	B,3		; Command	LD	A,15		; svc @VDCTL	RST	28H		; Set cursor	CALL	INPUT@		; Get command	CP	'g'		; Goto AAAA,(BBBB,(CCCC))	JP	Z,CMD_G	LD	HL,CMND		; Set up a return branch	PUSH	HL	CP	's'		; Set CRT to full screen?	JR	Z,CMD_S	CP	';'		; Inc CRT one page?	JR	Z,CMD_INC	CP	'-'		; Dec CRT one page?	JR	Z,CMD_DEC	CP	'o'		; Out to dos	JR	Z,CMD_O	CP	'c'		; Single step with CALL?	JR	Z,CMD_C	CP	'd'		; Display AAAA <space>	JR	Z,CMD_D	CP	'i'		; Single step?CMD_C	JP	Z,CMD_CI	CP	'a'		; ASCII modify memory?	JP	Z,CMD_AH	CP	'h'		; Hex modify memory AAAA?	JP	Z,CMD_AH	CP	'r'		; Modify reg pair RP DDDD?	JP	Z,CMD_R	CP	'u'		; Dynamic display update?	JR	Z,CMD_U	CP	'x'		; Display register format?	JP	NZ,BLOCK	; Try extra commands;;	Command X - Normal display mode;CMD_X	XOR	ACMD_S	LD	(SAVTWO),A	; Show not full screen	RET;;	Command U - Continuously update display;CMD_U	CALL	@KBD		; Scan keyboard	OR	A		; Character entered?	RET	NZ		; Return to CMND if so	CALL	WRREGS		;   else refresh display	JR	CMD_U		;   and loop;;	Command D - Display memory at address NNNN;CMD_D	CALL	HEXIN@		; Ret to CMND if no char	RET	Z		;   else set DSPADR to	JR	$?6		;   new address in HL;;	Command ; - Increment memory display one block;CMD_INC LD	BC,64		; Init for 64-byte block$?4	LD	HL,(DSPADR)	; Get current display addr	LD	A,(SAVTWO)	;  =0 -> Normal disp mode				; <>0 -> Full disp mode	OR	A	JR	Z,$?5	LD	C,0		; Zero out low order to				;   provide inc or dec of				;   256 bytes (full disp)	LD	A,B		; B=00 -> Inc 1 page	OR	A		;   make BC = 256	JR	NZ,$?5		; B=FF -> Dec 1 page,	INC	B		;   just add$?5	ADD	HL,BC		; HL now points to$?6	LD	(DSPADR),HL	;   new display address	RET;;	Command - - Decrement memory display one block;CMD_DEC LD	BC,0FFC0H	; Init to 64 byte dec	JR	$?4;;	Command o - Exit to DOS;CMD_O	CALL	INPUT@		; Fetch valid terminator	RET	NC		; Back if bad char	JP	@EXIT		; Else exit to DOS;;	Register display routine;WRREGS	LD	A,1CH		; Home the cursor	CALL	@DSP	IF	@MOD4	LD	A,15		; Turn off the cursor	CALL	@DSP	ENDIF	LD	A,(SAVTWO)	; 0 = normal display mode	OR	A		; <>0 = full display mode	JR	NZ,FULDSP	; No reg display if full	LD	HL,AFREG	; Pt to reg save area	PUSH	HL	LD	HL,REGTBL	; Pt to reg symbol table	LD	B,12		; Init for 12 registers$?8	CALL	WR3BYT		; Write 3 char symbol	EX	(SP),HL		; Exchange reg save ptr	LD	E,(HL)		; Place reg value in DE	INC	HL	LD	D,(HL)	INC	HL		; Place next reg save	PUSH	HL		;   ptr on the stack	EX	DE,HL		; Reg value -> HL	LD	A,'='	CALL	@DSP	CALL	WRSPA@	LD	A,H		; Write high order byte	CALL	WRHEX	LD	A,L		; Write low order byte	CALL	WRHEX	LD	A,B		; Get loop counter &	AND	0BH		;   ck if 12 => AF pair	CP	8		;   or if 8 => AF' pair	JR	NZ,NOFLG	; Bypass if not flag reg	LD	C,L		; Tranfer F reg into C &	PUSH	BC		;   save the loop counter	LD	HL,FLGTBL	; Pt to flag symbol table	LD	B,8		; Init for 8 bits$?9	SLA	C		; Shift a bit into carry	LD	A,(HL)		; Get flag table char	JR	C,$?10		; Use table char if bit on	LD	A,'-'		;   else use a dash$?10	CALL	@DSP	INC	HL		; Next flag table char	DJNZ	$?9		; Loop for 8 flag bits	POP	BC		; Get main loop counter	LD	A,61+0C0H	; Tab 60 to put cursor	CALL	@DSP		;   on the next line	JR	$?11NOFLG	CALL	WRMEM$?11	POP	HL		; Get next reg save ptr	EX	(SP),HL		; Exc with next reg symbol	DJNZ	$?8		; Loop end	POP	HL		; Get reg save ptr (fini)	LD	HL,(DSPADR)	; Get memory disp address	LD	B,4		; Init for 4 lines$?12	LD	A,6+0C0H	; Tab 6 spaces	CALL	@DSP	CALL	WR2HEX@		; Write the memory address	CALL	WRSPA@	CALL	WRMEM		; Write a line of memory	DJNZ	$?12		; Loop until 4 or 16	LD	A,1FH		; Clear to end of frame	JP	@DSPFULDSP	LD	HL,(DSPADR)	; Get display address	LD	L,0		; Round to multiple of 256	LD	B,16		; Init for 16 lines	JR	$?12;;	Register symbol table;REGTBL	DB	'af bc de hl af''bc''de''hl''ix iy sp pc ';;	Flag register bit symbol table;FLGTBL	DB	'SZ1H1PNC';;	Command G - Go to memory address NNNN,;	 Optional breakpoints;CMD_G	LD	B,2		; Init for maximum of	LD	DE,NXTBYT	;   two breakpoints	CALL	HEXIN@		; Get exec address	JR	Z,$?13		; Go on end	LD	(PCREG),HL	;   else save new start$?13	JR	C,$?14		; Go if ENTER used	CALL	HEXIN@		; Get a breakpoint	PUSH	AF	CALL	NZ,$?17		; Set if brkpt entered	POP	AF	DJNZ	$?13$?14	XOR	A	LD	(@DBGHK),A	; Init DEBUG on;;	This next section of code picks up the register;	save area, pushes the save area onto the stack,;	then pops out into the correct reg assignment;$?15	LD	HL,REGSAV	; End of reg save area	LD	B,11		; Init for 11 regs$?16	LD	D,(HL)	DEC	HL	LD	E,(HL)	DEC	HL	PUSH	DE	DJNZ	$?16	POP	AF		; Now pop the registers	POP	BC	POP	DE	POP	HL	EX	AF,AF'	EXX	POP	AF	POP	BC	POP	DE	POP	HL	EX	AF,AF'	EXX	POP	IX	POP	IY	POP	HL	LD	SP,HL	LD	HL,(PCREG)	; Init the branch address	PUSH	HL	LD	HL,(HLREG)	RET			; Go to branch;;	This next routine will insert an RST 48 instr into;	the target of a single-step or breakpoint;	providing the target address is a RAM location.;	If it is, the target byte and its address are;	saved in one of the instructions save areas.;	If the target address is ROM or nonexistant, a;	branch to command INPUT routine is taken instead;	of the pending operation.;$?17	LD	A,(HL)		; Save byte of next inst	LD	(DE),A	DEC	DE	LD	A,0F7H		; Insert RST 48 into	LD	(HL),A		;   next INST address	CP	(HL)		; Check if RAM/ROM/No memory	JP	NZ,$?1		; Go if command not in RAM	LD	A,H		; Is RAM, save address of	LD	(DE),A		;   insertion into buffer	DEC	DE	LD	A,L	LD	(DE),A	DEC	DE	RET;;	Commands A & H - Modify address NNNN to XX;	<space> increments address;CMD_AH	LD	(SAVONE),A	; Save entry condition	LD	HL,(NXTADR)	; Default to current mod addr	CALL	HEXIN@$?18	LD	(NXTADR),HL	; Adjust addr for mod	RET	C		; Return on ENTER	PUSH	HL	CALL	WRREGS	LD	HL,13<8!0	; Cursor to 13,0	LD	B,3	LD	A,15		; SVC @VDCTL set cursor	RST	28H	LD	HL,(NXTADR)	; Get mod address again	CALL	WR2HEX@		; Write the address & save	PUSH	HL		;   the mod addr again	LD	HL,14<8!0	; Cursor to 14,0	LD	B,3	LD	A,15		; SVC @VDCTL set cursor	RST	28H	POP	HL		; Recover mod addr	CALL	AHDSP	LD	A,'-'	CALL	@DSP	POP	DE		; Recover mod addr in DE	CALL	AHGET	EX	DE,HL		; Switch mod addr/value	JR	Z,$?19		; Bypass change on <space>	LD	(HL),E		; Insert new val in memory$?19	RET	C		; To CMND on non-digit	INC	HL		;   else increment address	JR	$?18		;   pointer and loopAHDSP	LD	A,(SAVONE)	CP	'a'	JP	NZ,WR1HEX@	; Write (HL) & bump HDSPASC@ LD	A,(HL)		; Else write in ASCII	CP	20H		; Convert non-displayable	JR	C,TYP3		;   values to '.'	CP	0C0H	JR	C,TYP4TYP3	LD	A,'.'TYP4	JP	@DSPAHGET	LD	A,(SAVONE)	CP	'a'	JP	NZ,HEXIN@GETASC@ PUSH	HL		; Provide upper/lower	LD	HL,INPUC@+1	;   case entry in type	LD	(HL),6FH	;   by modifying sys5 code	CALL	INPUT@	LD	(HL),0EFH	; Restore the UC -> LC	POP	HL		;   conversion	LD	L,A	RET;;	Command R - Load register pair RP with NNNN;CMD_R	CALL	INPUT@		; Get 1st symbol char	RET	Z		; Return if end	LD	C,A		;   else save char in C	CALL	INPUT@		; Get 2nd symbol char	RET	Z		; Return if end	LD	D,A		;   else save char in D	LD	E,' '		; Init for space	CALL	INPUT@		; Get 3rd symbol char	RET	C		; Return on end	JR	Z,$?20		; Bypass if not primed	LD	E,A		;   else put "'" into E	CALL	INPUT@		; Ck for space separator	RET	NZ		; Return if none	RET	C$?20	LD	HL,REGTBL	; Register symbol table	LD	B,12		; Init for 12 registers$?21	LD	A,(HL)		; Match first symbol?	CP	C	JR	Z,$?24		; If a match, test 2nd	INC	HL		;   else pt to next reg$?22	INC	HL$?23	INC	HL	DJNZ	$?21		; Loop for 12 regs	RET			; Return if no match$?24	INC	HL		; Pt to 2nd table char	LD	A,(HL)		;   & get the symbol	CP	D		; Ck 2nd char input	JR	NZ,$?22		; -> next if no match	INC	HL		; Match, ck 3rd reg symbol	LD	A,(HL)		; Get the 3rd table symbol	CP	E		;   & compare with input	JR	NZ,$?23		; -> next if no match	LD	A,18H		; Convert counter to index	SUB	B		;   into reg save area	SUB	B	LD	C,A		; Index into BC	LD	B,0	LD	HL,AFREG	; Start of reg save area	ADD	HL,BC		; Add index to get pointer	PUSH	HL		; Save the pointer	LD	A,1EH		; Clear to end of frame	CALL	@DSP	POP	DE		; Recover pointer	CALL	HEXIN@		; Read in the new value	RET	Z		; No update if none	EX	DE,HL		; Exchange value/pointer	LD	(HL),E		; Insert new value into	INC	HL		;   register save area	LD	(HL),D	RET;;	Command I - Step one instruction at a time;CMD_CI	PUSH	AF		; Save whether I or C	LD	DE,(PCREG)	; Point to instr address	LD	A,(DE)		;   & get it	LD	HL,XY_TAB	; IX,IY table	CP	0DDH		; Is inst an IX?	JR	Z,$?25	CP	0FDH		; Is inst an IY?	JR	Z,$?25	LD	HL,OP_TAB	; All X IX, IY & ED	CP	0EDH		; Is inst an ED?	JR	NZ,$?26	LD	HL,ED_TAB	; ED Table$?25	INC	DE		; Get next byte for	LD	A,(DE)		;   IX, IY and ED inst	DEC	DE		; Reset ptr to 1st byte$?26	LD	C,A		; Inst byte to reg C;;	This next section of code determines the length;	of all instructions and whether they are;	CALLs, JumPs, or RETurns.;$?27	LD	A,(HL)		; Get table value &	AND	C		;   strip off certain bits	INC	HL		; Pt to table code	CP	(HL)		; If a match, the inst is	INC	HL		;   fully decoded as to	JR	Z,$?28		;   length & type by the	INC	HL		;   next byte	LD	A,(HL)		; Check for table end	CP	5	JR	NC,$?27$?28	LD	A,(HL)		; Get control/length byte	LD	B,A		;  into reg B	AND	0FH		; Strip off the control	LD	L,A		; Put length into reg L	LD	H,0		; Zero out reg H	ADD	HL,DE		; Next address into HL	PUSH	DE		; This addr in DE saved	LD	DE,NXTBYT	; Buffer area	CALL	$?17		; Insert RST 28H if RAM	POP	HL		; Get this inst address	LD	A,B		; Get ctrl/length byte	AND	0F0H		; Strip off length	JR	Z,$?29		; Go if regular inst	INC	HL	CP	20H	JR	C,$?34		; Branch if 'JP (HL)	JR	Z,$?33		; Go if 'JP (IX|IY)'	CP	40H	JR	C,$?32		; Go if JR or DJNZ	JR	Z,$?31		; Branch if JP inst	CP	60H	JR	C,$?30		; Branch if RET inst	JR	Z,$?28A		; Branch if CALL inst	LD	A,C		;  else calc target of	AND	38H		;  the RST inst	LD	L,A	LD	H,00H	POP	AF		; Rcvr entry command	CP	'c'	JR	Z,$?29		; Go in "call" mode	LD	A,L		; Must check RST for	CP	5<3		;  40, 48, 56 inhibit	JR	NC,$?29		; Convert to CALL	JR	$?35		;  else single step$?28A	POP	AF		; Rcvr entry command	CP	'i'		; Was command an 'I'?	JR	Z,$?31		; Go for 'CALLS' if 'I'$?29	JP	$?15		; Go for 'CALLS' if 'C'$?30	LD	HL,(SPREG)	; RET inst, p/u RET addr$?31	LD	A,(HL)		; JP inst, p/u jump addr &	INC	HL		;  insert into reg HL	LD	H,(HL)	LD	L,A	JR	$?35$?32	LD	C,(HL)		; JR or DJNZ, get 'E'	LD	A,C		; Make A=0 if C is	RLCA			;  positive, else make	SBC	A,A		;  A=FF for negative	LD	B,A		; Put in B, FF if 'E' neg	INC	HL		;  or 0 if 'E' pos	ADD	HL,BC		; Add displacement	JR	$?35$?33	LD	HL,(IXREG)	; Init for JP (IX)	BIT	5,C		; Test inst for DD/FD	JR	Z,$?35		; Bit 5 off = DD	LD	HL,(IYREG)	; JP (IY), get jump addr	JR	$?35$?34	LD	HL,(HLREG)	; JP (HL), get jump addr$?35	CALL	$?17	JR	$?29;;	The next three tables are used to determine the;	length and instruction type for all instructions;	used in the single-step mode.  Table format uses;	three bytes for each decoding process.	The 1st;	byte is ANDED with the inst byte to strip off;	selected bits and include others.  The result is;	compared to the next table byte (test byte) for;	a match.  If matched, then the inst byte has been;	identified as to its class & length.  The 3rd byte;	denotes the class and length as follows:; High order nibble:;	0 = regular instructions;	1 = JP (HL);	2 = JP (IX) or JP (IY);	3 = JR or DJNZ instruction;	4 = JP instruction;	5 = RET instruction;	6 = CALL instruction;	7 = RST instruction; Low order nibble = the length;	The last byte of each table is the length of;	all other instructions.;;	Table for regular instructions (no IX, IY, ED);OP_TAB	DB	0C7H,0C0H,51H	; C8, D8, E8, F8	DB	0FFH,0C9H,51H	; C9	DB	0FFH,0E9H,11H	; E9	DB	0CFH,01H,03H	; 01, 11, 21, 31	DB	0E7H,22H,03H	; 22, 2A, 32, 3A	DB	0C7H,0C2H,43H	; C2, CA, D2, DA, E2, EA, F2, FA	DB	0FFH,0C3H,43H	; C3	DB	0C7H,0C4H,63H	; C4, CC, D4, DC, E4, EC, F4, FC	DB	0FFH,0CDH,63H	; CD	DB	0C7H,06H,02H	; 06, 0E, 16, 1E, 26, 2E, 36, 3E	DB	0F7H,0D3H,02H	; D3, DB	DB	0C7H,0C6H,02H	; C6, CE, D6, DE, E6, EE, F6, FE	DB	0FFH,0CBH,02H	; All CB instructions	DB	0F7H,10H,32H	; 10, 18	DB	0E7H,20H,32H	; 20, 28, 30, 38	DB	0C7H,0C7H,71H	; RST instructions	DB	01H		; All others are 1 byte;;	Next table is for ED - extended instructions;ED_TAB	DB	0C7H,43H,04H	; 43, 4B, 53, 5B, 73, 7B	DB	0F7H,45H,52H	; 45, 4D	DB	02H		; All other ED are 2-byte;;	IX, IY index instructions table;XY_TAB	DB	0FEH,34H,03H	; 34, 35	DB	0C0H,40H,03H	; 4X, 5X, 6X, 7X (X=0-F)	DB	0C0H,80H,03H	; 8X, 9X, AX, BX (X=0-F)	DB	0FFH,21H,04H	; 21	DB	0FFH,22H,04H	; 22	DB	0FFH,2AH,04H	; 2A	DB	0FFH,36H,04H	; 36	DB	0FFH,0CBH,04H	; CB	DB	0FFH,0E9H,22H	; E9	DB	02H		; All others are 2-bytes;;	Routine to display memory on CRT screen;WRMEM	PUSH	BC		; Save main counter 4/16	LD	A,'='	CALL	@DSP	INC	A		; '>'	CALL	@DSP	LD	B,16		; Init for 16 lines	PUSH	HL		; Save memory pointer$?36	CALL	GRPHIC		; Ck if need graphic bars	CALL	WR1HEX@		; Call HEX display only	DJNZ	$?36		; Loop until full line	POP	HL		; Recover memory pointer;;	Now write the line in ASCII;	CALL	WRSPA@	LD	B,16$?37	CALL	$?41		; Space after 8th	LD	A,(HL)		; Get the byte -> reg A	CP	' '		; Repl controls with '.'	JR	C,$?38	CP	0C0H		; Tabs/specials with '.'	JR	C,$?39$?38	LD	A,'.'$?39	CALL	@DSP	INC	HL		; Bump memory address	DJNZ	$?37	POP	BC		; Get line counter	RET;;	This routine determines if the vertical graphic;	bars should be surrounding the current character;GRPHIC	LD	DE,(NXTADR)	; Get modification address	INC	DE		;  & increment it	PUSH	HL		; Save current memory	XOR	A		;  display address	SBC	HL,DE		; Ck if mod addr=disp addr	IF	@MOD4	LD	A,95H		; Graphic left bar	ENDIF	IF	@MOD2	LD	A,15H	ENDIF	JR	Z,$?40		; Insert graphic if equal	CALL	$?41		; Not =, insert space if	INC	HL		;  between pos 8 & 9	LD	A,L		; Result 0 if next	OR	H		;  char address is also				;  the display address	POP	HL		; Get current mem disp addr	IF	@MOD4	LD	A,0AAH		; Graphic right bar output	JP	Z,@DSP		; Go if yes	JR	$?42		;  else continue	ENDIF	IF	@MOD2	JR	NZ,$?42		; Go if not	XOR	A		;  lead in	CALL	@DSP		; Init video lead in	LD	A,15H	JP	@DSP		; And display	ENDIF$?40	EQU	$	IF	@MOD2	PUSH	AF	XOR	A	CALL	@DSP		; Lead in code	POP	AF		; Restore	ENDIF	CALL	@DSP		; Display char	POP	HL		; Recover current display$?41	LD	A,B		;  address & output a	CP	08H		;  space if between the	RET	NZ		;  8th & 9th bytes$?42	JR	WRSPA@		;  else just return;;	This routine will return with zero flag set;	on entry of a comma or SPACE.  Entry of ENTER;	will set carry flag and return;INPUT@	PUSH	DE$?43	CALL	@KEY	CP	0DH		; ENTER?	JR	Z,$?44	CP	20H		; Get another char if	JR	C,$?43		;  entry was controlINPUC@	SET	5,A		; Convert UC to lc	CALL	@DSP		; Not control, disp it	POP	DE	CP	','		; Return with zero flag	RET	Z		;  set if a comma	CP	' '		; Return with zero flag	RET			; set if <SPACE>$?44	POP	DE	SCF			; <ENTER> will set	RET			;  the carry flag;;	This routine will read in digits;	and convert them to binary;HEXIN@	CALL	INPUT@		; Get char and return on	RET	Z		;  SPACE, COMMA or ENTER	LD	HL,0		; Init value to zero$?45	CALL	CVB		; Convert to binary if OK	JP	C,CMND		;  else back on bad digit	ADD	HL,HL		; Multiply current value	ADD	HL,HL		;  by 16 and insert the	ADD	HL,HL		;  new digit into the	ADD	HL,HL		;  lo-order nybble of L	OR	L	LD	L,A	CALL	INPUT@		; Get another character	JR	NZ,$?45		; Go if not separator	RRA			; Force ENTER to set	ADC	A,81H		;  the carry flag	RET;;	Routine to convert expected ASCII hex digit to;	its binary value.  Set carry-flag on bad digit;CVB	SUB	'0'		; Convert digit to binary	RET	C		; Error if less than '0'	ADD	A,0C9H		; Ck for >F (46H-30H=16H)				;  (16H+E9H=FFH)	RET	C		; Error if > ASCII 'F'	ADD	A,06H		; (E9H-EFH) to (EFH-05H)	JR	C,ATOF		; Carry denotes was <A-F>	ADD	A,27H		; (EFH-FFH) to (F6H-06H)	RET	C		; Error if (3AH-3FH/:-?)ATOF	ADD	A,0AH		; (00D-06D) to (10D-16D)				;  or (F6H-FFh) to (0-9)	OR	A		; Set zero flag on zero	RET;;	Routine to write one byte as two hex digits;WR1HEX@ LD	A,(HL)	INC	HL	JR	CV2HEX@;;	Routine to write 2 hex bytes (HL) as 4 hex digits;WR2HEX@ LD	A,H	CALL	CV2HEX@	LD	A,L;;	Routine converts a byte to 2 hex digits;CV2HEX@ PUSH	AF		; Save the byte in A	RRA			; Move high order	RRA			;  into low order	RRA	RRA	CALL	$?46		; Strip off hi-order				;  & convert to ASCII	POP	AF		; Recover the byte$?46	AND	0FH		; Strip off high order	ADD	A,90H		;  & convert to ASCII	DAA	ADC	A,40H	DAA$?47	JP	@DSP;;	Miscellaneous routines;WRHEX	CALL	CV2HEX@WRSPA@	LD	A,20H	JR	$?47WR3BYT	CALL	$?48	CALL	$?48$?48	LD	A,(HL)	INC	HL	JR	$?47;;	Command B - Block move;BLOCK	CP	'b'	JR	NZ,FILL	LD	HL,(DSPADR)	; 'b'lock move s,d,len	CALL	HEXIN@		; Default to disp addr	RET	C		; Back on <ENTER>	LD	(DSPADR),HL	; Save start addr	JR	NZ,BL01		; Go if start entered	CALL	WR2HEX@		;  else show default	LD	A,','	CALL	@DSPBL01	LD	HL,(NXTADR)	; Default next address	CALL	HEXIN@	LD	(NXTADR),HL	; Save dest address	JR	NZ,BL02		; Go if entered	PUSH	AF	CALL	WR2HEX@		;   else show default	LD	A,','	CALL	@DSP	POP	AFBL02	LD	HL,256		; Default length to 256	JR	C,BL03		; Go if ENTER used prev.	CALL	HEXIN@		; Get new length	JR	NZ,BL04		; Go if enteredBL03	PUSH	HL	CALL	WR2HEX@		;  else dsply default	POP	HLBL04	LD	B,H		; Length to BC	LD	C,L	LD	HL,(DSPADR)	; Set source	LD	DE,(NXTADR)	;  and dest	LDIR	LD	(NXTADR),DE	; Set new mod addr	RET;;	'F'ill aaaa,bbbb,cccc;FILL	CP	'f'	JR	NZ,JUMP	CALL	HEXIN@		; Get starting address	RET	Z	PUSH	HL		; Save starting address	CALL	HEXIN@		; Get ending address	EX	(SP),HL		; Place ending into BC	POP	BC		;   & starting into HL	RET	Z	PUSH	HL		; Save starting again	CALL	HEXIN@		; Get fill char	LD	E,L		; Save fill in E	POP	HL		; Recover starting addr	RET	Z	XOR	A		; Clear the C-flagFIL1	PUSH	HL	SBC	HL,BC	POP	HL	RET	NC		; Return when start=end	LD	(HL),E		; Stuff char into memory	INC	HL	JR	FIL1;;	'j'ump over next instruction;JUMP	CP	'j'	JR	NZ,QUERY	LD	HL,(PCREG)	; Get current PC location	INC	HL		;  and increment it	LD	(PCREG),HL	RET;;	'q'uery ii - 'q'uery oo,dd;	input/output to port;QUERY	CP	'q'	JR	NZ,DISKIO	LD	A,1EH		; Clear to end of line	CALL	@DSP	CALL	HEXIN@		; Get port number	RET	Z		; Back if no value	LD	C,L	JR	C,QUE1		; If ENTER do input	CALL	HEXIN@		; Get byte to output	RET	Z		; Quit if none	OUT	(C),L		; Do the output	RETQUE1	LD	A,'='		; Display separator	CALL	@DSP	IN	A,(C)		; Read the port and	CALL	CV2HEX@		;  Display the value	JP	INPUT@;;	If a command is entered and not found in SYS5,;	SYS9 will be searched if the extended debugger;	is active;EXTDBG	LD	HL,(EXTDBG$)	; Try extended debug	JP	(HL);;	Disk I/O - d,c,s,r/w/*,addr,length;	d=drive;	c=cylinder;	s=sector;	r=read, w=write, *=write to directory;	addr=address for I/O;	length=# of bytes to read/write;DISKIO	SUB	30H		; Cvrt drive to binary	CP	08H		; Check on max drive	JR	NC,EXTDBG	; Exit if not <0-7>	LD	C,A		; Xfer drive # to reg C	CALL	@GTDCT		;   & get the DCT	LD	A,(IY+07H)	; Get sectors/cyl & heads	AND	0E0H		; Remove sectors/cyl	RLCA			;   & keep # of heads	RLCA			; Shift into bits 0-2	RLCA	INC	A		; Adj for zero offset	LD	B,A	LD	A,(IY+07H)	; # of sectors / cyl	AND	1FH		; Remove heads	INC	A		; Adj for zero offset	LD	H,A	XOR	A		; Accumulate total # ofDIS1	ADD	A,H		; Sectors per cyl	DJNZ	DIS1	BIT	5,(IY+04H)	; Test if 2-sided drive	JR	Z,DIS2	ADD	A,A		; Times 2 if 2-sidedDIS2	LD	(SAVTWO+1),A	; Save sectors per cyl	LD	A,1EH		; Clear to end of line	CALL	@DSP	CALL	INPUT@		; Input cyl #	RET	C	CALL	HEXIN@	RET	C	LD	D,L		; Cylinder entered?	JR	NZ,DIS3	LD	D,(IY+09H)	; Get dir cylinderDIS3	CALL	HEXIN@	LD	E,L		; Sector entered?	LD	A,01H		; Init to 1 sector	JR	NZ,DIS4	LD	E,00H		; Default to sector 0	LD	A,(SAVTWO+1)	; Default to total sectorsDIS4	LD	(NXTBYT),A	RET	C	CALL	INPUT@		; Get I/O direction (R/W/*)	RET	C	LD	B,A		; Save I/O char in B	CALL	INPUT@		; Get buffer I/O address	RET	C	CALL	HEXIN@	PUSH	HL		; Save buffer address	JR	C,DIS6	PUSH	HL	CALL	HEXIN@		; Sector count entered?	LD	A,L	POP	HL	JR	Z,DIS6		; Go if no sector count	LD	(NXTBYT),A	;   else update countDIS6	LD	A,B		; Get I/O direction	CP	'r'		; Read?	JR	Z,DIS9	CP	'w'		; Write?	JR	Z,DIS10	CP	'*'		; Write to directory?	JR	Z,DIS11DIS7	INC	H		; Bump up a buffer page	INC	E		; Bump sector number	LD	A,(SAVTWO+1)	; Get max # of sectors	DEC	A		; Compare max to where	CP	E		;   we are	JR	NC,DIS8		; Jump if more on cyl	LD	E,00H		; Reset sector # to 0	INC	D		; Bump cylinderDIS8	LD	A,(NXTBYT)	; Reduce sector I/O count	DEC	A	LD	(NXTBYT),A	JR	NZ,DIS6		; Loop if not throughDIS8A	POP	HL		; Recover buffer start addr	LD	A,B		; Get I/O direction	CP	'r'		; Read?	RET	NZ		; Return if not read	LD	L,00H		; Reset memory buffer ptr	LD	(DSPADR),HL	;  to display the 1st	LD	(NXTADR),HL	;  sector read	LD	A,'s'		; Set full screen mode	LD	(SAVTWO),A	RET;DIS9	EQU	$	PUSH	HL	PUSH	DE	PUSH	BC	LD	D,H		; Pass buffer to DE	LD	E,L	INC	DE		; Start +1	LD	(HL),00H	; Clear a byte	LD	BC,255		; Length -1	LDIR			; Clear buffer	POP	BC		; Unstack	POP	DE	POP	HL;	CALL	@RDSEC		; Read the sector	JR	Z,DIS7		; Loop on read okay	CP	06H		;  or directory read	JR	Z,DIS7	JR	DIS12		;  else errorDIS10	CALL	@WRSEC		; Write sector	JR	Z,DIS7		; Loop on write okay	JR	DIS12DIS11	CALL	@WRSSC		; Write system sector	JR	Z,DIS7		; Loop on write prot ok;;	Disk I/O error output display routine;DIS12	PUSH	DE		; Save track and sector	PUSH	AF		; Save error code	CALL	WRSPA@		; Output a space	LD	A,'*'	CALL	@DSP		; Followed by asterisk	POP	AF	CALL	CV2HEX@		; Write error #	LD	A,'*'	CALL	@DSP		; Followed by space	CALL	INPUT@		; Continue?	POP	DE		; Recover track/sector	JR	NC,DIS7		; Loop unless <ENTER>	JR	DIS8A		; Exit on <ENTER>;LAST	EQU	$	IFGT	LAST,MAXCOR$-2	ERR	'Module too big'	ENDIF	ORG	MAXCOR$-2	DW	LAST-SYS5	; Overlay size;	END	SYS5