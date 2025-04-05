. GET4/JCL - Get LS-DOS system from Model 4 L631BIN
system (drive=2,disable,driver="FLOPPY")
1
3
system (drive=3,disable,driver="FLOPPY")
0
4
purge system/jcl:2 (q=n)
system (drive=0,wp)
system (drive=1,wp)
system (drive=3,wp)
cls
. . . . . . . . . . . . . . . . . .
. GET NEW LS-DOS 6.3.1 BOOT DISK  .
. . . . . . . . . . . . . . . . . .
device
. Check that:
.   :0 WP is write protected and contains 
.         MRAS/CMD, XREF/CMD, EXPORT/CMD, LS/CMD and CLKLD63X/CMD
.   :1 WP = L631UTL2
.>> :2    = L631NEW2 - target boot disk (use bootable copy of LD4-631 disk !)
.   :3 WP = L631BIN - build output disk (from Model 4 !)
. !! This script will DESTROY all files on drive :2 !!
//PAUSE => Press <BREAK> to stop now or <ENTER> to continue.
attrib :2 (name="L631NEW2")
//include GETUTILS/JCL
//include GETNEW/JCL
//EXIT
