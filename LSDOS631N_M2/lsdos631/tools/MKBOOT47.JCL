. MKBOOT2S/JCL -- Format :2 as 8" SS DD
system (drive=2,disable,driver="FLOPPY")
1
3
memory(a="A",b=34)
backup sys/sys:0 :2 (s,i)
free :2
//if -A
//pause
//end
memory(a="A",b=1)
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
backup :0 :2 (New)
free
free :2
//if -A
//pause
//end
purge system/jcl:2 (q=n)
attrib :2 (name="LSDOS631")
dir :2
//if -A
//pause %1B%0DPress ENTER
//else
.DONE.
BASIC
OUT 71,128
//end
