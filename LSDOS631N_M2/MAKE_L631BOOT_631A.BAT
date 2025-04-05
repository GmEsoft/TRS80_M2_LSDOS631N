@echo off
copy l2-631a-ds.DMK L631BOOT_631A.DSK
CALL %~dp0SET_TRS80GP
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk
set DISKS=-d0ds -d L631BOOT_631A.DSK -d %DISK1%
set FREHD=-frehd-dir frehd
@echo on
start %TRS80GP% -haste -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF% -itime 0 ^
 -iw "Date" -iy "11/11/11\r\r" ^
 -iw "Ready" -i "ATTRIB :0 (NAME=\"L631BOOT\")\r" ^
 -iw "Ready" -i "IMPORT2 -n IMPTOOLS.JCL\r" ^
 -iw "Ready" -i "DO IMPTOOLS\r" -iw "Job done" -iw "Ready" ^
 -iw "Ready" -i "DO SYSGEN\r"   -iw "User configuration built" -iw "Ready" ^
 -iw "Ready" -i "BACKUP /CMD:1 :0\r" -iw "Backup complete" -iw "Ready" ^
 -iw "Ready" -i "CAT 0\r"
@echo off
