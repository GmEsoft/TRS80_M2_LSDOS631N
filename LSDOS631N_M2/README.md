LS-DOS 6 for Model II
=====================


Info
----

- Master password in DIR/SYS at offset CE-CF (LSB-MSB)
- Model II LS-DOS Master Password: `system6`
- LS-DOS Old Master Password: `lsidos`
- (Almost) complete source code [here](http://archives.oldskool.org/pub/drivers/Tandy/nemesis.lonestar.org/computers/tandy/software/os/logical_systems/lsdos6/src631/).


Bugs in LS-DOS 6.3.1 Level-1A for Model II
------------------------------------------

- Keyboard interrupt crashes if the application stack is above $F800. Fixed in Level-M.
- Clock, Trace and Alive crash if the application stack is above $F800. Fixed in Level-N.


Password Hashes
---------------
- PASSWORD = 42E0
- LSIDOS   = 29BA
- SYSTEM6  = 71F4
- S0LT0FF  = DDD5
- UTILITY  = AEBF
- FILTER   = 98CD
- DRIVER   = 1F51


Revisions history
-----------------

- 6.1.0
- 6.1.1
- 6.2.0
- 6.2.1: Last official TRSDOS 6
- 6.3.0: LS-DOS 6 by Logical Systems
- 6.3.1: LS-DOS 6 by Misosys
- 6.3.1A: Last "Official" LS-DOS 6.3 for Model II
- 6.3.1B: Last "Official" LS-DOS 6.3.1 distribution for Model 4

Patches C thru F were published in TMQ IV.iv, page 32 (NOTE: the 
patch addresses listed for SPOOL in SPOOL1/FIX are 19H high).
- 6.3.1C: SETKI patches
- 6.3.1D: DIR patches
- 6.3.1E: DIR and MEMDISK/DCT patches (LSIDOS->SYSTEM6)
- 6.3.1F: SPOOL patches

Patches G and H were published in TMQ V.i, pages 10 and 18/19.
- 6.3.1G: //KEYIN, DIR and DO* patches
- 6.3.1H: MEMORY patches

Unidentified patches except L for dates until 2079
- 6.3.1I
- 6.3.1J
- 6.3.1K
- 6.3.1L: Support for years until 2079 (Matthew Reed)

Bug fixes and other improvements by GmEsoft.
- 6.3.1M: 
  - Fixed the bug in the keyboard interrupt handler, not moving the
    stack pointer in a safe area when enabling the Video RAM in
    the Z-80 address space;
  - Enlarged the cursor vertically by 1 pixel, to improve the
    visibility of the "small" cursor.
- 6.3.1N:
  - Fixed the bug in the CLOCK, ALIVE and TRACE routines
    (triggered by the tick interrupt handler), not moving the
    stack pointer in a safe area when enabling the Video RAM in
    the Z-80 address space.


Fixes to LS-DOS 6.3.1
---------------------

### TMQ Vol IV.iv

Fm MISOSYS, Inc: Here's all of the fixes installed onto LSDOS
6.3.1 disks to date. Note that the "level" letter advanced
by one character for each fix installed. If, for instance, you see
"Level 1D" when you boot your 6.3.1, you would need to apply
patches starting from FIX631D/JCL. Note also that the level
letter is stored in BOOT/SYS. If you are patching a disk (i.e. a
hard drive system partition) formatted with 6.3.0 or earlier, the
password on the BOOT/SYS file is "LSIDOS"; make any
change to the fix as necessary.


```
. FIX631A/JCL - 03/08/90 - Cause FORMAT to write all sectors of DIR cyl
. Apply via, DO FIX631A (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
patch boot/sys.system6:#d# (d02,1f=42:f02,1f=41)
patch format/cmd.utility:#d# (d03,7f=21:f03,7f=32)
//exit
```

```
. FIX631B/JCL - 04/03/90 - Add missing code to SETKI
. Apply via, DO FIX631B (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
patch boot/sys.system6:#d# (d02,1f=43:f02,1f=42)
patch sys8/sys.system6:#d# setki1/fix
//exit
```

```
. SETKI1/FIX - Adds missing code to SETKI
. Use with FIX631B/JCL
LB3
X'2583'=96
X'258E'=3E 60 EF 50 59 79 B7 C9
. Eop
```

```
. FIX631C/JCL - 04/18/90 - Minore correction to DIR
. Apply via, DO FIX631C (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
patch boot/sys.system6:#d# (d02,1f=44:f02,1f=43)
patch sys6/sys.system6:#d# dir1/fix
//exit
```

```
. DIR1/FIX - 04/18/90 - Patch to LS-DOS 6.3.1 DIR command
. Corrects abort file with ext>4 and (O=N)
. Apply via DO FIX631C
D07,D3=DC 04
F07,D3=76 2D
D0B,64=DC 04
F0B,64=76 2D
D0B,9E=FD E5 CD 76 2D
F0B,9E=2B 3E 65 EF 7E
D0B,D1=C3 7C 2D 00
F0B,D1=FD CB 08 66
D10,0C=2B 3E 65 EF 7E C9 FD CB 08 66 FD E1 C3 4F 29
F10,0C="JanFebMarAprMay"
. Eop
```

```
. FIX631D/JCL - 04/30/90 - Minor correction to DIR & Memdisk/DCT
. Corrects exit code for DIR; BOOT/SYS & DIR/SYS passwords in Memdisk.
. Apply via, DO FIX631D (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
PATCH SYS6/SYS.SYSTEM6:#D# DIR2/FIX
PATCH MEMDISK/DCT.DRIVER:#D# (D04,40=F4 71:F04,40=F6 37)
PATCH MEMDISK/DCT.DRIVER:#D# (D04,60=F4 71:F04,60=F6 37)
PATCH BOOT/SYS.SYSTEM6:#D# (D02,1F=45:F02,1F=44)
//exit
```

```
. DIR2/FIX - 04/27/90 - Corrects exit code of DIR in 6.3.1 1D
. Apply via PATCH SYS6/SYS.SYSTEM6 DIR2
D08,B6=21 00 00 C8 3A 2F 26 0C B9 30 EB
F08,B6=67 6F C8 3A 2F 26 0C B9 D2 32 24
. Eop
```

```
. FIX631E/JCL - 04/30/90 - Corrects release of banks > 7 in SPOOL
. Apply via, DO FIX631E (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
PATCH SYS8/SYS.SYSTEM6:#D# SPOOL1/FIX
PATCH BOOT/SYS.SYSTEM6:#D# (D02,1F=46:F02,1F=45)
//exit
```

```
. SPOOL1/FIX - 04/30/90 - Corrects release of banks > 7
. Apply to SYS8/SYS.SYSTEM6
D1F,A5=21;F1F,A5=CA
D20,1E=1F;F20,1E=07
D20,24=CD EF 29;F20,24=32 8C 2A
D21,82=69 26 00 11 8C 2A C5 06 02 3E 5F EF C1 C9;F21,82="Spooler alread"
D22,24="x freed  ";F22,24=" released"
. Eop
```

```
. FIX631F/JCL - 07/16/90 - Corrects three minor problems in 6.3.1F
. //KEYIN of JCL now accepts 79 cpl + CR instead of 79 cpl including CR
. DIR now displays header of disk formatted when DATE was not set
. DO * now finds a SYSTEM/JCL file on a drive other than :0
. Apply via, DO FIX631F (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
PATCH SYS11/SYS.SYSTEM6:#D# (D01,2A=50:F01,2A=4F)
PATCH SYS11/SYS.SYSTEM6:#D# (D01,CE=50:F01,CE=4F)
PATCH SYS6/SYS.SYSTEM6:#D# (D07,F3=7A:F07,F3=3C)
PATCH SYS6/SYS.SYSTEM6:#D# USING DO1/FIX
PATCH BOOT/SYS.SYSTEM6:#D# (D02,1F=47:F02,1F=46)
//exit
```

```
. DO1/FIX - 07/16/90 - Patch to LS-DOS 6.3.1 DO command
. Allows DO * to find a SYSTEM/JCL file on a drive other than :0
. Apply via DO FIX631F
D2D,AB=CD AC 2A
F2D,AB=32 EB 29
D33,0B=03
F33,0B=3A
D33,AD="Bad JCL format, process aborted"
F33,AD="Invalid JCL format, processing "
D33,CC=0D 67 2E 3A 22 EA 29 C9
F33,CC=61 62 6F 72 74 65 64 0D
. Eop
```


### TMQ Vol V.i

Fm MISOSYS, Inc: Thanks for all the
fixes, especially the MEMORY command
fix, as it saved me a little bit of work. No
one ever reported that cosmetic error which
would occur if the MEMORY display
used more than one video screen; that's a
lot of installed filters! But there were two
things about it which I didn't like. First,
there is a 32-byte data space starting at
X'2984' which you would not necessarily
have known about without looking at the
source code. Your patch with the FIX
code at X'29A0' could have been overwritten
when that data space was used. I
also like to spend more time squeezing a
patch in by direct overwrite than by extending
a library module with L-verb patch
code. Fortunately, I was able to reduce the
patch length by putting some of it in the
"No memory space..." message. Here's
the official patch.


```
. FIX631G/JCL - 08/27/90 - Corrects MEMORY command display when the
. information uses more than one screen.
. Also correct MEMDISK/DCT password to ".DRIVER"
. Apply via, DO FIX631G (D=d) where "d" is drive to patch
//if -d
//. Must enter drive to patch!
//quit
//end
ATTRIB MEMDISK/DCT.UTILITY:#D# (O="DRIVER")
PATCH SYS6/SYS.SYSTEM6:#D# USING MEMORY1/FIX
PATCH BOOT/SYS.SYSTEM6:#D# (D02,1F=48:F02,1F=47)
//exit
```

```
. MEMORY1/FIX - 08/27/90 - Patch to LS-DOS 6.3.1 SYS6/SYS
. Patch cleans up video screen when data goes to 2nd screen.
. Apply via DO FIX631G (D=d) ... see FIX631G/JCL
D04,63=18;F04,63=17
D04,6E=7F;F04,6E=0C
D04,DB=15;F04,DB=0F
D04,F2=CD 9C 27 C3 6A 27;F04,F2="No mem"
D04,F8="No memory";F04,F8="ory space"
. Eop
```
