@echo off
CALL %~dp0SET_TRS80GP
set SOUND=
set DISKS=-d0ds -d L631BOOT_631N.DSK -d1ds -d L631UTL2.DSK -d2ds -d L631SYS2.DSK -d3ds -d L631BIN2.DSK
set FREHD=-frehd-dir frehd

start /wait %TRS80GP% -haste -m2 -50 -vs -win full -ee %SOUND% %DISKS% %FREHD% %GRAF% ^
 -iw "Date" -iy "%%m/%%d/%%y\r%%h:%%i:%%s\r" ^
 -iw "Ready" -iy "DO BUILDNL"

echo Job done.
