@echo off
copy l2-631a.DMK L631NEW2.DSK
CALL %~dp0SET_TRS80GP
set SOUND=
set DISKS=-d0ds -d L631BOOT_631A.DSK -d1ds -d L631UTL2.DSK -d L631NEW2.DSK -d3ds -d L631BIN2.DSK
set FREHD=-frehd-dir frehd

start %TRS80GP% -haste -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF% -itime 0 ^
 -iw "Date" -iy "11/11/11\r%%h:%%i:%%s\r" ^
 -iw "Ready" -i "DO GET\r" ^
 -iw "ENTER" -i "\r" ^
 -iw "//pause" -i "\r" ^
 -iw "Job done" -ix

echo Job done.
