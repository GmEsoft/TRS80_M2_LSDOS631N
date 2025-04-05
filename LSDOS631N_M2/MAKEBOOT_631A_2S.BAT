@echo off
CALL %~dp0SET_TRS80GP
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk
set DISKS=-d :ld2 -d %DISK1% -d2ds -d dmk-ds#77
set FREHD=-frehd-dir frehd
call :del trs80-disk*.dsk
start /wait %TRS80GP% -haste -batch -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "11/11/11\r\r"^
 -iw "Ready" -i "import2 -n mkboot2d.jcl mkboot2d/jcl:1\r"^
 -iw "LS-DOS Ready" -i "do mkboot2d (A)\r"
if exist trs80-disk1-?.dsk move /y trs80-disk1-?.dsk m2-lsdos-util.dmk
if exist trs80-disk2-?.dsk move /y trs80-disk2-?.dsk l2-631a-ds.dmk
call :del trs80-disk?-?.dsk
goto :eof

:del
if exist %1 del /q %1
goto :eof
