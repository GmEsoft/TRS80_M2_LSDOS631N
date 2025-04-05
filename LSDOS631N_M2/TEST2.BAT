@echo off
CALL SET_TRS80GP
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk
set DISKS=-d0ds -d L631NEW2.DSK -d %DISK1%
set FREHD=-frehd-dir frehd
start /wait %TRS80GP% -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF% ^
 -iw "Date" -iy "%%m/%%d/%%y\r%%h:%%i:%%s\r" ^
 -iw "LS-DOS Ready" -iy "dir /CMD:0\r"

echo Job done.
