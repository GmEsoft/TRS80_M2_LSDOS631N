. MKBOOT2D/JCL -- Format :3 as 8" DS DD
system (drive=2,disable,driver="FLOPPY")
1
3
system (drive=3,disable,driver="FLOPPY")
1
4
format :3 (N="L631BIN2",M="PASSWORD",DDEN,SIDES=2,STEP=2)
BASIC
OUT 71,128
