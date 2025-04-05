;****************************************************************;* Filename: FDCDVR/ASM						*;* Rev Date: 30 Nov 97						*;* Revision: 6.3.1						*;****************************************************************;* TRS-80 Model 4 Floppy Disk Driver routines			*;****************************************************************;	SUBTTL	'<Floppy Disk Driver>';;	HL -> Buffer Address;	D  -> Track desired;	E  -> Sector desired;	C  -> Drive desired;	B  -> Disk primitive command;WRNMIPORT EQU	0E4H		;NMI mask registerFDCADR	EQU	0F0H		;FDC Command port (write)FDCSTAT	EQU	FDCADR		;FDC Status port (read)TRKREG	EQU	FDCADR+1	;FDC Track port (r/w)SECREG	EQU	FDCADR+2	;FDC Sector port (r/w)DATREG	EQU	FDCADR+3	;FDC Data port (r/w)DSELCT	EQU	FDCADR+4	;Drive select port;;;	Disk Driver Entry Point;FDCDVR	JR	FDCBGN		;Branch around linkage	DW	FDCEND		;Last byte used	DB	3,'$FD'		;Module name;;	Automatic density recognition and retry density switch;SWDEN	LD	A,3		;Check counter for 2	CP	B		;  tries after this one	JR	Z,RESTOR	;If so try a restore;	LD	A,(IY+3)	;Flip the density bit,	XOR	40H		;  Bit 6, (IY+3)	LD	(IY+3),A	LD	BC,2409H	;Set alloc to SDEN	BIT	6,A		;Test SDEN/DDEN	JR	Z,SDEN		;Do SDEN if it was DDEN	LD	BC,4511H	;  else set alloc to DDENSDEN	LD	(IY+7),C	LD	(IY+8),B	RET;;	Verify routine;VERFIN	LD	HL,BUCKET	;Set byte bucket	LD	A,2DH		;Set for DEC L	DB	1EH		;Ignore next with LD E,n;;	Read routine;RDIN	XOR	A		;Set for NOP	LD	(CKVER),A	CALL	RWINIT		;Initialize	LD	E,16H		;Status maskRDIN1	IN	A,(FDCSTAT)	;Get status	AND	E		;Loop until DRQ	JR	Z,RDIN1		;  or error	INI			;Grab byte	DI	LD	A,D		;Get drive sel + WSGENRDIN2	OUT	(DSELCT),A	;Initiate wait stateCKVER	NOP			;DEC L if verify	INI			;Xfer byte	JR	NZ,RDIN2	;Loop then TSTBSY;;	Reselect drive while controller is busy;TSTBSY	IN	A,(FDCSTAT)	;Check FDC status	BIT	0,A		;Busy?	RET	Z		;Return if not	LD	A,(PDRV$)	;pickup drive	OUT	(DSELCT),A	;  & reselect	JR	TSTBSY		;Loop until idle;;	Driver Start;FDCBGN	LD	A,B		;pickup primitive request	AND	A		;NOP?	RET	Z		;Quit if so	CP	7	JR	Z,TSTBSY	;Jump on TSTBSY request	JP	NC,IORQST	;Jump on I/O request	CP	6	JR	Z,SEEKTRK	;Jump on track seek	DEC	A	JR	Z,SELECT	;Jump on drive select	INC	(IY+5)		;Bump current cylinder	CP	4	LD	B,58H		;FDC step in command	JR	Z,STEPINRESTOR	LD	(IY+5),0	;Set track to 0	LD	B,8		;FDC restore command	JR	STEPIN;SELECT	CALL	TSTBSY		;Check drive status	RLCA	IF	@BLD631;;	This is the first part of the fix for Gate-Array systems.  Provided;	by Frank Durda IV in a paper for The Misosys Quarterly, Vol IV.iii;	Essentially, the motor-on timer in gate-array Model 4/4D/4P systems;	sometimes fails to log a write to 0xD4, and the motor can unexpectedly;	spin-down.  The most common symptom is to end up with duplicate;	directory entries.   The patch ensures that for directory accesses;	port 0xd4 is accessed twice before read/write operations begin.;	LD	A,(IY+3)	;p/u SDEN/DDEN	PUSH	AF		;Save NOT READY flag	PUSH	BC	ELSE	PUSH	AF		;Save NOT READY flag	PUSH	BC	LD	A,(IY+3)	;p/u SDEN/DDEN	ENDIF	RLA			;Bit 6->7, bit 4->4	SRA	A	AND	90H		;Keep only DDEN & side 1	LD	C,A		;Save the bits	BIT	7,A		;Check if SDEN or DDEN	JR	Z,NOPCMP	;No precomp if SDEN	LD	A,(IY+9)	;Set precomp on all	CP	D		;  tracks above DIR	JR	NC,NOPCMP	;Go if no precomp needed	SET	5,C		;Request precompNOPCMP	LD	A,(IY+4)	;Get drive select code	AND	0FH		;Keep only select bits	OR	C		;Merge in bits 4,5,7	POP	BC	OUT	(DSELCT),A	;Select drive	LD	(PDRV$),A	;Store port byte	IF	@BLD631;	This is the second part of the fix for Gate-Array systems.  Provided;	by Frank Durda IV in a paper for The Misosys Quarterly, Vol IV.iii	OUT	(DSELCT),A	;Select drive again	POP	AF		;Retrieve NOT READY bit	RET	NC		;Return if it was ready	BIT	2,A		;Check DELAY=0.5 or 1.0	ELSE			;Ver < 631	POP	AF		;Retrieve Not Ready bit	RET	NC		;Ret if was ready	BIT	2,(IY+3)	;Check DELAY=0.5 or 1.0	ENDIF	CALL	Z,FDCDLY	;Double delay if 1.0FDCDLY	PUSH	BC		;Delay routine	LD	B,7FH	CALL	PAUSE@	POP	BC	RET;;	Routine to seek a track;SEEKTRK	CALL	TSTBSY		;Wait until not busy	LD	A,(IY+5)	;p/u current cylinder	OUT	(TRKREG),A	;  & set FDC to current	LD	A,(IY+7)	;p/u alloc data	AND	1FH		;Get highest # sector	SUB	E		;Form req sector minus	CPL			;  max, setting CY flag if	RES	4,(IY+3)	;  init side select to 0	JR	NC,SETSECT	;Go if sector on side 0	BIT	5,(IY+4)	;If not 2-sided media	JR	Z,FRCSID0	;  don't set side 1	SET	4,(IY+3)	;Set side 1	DB	06H		;Ignore next with LD B,7BHSETSECT	LD	A,E		;Restore unaltered sector #FRCSID0	OUT	(SECREG),A	;Set sector	LD	A,D	OUT	(DATREG),A	;Set desired track	CP	(IY+5)		;If at desired track	LD	B,18H		;  use seek, else use	JR	Z,STEPIN	;  seek with verify	LD	(IY+5),D	;Update current cylinder	LD	B,1CH		;Seek with verify commandSTEPIN	CALL	SELECT		;Select drive	LD	A,(IY+3)	AND	3		;Strip all but step rate	OR	BPASSCMD	OUT	(FDCADR),A	;Give FDC its command	LD	B,12H		;Delay time	DJNZ	$		;Wait a bit	XOR	A		;Z-flag for returnFDCRET	RET;;	Read and write init routines;RWINIT	LD	A,D		;Restuff track register	OUT	(TRKREG),A	LD	A,(PDRV$)	;Get select code	OR	40H		;Set WSGEN bit	LD	D,A		;Save code in D	AND	10H		;Get side sel bit	RRCA			;  to bit 3	BIT	1,C		;Check if doing side cmp	JR	NZ,GETCMD	;Go if so	XOR	AGETCMD	OR	C	LD	C,DATREG	;Get data port into C	CALL	FDDINT$		;Interrupts on or off	JR	PASSCMD		;Pass command to controller;;	I/O request handler;IORQST	BIT	2,B		;Write command?	LD	BC,(RFLAG$-1)	;pick up retry count	LD	C,82H		;FDC Read Sector command	JR	NZ,WRCMD	;Go if write command	CP	10		;Verify sector?	JR	Z,VERFY	CALL	GRABNDO		;Grab next code & insert	DB	1		;Error code start	DW	RDIN		;Read entry pointVERFY	CALL	GRABNDO		;Stuff I/O direction	DB	1		;Error code start	DW	VERFIN		;Verify entry pointWRCMD	BIT	7,(IY+3)	;Software write prot?	JR	Z,WRCMD1	;Bypass if not	LD	A,15		;Else set WP error	RETWRCMD1	LD	C,0A2H		;FDC Write Sector command	CP	14		;Write DIR sector?	JR	C,DOWRIT	LD	C,0A3H		;Change DAM if directory	JR	Z,DOWRIT	LD	C,0F0H		;  else write trackDOWRIT	CALL	GRABNDO		;Switch code	DB	9		;Error code start	DW	WROUT		;Write entry point;;	Routine stuffs error start byte & I/O vector;GRABNDO	EX	(SP),HL		;Save HL & get ret addr	LD	A,(HL)		;p/u & stuff error code	INC	HL		;  start byte	LD	(ERRSTRT+1),A	LD	A,(HL)		;Set up data transfer	INC	HL		;  direction vector	LD	H,(HL)	LD	L,A	LD	(CALLIO),HL	;Stuff CALL vector	POP	HL		;Restore buffer addr;;	Main I/O Handler routine;RETRY	PUSH	BC		;Save retry & FDC command	PUSH	DE		;Save track/sector	PUSH	HL		;Save buffer addr	BIT	4,C		;Test for track command	CALL	Z,SEEKTRK	;Seek if not track write	CALL	TSTBSY		;Wait until not busy	CALL	0		;Call I/O routineCALLIO	EQU	$-2		;Data transfer directionDISKEI	NOP			;Will be changed to an EI after				;  BOOT has read in SYSRES	IN	A,(FDCSTAT)	;Get status	AND	7CH		;Strip all but 2-6	POP	HL		;Recover buffer addr	POP	DE		;Recover track/sector	POP	BC		;Recover retry count & command	RET	Z		;Return if no error	BIT	2,A		;Lost data?	JR	NZ,RETRY	;Don't count this retry	PUSH	AF	AND	18H		;Record not found or CRC?	JR	Z,DISKDUN	;No retries if otherwise	BIT	4,A		;Record not found?	PUSH	BC		;If so, switch	CALL	NZ,SWDEN	;  density or restore	POP	BC	POP	AF	DJNZ	RETRY		;Count down retry	DB	6		;Ignore next with LD B,nDISKDUN	POP	AF		;Adjust RET code	LD	B,AERRSTRT	LD	A,0		;Start with R=1, W=9ERRTRAN	RRC	B	RET	C	INC	A	JR	ERRTRAN;;	Write routine;WROUT	CALL	RWINIT		;Set up initialization	LD	E,76H		;Status maskWR01	IN	A,(FDCSTAT)	;Get status	AND	E		;fall out on DRQ or error	JR	Z,WR01		;  else loop	OUTI			;Xfer byte to FDC	DI			;Now kill the interrupts	IN	A,(FDCSTAT)	;Check for errors	RRA			;Did BUSY drop?	RET	NC		;Quit now if so	LD	A,0C0H		;Enable INTRQ and timeout	OUT	(WRNMIPORT),A	LD	B,50H		;Time delay for WRSEC	DJNZ	$	LD	B,(HL)		;Get next byte early	INC	HLWR03	LD	A,D		;Enable wait states	OUT	(DSELCT),A	IN	A,(FDCSTAT)	;Check if timed out	AND	E		;Loop back if it timed	JR	Z,WR03		;  out (must be WRTRK)	OUT	(C),B		;pass second byte	LD	A,D		;Get sel code + WSGEN bitWR02	OUT	(DSELCT),A	;Pass until FDC times out	OUTI			;  & generates NMI	JR	WR02	IFEQ	$&0FFH,0FFH	ERR	'Warning... BUCKET position error'	ENDIFBUCKET	DB	'S';@RSTNMI	XOR	A		;NMI vectors here	OUT	(WRNMIPORT),A	;Disable INTRQ and timeout	LD	BC,100		;Need to wait a moment	CALL	PAUSE@	POP	HL		;Discard return	RETFDCEND	EQU	$-1	END