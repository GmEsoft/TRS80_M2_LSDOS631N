; CONV2/CMD - Ver 1.0 - 01/03/84
; Program to transfer files from Mod II TRSDOS to
;   Mod II LS-DOS disks
;*******
; Tim Mann
; 08/07/81 -- Initial version based on CONV 3.2
;******
; Les Mikesell
; 09/17/82 -- added DIR param
; added NOT param
; fixed LRL<256 files
; reset #sectors/track for each read
; runs in mod1 or 3
; 10/12/82 -- fixed zero record files
; adapted to LDOS II - kjw
;
*GET	BUILDVER
;
	IF	@BLD631B
*GET	COPYCOM
	ELSE
	COM	'<*(C) 1982,3,4,6 by LSI*>'
	ENDIF
;
	ORG	3000H
;
ETX	EQU	03H
CR	EQU	0DH
@ABORT	EQU	21
@OPEN	EQU	59
@DSPLY	EQU	10
@DSP	EQU	02
@KEY	EQU	01
@KEYIN	EQU	09
@KBD	EQU	08
@INIT	EQU	58
@POSN	EQU	66
@WRITE	EQU	75
@REW	EQU	68
@CLOSE	EQU	60
@EXIT	EQU	22
@ERROR	EQU	26
@KILL	EQU	57
@LOGOT	EQU	12
@PARAM	EQU	17
RDSECT	EQU	49
@GETDCT	EQU	81
@HIGH$	EQU	100
@FLAGS	EQU	101
@SVC	EQU	28H
;
;
BEGIN	EQU	$
	PUSH	HL		;save input pointer
	LD	HL,HELLO$	;sign on message
	CALL	DSPLY		;display it
	POP	HL		;restore input
	LD	A,@FLAGS	;SVC #
	RST	@SVC		;fetch flags
	RES	0,(IY+'K'-'A')	;reset BREAK bit
	JP	START
; jump tables for calls that might be changed
READER	LD	A,RDSECT	;SVC #
	RST	@SVC
	RET
;
PARAMR	LD	A,@PARAM	;SVC #
	RST	@SVC
	RET
;
GETDCR	LD	A,@GETDCT
	RST	@SVC
	RET
;
LOGOR	LD	A,@LOGOT
	RST	@SVC
	RET
;
DEHIGH:	JP	GETHI2		;Ld DE,(HIGH$)
;
START	EQU	$
;
; Scan parameters first so we know if 2nd drivespec
; is necessary
;
	CALL	SKIPSP		;Find 1st char
	PUSH	HL		;Save posn
;
SCNLP:	LD	A,(HL)
	CP	CR		;End of line?
	JR	Z,NOPRMS	;Then skip this
	CP	'('		;Start of params?
	JR	Z,SCANR
	INC	HL
	JR	SCNLP		;Keep looking
;
SCANR:	LD	DE,PBLOCK	;=>list
	CALL	PARAMR		;Scan
	JP	NZ,PERROR	;Quit if error
;
NPARM:	LD	DE,0		;<=new param
OPARM:	LD	BC,0		;<=old param
	LD	A,E		;Don't allow new and old
	AND	C
	JP	NZ,PERROR	
	LD	A,E		;Form N!O
	OR	C
	LD	(NORO+1),A	;Save that
;
;Check for NOT
NOPRMS:	POP	HL		;Back to command line
	LD	A,(HL)		;Check for NOT
	CP	'-'
	JR	NZ,MVNAM1
	LD	A,0FFH		;Set TRUE
	LD	(NOTPRM),A	;And save
	INC	HL		;Move past -
;
; Pick up drive numbers and partial filespec
;
MVNAM1:	LD	DE,PATTRN	;Point to pattern
	LD	B,8		;Max 8 chars in name
	CALL	MOVELT		;Move letters/digits/$
	CALL	SKIPLT		;Skip letters/digits/$
	LD	A,(HL)		;Slash?
	CP	'/'
	JR	NZ,NOEXT	;Go if none
	INC	HL
	LD	DE,PATEXT	;Point to ext field
	LD	B,3		;Max 3 chars in ext
	CALL	MOVELT		;Move letters/digits/$
	CALL	SKIPLT		;Skip letters/digits/$
NOEXT:	CALL	GETDRV		;Get source drive #
	LD	(SDRIVE),A	;Store drive #
	AND	A		;Be sure not drive 0
	JP	Z,PERROR	;Parameter error if so
	CALL	SKIPSP		;Skip spaces
	CALL	GETDR2		;Get destination drive
	LD	(DDRIVE),A	;Store it
;
; Save old DCT
;
	LD	A,(SDRIVE)	;Pick up source drive #
	LD	C,A		;Move to C reg
	LD	A,(DDRIVE)	;Be sure not single drive
	CP	C
	JP	Z,PERROR	;Error if so
	CALL	GETDCR		;Point IY to DCT
	PUSH	BC		;Save drive #
	PUSH	IY		;Move DCT to HL reg
	POP	HL
	LD	DE,SAVDCT	;Point to save area
	LD	BC,10
	LDIR			;Move it
	POP	BC
;
; Read GAT/HIT to log drive as DDEN
;
	LD	DE,2C01H	;Track 2C, sector 1
	LD	HL,DBUFF	;Buffer for sector
	CALL	READER
	JR	Z,OK0
	CP	6
	JP	NZ,IOERRA	;Go if error
OK0	EQU	$
;
;
; Read directory records into memory
;
	LD	E,2		;Skip GAT/HIT
	LD	B,24		;Read 24 sectors
	LD	HL,DBUFF
DREAD:	LD	(IY+7),26	;Reset #sectors/trk each time
	CALL	READER		;Read a sector
	JR	Z,OK1		;Go if no error
	CP	6		;Ignore record type
	JP	NZ,IOERRA	;Go if error
OK1:	INC	H		;Bump buffer pointer
	INC	E		;Bump sector number
	DJNZ	DREAD		;Loop till done
;
; Loop through all entries
;
	LD	HL,DBUFF	;Point to first entry
ELOOP	EQU	$
	PUSH	IY		;save
	LD	A,@FLAGS	;SVC #
	RST	@SVC		;fetch pointer
	BIT	0,(IY+'K'-'A')	;break here?
	POP	IY		;restore
	JP	NZ,BABORT	;Abort if set
	LD	B,(HL)		;P/U attributes
	PUSH	HL
	POP	IX		;Move pointer to IX
	PUSH	HL		;Save position
	LD	A,(IX+5)	;Blank name?
	CP	' '		;Dead file if so
	JP	Z,SKIPIT	;Go if dead
;
; Check file's attributes
;
	BIT	7,B		;SYS file?
	JR	Z,NOTSYS	;Go if not
	LD	A,(SPARM)	;S parm given?
	AND	A
	JP	Z,SKIPIT	;Skip file if not
NOTSYS	EQU	$
;
; Check if name matches wildcard
;
NOSIV:	LD	DE,5		;Offset to name field
	ADD	HL,DE
	PUSH	HL		;Compare with pattern
	LD	DE,PATTRN
	LD	B,11
CPLOOP:	LD	A,(DE)		;P/U pattern byte
	INC	DE
	CP	'$'		;Matchall?
	JR	Z,MATCH
	CP	(HL)		;Match?
	JR	NZ,NMATCH	;Go if not
MATCH:	INC	HL
	DJNZ	CPLOOP
NMATCH:	POP	HL		;Z if match, NZ if not
;
	CALL	NOTCHK		;Reverse if NOT entered
	JP	NZ,SKIPIT	;Skip file if no match
;
	LD	DE,FNAME	;Put U/L case in printing
	LD	B,8		;Buffer
MVNAME:	LD	A,(HL)		;Move name
	CP	' '		;Space?
	JR	Z,GOTNAM	;Go if hit one
	INC	HL
	LD	(DE),A		;Put to buffer
	INC	DE
	DJNZ	MVNAME
;
GOTNAM:	LD	C,B		;Offset to ext field
	LD	B,0
	ADD	HL,BC
	LD	A,(HL)		;No extension?
	CP	' '
	JR	Z,GOTEXT	;Go if so
;
	LD	A,'/'		;Put in slash
	LD	(DE),A
	INC	DE
	LD	B,3
EXLOOP:	LD	A,(HL)		;Move extension
	INC	HL
	CP	' '		;Finished?
	JR	Z,GOTEXT
	LD	(DE),A
	INC	DE
	DJNZ	EXLOOP		;Loop till done
;
GOTEXT:	LD	A,ETX		;Put ETX at end 
	LD	(DE),A		;For printing
;
	CALL	MVFNM		;Make u/c in DCB
;
	LD	A,(DPARAM)	;Just reading DIR?
	OR	A
	JR	Z,NODIR		;No, check for write
	CALL	SHOW		;Yes, print entry
	JP	SKIPIT		;And skip copy
;
; Check if file exists on destination disk
;
NODIR:	LD	(DOTLOC+1),DE	;Save this spot
	LD	HL,MPW		;Put in system MPW
	LD	BC,6
	LDIR
	LD	A,(DDRIVE)	;Put in drive spec
	OR	'0'		;Change number to ASCII
	LD	(DE),A
	INC	DE
	LD	A,CR		;Put in CR to end
	LD	(DE),A
	LD	DE,FCB		;Point to start of FCB
	LD	HL,TBUFF	;Point to transfer buffer
	LD	B,0		;OPEN file
;
	LD	A,@OPEN
	RST	@SVC
	LD	B,A		;Save return code
	JR	Z,NORO		;Go if opened okay
	CP	18H		;File not found?
	JP	Z,NORO		;Else an error
	OR	0C0H		;Short msg
	PUSH	BC		;save
	LD	C,A		;pass error code
	LD	A,@ERROR
	RST	@SVC
	POP	BC		;restore
	JP	SKIPIT		;Next file
;
; Check N and O parms
;
NORO:	LD	A,0		;N or O specified?
	AND	A
	JR	Z,CHECKQ	;Go if neither
; check further
	LD	A,(OPARM+1)	;O parm given?
	AND	A
	JR	Z,CKNEW		;Go if not
	XOR	A
	OR	B		;Did file exist?
	JR	Z,CHECKQ	;Go if so (ok)
CKNEW:	LD	A,(NPARM+1)	;N parm given?
	AND	A
	JP	Z,SKIPIT	;Skip file if not
	XOR	A
	OR	B		;Be sure it was new
	JP	Z,SKIPIT	;Go if it wasn't
;
;Ask question if Q parm was given (default)
;
CHECKQ:	LD	A,(QPARM+1)	;Check Q parm
	AND	A
	JR	NZ,QUERY	;Query if so
	LD	HL,CONVS	;"Converting..."
	CALL	DSPLY
	LD	HL,FNAME	;Filename
	CALL	DSPLY
	LD	A,CR		;Carriage return
	CALL	DSP
	JR	TAKE1		;Go & take it
;
QUERY:	LD	HL,CONVQ
	CALL	DSPLY		;Ask question
	LD	HL,QMARK
	CALL	DSPLY
	LD	HL,ABUFF	;Get answer
	LD	B,3
	LD	A,@KEYIN	;SVC #
	RST	@SVC		;get key input
	JP	C,ABORTER	;Abort if BREAK hit
	LD	A,(HL)		;Check for 'Y'
	RES	5,A		;Force upper case
	CP	'Y'
	JP	NZ,SKIPIT	;Skip it if not 'Y'
;
; If file exists, query user
;
	LD	A,(FCB)		;Was file opened ok?
	BIT	7,A		;NZ means file is open
	JR	Z,TAKE1		;Go if it is
;
	LD	HL,EXISTQ
	CALL	DSPLY		;Print question
	LD	HL,ABUFF
	LD	B,3
	LD	A,@KEYIN	;get answer
	RST	@SVC
	JP	C,ABORTER	;Abort if break
	LD	A,(HL)		;Check answer
	RES	5,A		;Force uppercase
	CP	'Y'
	JP	NZ,SKIPIT	;Skip if 'no'
;
; Init file if it didn't exist
;
TAKE1:	LD	DE,FCB		;=>file
	LD	A,(DE)		;Was file opened?
	BIT	7,A
	PUSH	DE
	CALL	NZ,KILLER	;Kill old one to get new LRL
	POP	DE
;
DOTLOC:	LD	HL,0		;Pick up where MPW was
;
	LD	(HL),':'	;Stuff in drivespec
	INC	HL		;Instead
	LD	A,(DDRIVE)
	OR	'0'		;Convert to ASCII
	LD	(HL),A
	INC	HL
	LD	(HL),CR		;Stuff in a CR at end
	LD	HL,TBUFF	;Create file
; fiddle with TRSDOS directory entry
	LD	A,(IX+4)	;P/U Mod II LRL
	LD	B,A		;Save for init
;
	OR	A		;Is it zero?
	JR	Z,LRLOK
; directory is one LRL short if >0
	ADD	A,(IX+3)	;Add one LRL to EOF if >0
	JR	Z,FIXEOF	;If Z, don't add sector
	JR	NC,FIXEOF
; adjust ERN if necessary
	INC	(IX+20)		;Add a sector if needed
	JR	NZ,FIXEOF
	INC	(IX+21)		;Bump high byte if low wraps
FIXEOF:	LD	(IX+3),A	;Store new EOF offset
; create file on LDOS disk
LRLOK:	LD	A,@INIT		;SVC
	RST	@SVC		;open file
	JP	NZ,IOERR	;Go if error
	PUSH	DE		;Change LRL to 0 for copy
	EX	(SP),IX
	RES	7,(IX+1)	;Show full sector ops
	LD	(IX+9),0	;Show LRL=0
	EX	(SP),IX
	POP	DE
;
; Initialize to read from source file
;
TAKE2:	POP	HL		;Point to dir entry
	PUSH	HL
	LD	DE,20D		;Point to ERN
	ADD	HL,DE		;Add offset
	LD	E,(HL)		;P/U ERN
	INC	HL
	LD	D,(HL)		;To DE
	INC	HL		;Leave ptg to extents
	INC	DE		;Adjust for weirdness
	LD	B,0		;# sectors left in extent
	PUSH	DE		;Save ERN
	EXX			;Switch to alternate regs
;
; Preallocate file
;
	POP	BC
	LD	A,B		;Empty file?
	OR	C
	JR	Z,READ		;Go if so
	DEC	BC
	LD	DE,FCB		;Point to LDOS FCB
;
	LD	A,@POSN		;SVC #
	RST	@SVC		;posit to last sector
	JR	Z,OK3
	CP	1CH		;Ignore EOF errors
	JR	Z,OK3
	CP	1DH
	JP	NZ,IOERR
;
OK3:	LD	A,@WRITE	;SVC
	RST	@SVC		;allocate disk space
	JP	NZ,IOERR
	LD	A,@REW		;position to start
	RST	@SVC
	JP	NZ,IOERR
;
; Read sectors
;
READ:	LD	B,0		;Count sectors read
	LD	HL,TBUFF	;Point to transfer buffer
	CALL	DEHIGH		;LD  DE,(HIGH$)
	INC	DE		;Inc D if E=FF
	DEC	D		;256 bytes back
;
GETONE:	CALL	GETSEC		;Get next sector
	JR	NZ,WRITE	;Go if EOF
	INC	B		;Count sector
	CALL	CPHLDE		;Compare HL and DE
	LD	A,0		;No error code
	JR	NC,WRITE	;Go if mem full
	INC	H		;Point to next spot
	JR	GETONE
;
; Write sectors to destination file
;
WRITE:	PUSH	AF		;Save completion type
	LD	DE,FCB		;Point to file fcb
	LD	HL,TBUFF	;Point to transfer buffer
;
WRLOOP:	LD	(FCB+3),HL	;Point FCB to buffer
	LD	A,B		;Zero to write?
	AND	A
	JR	Z,WRDUN		;Go if so
	LD	A,@WRITE	;write to file
	RST	@SVC
	JP	NZ,IOERR
	INC	H		;Adjust buffer pointer
	DJNZ	WRLOOP		;Loop till done
;
; Were we at EOF?
;
WRDUN:	POP	AF		;Restore completion type
	AND	A		;At end of file?
	JR	Z,READ		;Go if not
;
; Copy over EOF offset
; If LRL =0 then add adjust EOF offset
	LD	A,(IX+4)	;Ck lrl
	OR	A		;For 0
	LD	A,(IX+3)	;P/U offset from dir
	JR	NZ,DONT		;Lrl <0 already fixed
	OR	A		;Full sector valid?
	JR	Z,DONT		;Then don't change
	INC	A		;Adjust for weirdness
;
DONT:	LD	(FCB+8),A	;Put into FCB
	LD	A,@CLOSE	;And close the file
	RST	@SVC
	JP	NZ,IOERR
;
; Increment to next entry and loop if not done
;
SKIPIT:	POP	HL
	LD	DE,64D		;64 bytes per entry
	ADD	HL,DE
NOTEOS:	LD	DE,TBUFF	;Done?
	CALL	CPHLDE		;CP HL,DE
	JP	C,ELOOP		;Loop back if not done
;
; Finished with files
;
	LD	A,(DPARAM)	;Reading directory?
	OR	A
	JR	Z,GONOW
	LD	A,(CCOUNT+1)	;Get ending line
	CP	12		;On bottom?
	CALL	NC,@KEY		;Then wait for keypress
GONOW:	LD	A,CR		;Blank line
	CALL	DSP
;
EXIT1:	CALL	BYEBYE		;Restore DCT
	LD	A,@EXIT		;sVC
	RST	@SVC		;back to system
;
QUIT:	CALL	BYEBYE		;Restore DCT
	LD	A,@ABORT	;SVC#
	RST	@SVC
;
; Error routines
;
IOERRA:	OR	40H		;Short message, abort
	PUSH	AF
	PUSH	DE
	CALL	BYEBYE		;Restore DCT
	POP	DE
	POP	AF
	PUSH	BC		;save
	LD	C,A		;pass error code
	LD	A,@ERROR
	RST	@SVC
	POP	BC
	RET
;
IOERR:	OR	0C0H		;Short message, return
	PUSH	BC		;save
	LD	C,A		;pass error code
	LD	A,@ERROR
	RST	@SVC
	POP	BC		;restore
	JP	ELOOP		;Take next file
;
BYEBYE:	PUSH	IY		;Move back DCT
	POP	DE
	LD	HL,SAVDCT	;Point to save area
	LD	BC,4
	LDIR
	INC	HL		;Don't mess with head posn
	INC	DE
	LD	BC,5		;Move everything else
	LDIR	
	RET
;
PERROR:	LD	HL,PMSG
	LD	A,@LOGOT	;display and log
	RST	@SVC
	LD	A,@ABORT	;exit
	RST	@SVC
;
; Sector read routine - from TRSDOS disk
;
GETSEC:	EXX			;P/U alt registers
	LD	A,D		;Any records left?
	OR	E
	JR	NZ,NOTEND	;Go if so
BDSEC:	EXX
	LD	A,1CH		;EOF code
	AND	A
	RET
;
NOTEND:	XOR	A		;Check if used up ext
	OR	B		;Records left in this ext
	JR	NZ,MORE		;Go if not used up
;
	LD	A,(HL)
	CP	0FFH		;Check for FF ext
	JR	Z,BDSEC		;Treat like EOF
	PUSH	DE		;Save DE'
;EXT fields have track # followed by starting gran/# of grans
	LD	D,(HL)		;P/U track number
	INC	HL
	LD	B,(HL)		;P/U other stuff
	INC	HL		;Point to next field
	LD	A,B		;Get starting sector
;
; bits 5-7 have starting position (/5 in sectors)
	RLCA			;Roll to bits 0-2
	RLCA
	RLCA
	AND	7		;Mask other stuff
	LD	E,A		;Multiply by 5
	RLCA			; x2
	RLCA			; x4
	ADD	A,E		;+1=x5
;
	INC	A		;First sector is #1
	LD	E,A		;And move to E reg
	LD	(TRKSEC),DE	;Then store starting posn
;
	POP	DE		;Restore DE'
;
	LD	A,B		;Get number of sectors
	AND	1FH		;Mask junk
	INC	A		;Adjust for 0 offset
	LD	B,A		;Multiply by 5 sectors/gran
	RLCA
	RLCA
	ADD	A,B
	LD	B,A		;And put in B reg
;
; Read sector
;
MORE:	DEC	B		;Count down # sec in ext
	DEC	DE		;Count down # records
	EXX			;Restore primary set
	PUSH	DE		;Save DE
	PUSH	BC		;Save BC
	LD	DE,(TRKSEC)	;P/U track and sector #
	LD	A,(SDRIVE)	;P/U source drive
	LD	C,A		; into C
	LD	(IY+7),26	;Reset #sec/tr each time
	CALL	READER		;Read sector to (HL)
	JR	Z,OK2
	CP	6
	JP	NZ,IOERR
OK2:	INC	E		;Step to next sector
	LD	A,E
	CP	26D		;End of track?
	JR	NZ,NOTEOT	;Go if not
	LD	E,1
	INC	D		;Next track
NOTEOT:	LD	(TRKSEC),DE
	POP	BC
	POP	DE
	XOR	A
	RET
;
; Parsing subroutines
GETDR2:	LD	A,(DPARAM)	;Just want DIR?
	OR	A
	RET	NZ		;Then skip dest drv.
;
GETDRV:	LD	A,(HL)		;Parse drivespec
	CP	':'
	JR	NZ,PERROR	;Go if not
	INC	HL
	LD	A,(HL)		;P/U drivespec
	CP	'0'		;Be sure digit
	JR	C,PERROR
	CP	'7'+1
	JR	NC,PERROR
	INC	HL
	AND	7
	RET
;
SKIPSP:	LD	A,(HL)		;Skip spaces
	CP	' '
	RET	NZ
	INC	HL
	JR	SKIPSP
;
SKIPLT:	LD	A,(HL)		;Skip letters/digits/$
	CALL	CHKLET		;Check letter/digit/$
	RET	NZ
	INC	HL
	JR	SKIPLT
;
MOVELT:	LD	A,(HL)		;Move letters/digits/$
	CALL	CHKLET
	RET	NZ
	INC	HL
	LD	(DE),A
	INC	DE
	JR	MOVELT
;
CHKLET:	BIT	7,A		;Graphic?
	RET	NZ
	CP	'a'		;Lowercase?
	JR	C,NOTLC		;Go if not
	RES	5,A
NOTLC:	CP	'$'		;Dollar sign?
	RET	Z
	CP	'0'		;Digit?
	RET	C		;Return (NZ) if less
	CP	'9'+1
	JR	NC,NOTDIG	;Go if not digit
	CP	A		;Mark as letter/digit/$
	RET
;
NOTDIG:	CP	'A'		;Letter?
	RET	C		;Return (NZ) if less
	CP	'Z'
	RET	NC		;Z if =Z, NZ if >Z
	CP	A		;Z if <Z
	RET
;
SHOW:	PUSH	HL
	PUSH	DE
	PUSH	BC		;Save regs
	LD	C,0		;Init char count
	LD	HL,FNAME
NMDSP:	LD	A,(HL)		;Get a character
	CP	ETX		;Is this the last
	JR	Z,NMEND		;Then quit
	CALL	DSP		;Print it
	INC	C		;Count it
	INC	HL		;Point to next
	JR	NMDSP		;Loop to end
NMEND:	LD	HL,00		;Line/char count
CCOUNT	EQU	$-2
	LD	A,C
	ADD	A,L		;Add in count so far
	LD	L,A		;Store
	LD	A,16		;Max /entry
	SUB	C		;Spaces needed
SPLP:	PUSH	AF		;Save count
	LD	A,' '
	CALL	DSP
	INC	L		;Chars on line now
	LD	A,L		;Get total char count
	CP	62		;End?
	JR	Z,ELINE		;Print CR
	POP	AF		;Count
	DEC	A
	JR	NZ,SPLP		;Print all spaces
;
ESHOW:	LD	(CCOUNT),HL	;Save line/char
	POP	BC
	POP	DE
	POP	HL
	RET
;
ELINE:	LD	A,CR
	CALL	DSP		;Move to next line
	INC	H		;Count lines printed so far
	LD	L,0		;Reset char count
	POP	AF		;Fix stack
	LD	A,15
	CP	H		;OK to scroll?
	JR	NZ,ESHOW	;Done 
	LD	A,@KEY		;else wait for keypress
	RST	@SVC
	CALL	CLS		;Then clear screen
	LD	HL,0		;Reset line/chars
	JR	ESHOW		;And get next
;
;
CPHLDE:	PUSH	HL		;Compare HL and DE
	AND	A
	SBC	HL,DE
	POP	HL
	RET
;
GETHI2	PUSH	HL		;save
	PUSH	BC		;save
	LD	B,0		;init command
	LD	H,B		;init for fetch
	LD	L,B
	LD	A,@HIGH$	;SVC #
	RST	@SVC		;fetch HIGH$
	EX	DE,HL		;DE = high
	POP	BC		;restore
	POP	HL
	RET			;done
;
BABORT:	LD	A,@KBD		;Pull <BREAK> char fm buffer
	RST	@SVC
ABORTER	LD	A,@ABORT
	RST	@SVC
;
; flip Z flag setting if NOT (-) entered with fspec
NOTCHK:	PUSH	AF		;Save flags
	LD	A,(NOTPRM)	;Check for '-'
	OR	A
	JR	Z,NOTNOT	;Don't change
	POP	AF		;Get original flag setting
	JR	Z,SETIT		;Reverse Z flag setting
	XOR	A		;Set Z
	RET
SETIT:	OR	0FFH		;Set NZ condition
	RET
NOTNOT:	POP	AF		;Unchanged
	RET
;
KILLER:	LD	A,@KILL		;Kill old file, then...
	RST	@SVC
;
MVFNM:	LD	HL,FNAME-1	;Move name to FCB
	LD	DE,FCB-1	;Conv to U/C
FIXFCB:	INC	HL		;Bump pointers
	INC	DE
	LD	A,(HL)		;Get char
	CP	'a'
	JR	C,ISUC
	RES	5,A		;Force u/c
ISUC:	LD	(DE),A
	CP	ETX		;Done?
	JR	NZ,FIXFCB	;Loop to end
	RET
;
DSPLY	LD	A,@DSPLY	;sVC #
	RST	@SVC		;display
	RET			;return status
;
CLS	LD	A,1CH		;home cursor
	CALL	DSP		;display
	LD	A,1FH		;clear end of frame
DSP	PUSH	BC		;save
	LD	C,A		;pass char
	LD	A,@DSP		;SVC #
	RST	@SVC		;display
	LD	A,C		;restore char
	POP	BC		;unstack
	RET			;done
;
; Messages and buffers
;
HELLO$	DB	'CONV'
*GET	CLIENT
;
PBLOCK:	DB	'QUERY '
	DW	QPARM+1
	DB	'Q     '
	DW	QPARM+1
	DB	'SYS   '
	DW	SPARM	
	DB	'S     '
	DW	SPARM	
	DB	'OLD   '
	DW	OPARM+1
	DB	'O     '
	DW	OPARM+1
	DB	'NEW   '
	DW	NPARM+1
	DB	'N     '
	DW	NPARM+1
	DB	'DIR   '
	DW	DPARAM
	DB	'D     '
	DW	DPARAM
	DB	0
NOTPRM:	DB	0
DPARAM:	DW	0		;Dfault OFF
SPARM:	DW	0		;Default OFF
QPARM:	DW	-1		;Default ON
	DB	'V20'		;Show version 2.0
PATTRN:	DB	'$$$$$$$$'
PATEXT:	DB	'$$$'
MPW:	DB	'.EZTO:'
PMSG:	DB	'Parameter error',CR
QMARK:	DB	'? ',ETX
EXISTQ:	DB	'  File exists -- replace it? ',ETX
CONVS:	DB	'Converting file ',ETX
CONVQ:	DB	'Convert file '
FNAME:	DS	32		;Must follow CONVQ
FCB:	DS	32
SDRIVE:	DS	1
DDRIVE:	DS	1
TRKSEC:	DS	2
ABUFF:	DS	5
SAVDCT:	DS	10
DBUFF	EQU	$<-8+1<8
;
;
TBUFF	EQU	24*100H+DBUFF	;Rm for 24 sectors of directory

	END	BEGIN
