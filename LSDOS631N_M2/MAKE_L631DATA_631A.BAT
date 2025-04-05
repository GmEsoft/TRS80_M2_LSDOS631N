@echo off
CALL %~dp0SET_TRS80GP
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk

set DISKS=-d :ld2 -d %DISK1% -d2ds -d dmk-ds#77 -d3ds -d dmk-ds#77
set FREHD=-frehd-dir frehd
call :del trs80-disk*.dsk

start /wait %TRS80GP% -haste -batch -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "11/11/11\r\r"^
 -iw "Ready" -i "import2 -n mkbin.jcl mkbin/jcl:1\r"^
 -iw "LS-DOS Ready" -i "do mkbin (A)\r"

if exist trs80-disk3-?.dsk move /y trs80-disk3-?.dsk L631BIN2.DSK
copy L631BIN2.DSK L631UTL2.DSK
copy L631BIN2.DSK L631SYS2.DSK

call :del trs80-disk?-?.dsk

set DISKS=-d0ds -d L631BOOT_631A.DSK -d1ds -d L631UTL2.DSK -d2ds -d L631SYS2.DSK -d3ds -d L631BIN2.DSK

start /wait %TRS80GP% -haste -batch -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "11/11/11\r\r"^
 -iw "Ready" -i "import2 -n mksysutl.jcl mksysutl/jcl:1\r"^
 -iw "LS-DOS Ready" -i "do mksysutl (A)\r"

call :del trs80-disk?-?.dsk

start /wait %TRS80GP% -haste -batch -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "11/11/11\r\r"^
 -iw "LS-DOS Ready" -i "do IMPORT\r"^
 -iw "TAPE100/ASM"  -iw "Job done" -i "\x03"
goto :eof

:del
if exist %1 del /q %1
goto :eof
