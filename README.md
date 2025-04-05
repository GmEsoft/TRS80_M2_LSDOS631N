LSDOS631N for TRS-80 Model II
=============================

TRS-80 LS-DOS 6.3.1 Level M for Model II source files with bug fixes and date support up to 2079
------------------------------------------------------------------------------------------------

This repository contains the source files to build a working version of LS-DOS 6.3.1 Level N for Model II.

This version is based on the official LS-DOS 6.3.1 Level-1A for Model II, with all patches issued for
the Model 4 version up to Level-1L. I applied 2 additional patches to fix some bugs in the Keyboard and
Tick interrupt handlers, leading to a system crash if the stack pointer was above x'F800'. The interrupt
handlers were enabling the Video RAM in the area x'F800'-x'FFFF' without moving SP to a safe location,
and made the system crash.

I took some Model II code from the archive from Frank Durda IV at this address (the original URL seems now invalid):
http://archives.oldskool.org/pub/drivers/Tandy/nemesis.lonestar.org/computers/tandy/software/os/logical_systems/lsdos6/src631/

The original source files come from the archive `Source code for LS-DOS 6.3.1H (19xx)(-)[DSK]`
and were made available by Peter W. Cervasio. Here is the text of the `HowTo.txt` notice included in the archive:

```
LS-DOS 6.3.1 Source Code
========================

Copyright 1982-1984, 1986, 1990 by MISOSYS, Inc.

The permission statement from Tim Mann's web page says the following
about the MISOSYS software available for download:

=====================================================================
Roy Soltoff holds the copyright to the software and documentation in
the list below; notices that name other authors are outdated. Roy
grants free permission to everyone to download and use this software
and documentation and to redistribute it to others, provided this
notice is retained. All other rights are reserved.
=====================================================================

Typed in (and enhanced) by Pete Cervasio (cervasio@airmail.net)
Changes are copyright 1997-98 Peter W. Cervasio.

Permission to do whatever you want with my changes is granted, as long
as my copyright notice is left intact.

[Minor edits to this file made 1-12-98 by Tim Mann.]

Introduction stuff
==================

The files in this package are the complete source code to the LS-DOS
version 6.3.1 operating system for the TRS-80 Model 4.  I started by
typing in the source listings from "The Source".  I wound up moving
to LS-DOS 6.3.1 in the middle of the first part of the SYSx/ASM set of
files.  I also realized that I should be using MISOSYS' PRO-DUCE to
generate the opcodes, and then massaging the resulting /ASM files until
they have meaningful labels and comments.  For the most part, the
comments from "The Source", volumes 1 through 3, are what you will see,
except I may have changed the wording somewhat.  When I was doing this
I had NO idea that it would wind up on Tim Mann's web page with the
rest of the MISOSYS software.  Because of that, I was not strict in
my typing of the comments, and didn't make sure that every single
line had the exact same wording as "The Source".  Where there are
major changes in version 6.3.x, as compared to what was listed for
version 6.2, I have tried to comment the code as well as I can figure
it out.

There may be a few places where a piece of code says isn't commented
and a similar piece somewhere else is fully documented.  That's
probably because I decided to actually figure it out later and didn't
update the comments in all locations.  Some places have the 6.3.1
sections marked with ";---> 6.3.1 change" and ";<--- 6.3.1 change".
These flag the start and end of code that's different from the code
listed in "The Source".  Not every change has this flag, though.

Several files have much more commenting than the original listing had.
This is especially true of the SYSINFO sector in SYSRES/ASM where I
have documented how backup-limited diskettes work.  This was done
for informational purposes only, by the way.

In addition, I have included the new logo which I use on my own system.
If you look in SYSRES/ASM and change the equate as documented there,
you can try out my changes.  They don't adversely affect the operation
of the system in any way, as far as I have been able to tell.  It just
makes the bootup look a little nicer.  Some may have flashbacks to the
boot screen of DOSPLUS, but that's their problem.

But wait, there's more!  As an extra added bonus for downloading now,
I have included the /JCL files I used to reassemble the operating
system under Jeff Vavasour's wonderful Model 4 emulator (which is
available from Computer News 80).  These JCL files can route the
assembler's listing to /PRN files and then export them to MSDOS as
each file is completed, if you choose.  You'll probably need to do
some editing of them to reflect your systems directory structure.

Still not convinced?  Well, check out the BLDLIBS/CMD file (and source
in BLDLIBS/CCC) and the various /DAT files that go with it.  This handy
little utility re-generates the system libraries (SYS6, 7 and 8) from
the individual /CMD files!  Yes, that's right.  You get all this for
the amazing low price of whatever it cost you to log on and download it.

Send $9.95 for records or $12.95 for 8-track tapes to...

Back to seriousness
===================

As supplied, this set of source will assemble to LS-DOS 6.3.1 as found
on Tim's site.  With one exception, all the files come out as byte-for-
byte duplicates of the files on the LD4-631.DSK disk image.  That one
exeption is because SYS8/SYS has had a named patch applied to the SETKI
routine.

LATE BREAKING NEWS!

Just before sending this off for the web site, I figured out what I had
to do to get an exact byte-for-byte copy of SYS8 going.  After the file
LBSETKI/ASM is assembled, a SETKI1/FIX patch is applied to the resulting
/CMD file before the library overlay is built.  This means that once the
three /JCL files have been run, you'll have an exact copy of LS-DOS.

Since "The Source" was published, several files have been added to the
LS-DOS distribution disk.  These include BREF/CMD, DATECONV/CMD,
DISKCOPY/CMD and TED/CMD.  I have disassembled the DATECONV and
DISKCOPY utilities and included their source.  I have also done the
source for HELP/CMD, which is rather confusing in places.  One day
I may get around to doing BREF and TED, but it won't be soon.

Distribution files
==================

This source is being distributed in two forms.  One is 80 track DSDD
disk images for Jeff Vavasour's Model 4 emulator.  These are all set
to plug into drives :1 and :2.  The other form is .ZIPs of
the individual files in MSDOS format, with CR/LF as line ends.

    Disk Image Distribution:
    ------------------------
    L631UTL.DSK - This disk image contains the /JCL files, as well
                  as the BLDLIBS program and data files.  Also, it
                  holds the source for the system utilities, such as
                  BACKUP and FORMAT.  Also, my emulator utility to
                  set the system time from the PC's clock.
                  The JCL files are set up for this to be in drive :1

    L631SYS.DSK - This disk image holds the operating system's /ASM
                  files.  All the source for BOOT/SYS and SYS0/SYS
                  through SYS13/SYS is on this one disk.  This goes
                  in drive :2 for the /JCL files.

    Individual file distribution:
    -----------------------------
    This distribution has all the files from inside the two .DSK
    images, extracted into two subdirectories and converted to the
    MS-DOS CR/LF end-of-line convention.  This distribution is useful
    if you want to read the sources under MS-DOS or Unix; the .DSK
    distribution is useful if you want to reassemble them under LS-DOS.

Both distributions contain my JCL files as well as the source code
and data files for the utility I wrote to rebuild the library command
overlays from the individual /CMD files.

Using the Model 4 emulator to assemble the operating system
===========================================================

Put a LS-DOS system disk in drive :0.  Make sure it contains MRAS/CMD
and XREF/CMD, from the MISOSYS PRO-MRAS assembler package.  It should
also have CD/CMD and EXPORT/CMD from Jeff's utilities, if you're going
to be exporting the /LST files out to MSDOS files.

Set up drives :1, :2 and :3 as follows:

    :1 - L631UTL.DSK - JCLs & Utilities & LS-DOS utility source code.
    :2 - L631SYS.DSK - System source code files.
    :3 - Create a new, blank .DSK file and format it as 80 tracks, DSDD.

From a DOS ready prompt, enter "DO BUILD631".  The parameters this
/JCL file can take are:

	V="mm:ss" - Set the timestamp of the assembled files
	            The default is "06:31".
	ALL       - Assemble the lib commands and utilities also.
	            The default is not to do this.
	LP        - Generate the /PRN files and export them to MSDOS
	            The default is not to do this.
	NOSTOP    - Keep on going without pause
	            The default is to wait for a keypress at the
	            beginning of each JCL file.

If you didn't supply the (ALL) parameter, you'll want to enter the
command "DO BUILDLIB" to assemble the files that make up the SYS6, SYS7
and SYS8 library overlays and generate the ISAM files using my
BLDLIBS/CMD program.  There is some documentation on the BLDLIBS
program, if you want to know more about it.  See the file BLDLIBS/TXT
for information.  You'll also need to "DO BUILDUTL" to assemble all of
the system utilities.

When finished, you need to copy the files to a system disk to check them
out.  There are two /JCL files on the L631UTL disk to handle this task
for you.  A third is handy to check the assembled files against the ones
on an original LS-DOS 6.3.1 disk.

The first is GETNEW/JCL, which copies the operating system /CMD
files from drive :3 to the appropriate /SYS files on drive :2.  If you
do not want to use my drive assignments, the DO file takes (S=x,D=y)
parameters to set the source and destination drives.  Omit the colon, if
you use these.

The second JCL file is GETUTILS.  It does the same thing for the LS-DOS
utilities, and also has the S= and D= parameters.

The third JCL file is called COMPARE/JCL - it uses COMP/CMD to compare
the files on drive :3 to the appropriate files on drive :2.  It pauses
after every compare so you can see that there are no differences (other
than the size of BOOT/SYS compared to LOWCORE/CIM).  This hasn't been
fixed to handle the S= and D= parameters, yet.

Finally, move that disk image to drive :0 and reboot the emulator.
Congratulations, you're now running your freshly assembled LS-DOS
version 6.3.1!

Using a real Model 4 to assemble the operating system
=====================================================

Uh... gee.. I haven't done that yet.  I imagine you'll want to split
the files up between a bunch of diskettes, and chop up the JCL files
files so they match the disks.  If you have a hard disk system, you
would probably copy all the files to your hard disk and massage the
/JCL files to your liking and go from there.  Unfortunately, since
my P166 acts like a 22.5 MHz Model 4 using the emulator - I just don't
have much pushing me to test this configuration.  :)

That's it.

Best regards,
Pete Cervasio (cervasio@airmail.net)
```

Pete Cervasio's archive corresponds to the US flavor of LS-DOS 6.3.1H for Models 4
and 4P.

I incorporated the changes by Matthew Reed, converting his patch files to
Z-80 code with conditional assembly. This corresponds to LS-DOS 6.3.1L, and allows for
date support up to 31-12-2079.

The bug fixes for the interrupt handlers have been applied to `kidvr2.asm` (the
keyboard interrupt handler) and to `clock2.asm` (the clock tick interrupt handler).

To select the version level (H or L) and the keyboard language (US/FR/GE), I added a
configuration file `BUILDVER/ASM` where the conditional assembly flags can be configured.

```
@MOD2   EQU     -1              ; Set MOD2 true
@MOD4   EQU     -0              ; Set MOD4 false
;
@DOSVER EQU     631             ; Set DOS Version 6.3.1
@DOSLVL EQU     'N'             ; Set DOS Level L-?(-2079) or A-H(-2011)
;
;       Define switches for international or domestic
;
@GERMAN EQU     0               ; -1 to select German keyboard layout
@FRENCH EQU     0               ; -1 to select French keyboard layout
;
        END
```

I also added the missing `END` statements at the end of the `/ASM` files. This was causing
errors during assembly when those files were included using `*GET` statements.


The source files are packaged in plain ASCII files in the folder `LSDOS631N_M2/lsdos631`.

The instructions to build the system disk images are detailed [HERE](LSDOS631N_M2/BUILD.md).

Some additional tools are needed to build the system:
- [TRS80gp](http://48k.ca), a TRS-80 emulator by George Phillips, to assemble the source code and 
  create the DMK images. The emulator can be downloaded by running the script `get_trs80gp.sh`.
- [HxC Floppy Emulator software](https://hxc2001.com/download/floppy_drive_emulator/) from HxC2001, by
  Jean-Francois Del Nero, to convert the DMK images to HFE images for the HxC Floppy Emulator for
  the real Model II hardware. The software can be downloaded by running the script `get_hxcfe.sh`.

That's it.  Enjoy !

Best regards,

Michel Bernard (michel_bernard at icloud.com)


Credits
-------

- **Frank Durda IV** for the LS-DOS 6.3.1 Source Code Restoration Project;
- **George Phillips** for the TRS80gp emulator, the only emulator to my knowledge capable of
  emulating TRS-80 Models II, 12, 16 and 6000;
- **Pete Cervasio** for the original LS-DOS 6.3.1 complete build system;
- **Jean-Francois Del Nero** for the HxC-2001 Floppy Emulator software;
- **Erwin Waterlander**, **Christian Wurll**, **Bernd Johannes Wuebben** and **Benjamin Lin**
  for the `dos2unix` et al. text format conversion tools;
- **Matt Boytim** for the testing of the new LS-DOS 6.3.1N system on real hardware.

Many thanks to all of them !
