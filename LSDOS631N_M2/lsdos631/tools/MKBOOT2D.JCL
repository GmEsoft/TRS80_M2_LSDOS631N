. MKBOOT2D/JCL -- Format :2 as 8" DS DD
system (drive=2,disable,driver="FLOPPY")
1
3
format :2 (N="L631BOOT",M="PASSWORD",DDEN,SIDES=2,STEP=2)
memory(a="A",b=36)
backup sys/sys:0 :2 (s,i)
free :2
//if -A
//pause
//end
memory(a="A",b=32)
backup /OV:0 :2 (i)
backup /CMD:0 :2 (i)
backup /DCT:0 :2
backup /DVR:0 :2
backup /FLT:0 :2
backup /HLP:0 :2
free :2
//if -A
//pause
//end
memory(a="A",b=2)
backup :0 :2 (New)
free
free :2
//if -A
//pause
//end
purge SYSTEM/JCL:2 (Q=N)
attrib :2 (name="LSDOS631")
dir :2
//if -A
//pause %1B%0DPress ENTER
//else
.DONE.
BASIC
OUT 71,128
//end
