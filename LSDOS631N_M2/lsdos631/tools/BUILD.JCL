. BUILD/JCL - build LS-DOS 6 with listing output
purge /PRN:1 (q=n)
system (drive=0,wp)
cls
. . . . . . . . . . . . . . . . . . . . . . . .
. BUILD LS-DOS 6.3.1 EXECUTABLES WITH LISTING .
. . . . . . . . . . . . . . . . . . . . . . . .
device
. Check that:
.   :0 WP is write protected and contains 
.         MRAS/CMD, XREF/CMD, EXPORT/CMD, LS/CMD and CLKLD63X/CMD
.   :1    = L631UTL2
.   :2    = L631SYS2
.>> :3    = L631BIN2 - target build disk
. !! This script will DESTROY all files on drive :3 !!
//PAUSE => Press <BREAK> to stop now or <ENTER> to continue.
attrib :3 (name="L631BIN2")
purge :3 (inv,sys,q=n)
do build631 (ALL,LP,NOSTOP)
