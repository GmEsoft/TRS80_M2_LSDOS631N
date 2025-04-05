@echo off
CALL %~dp0SET_TRS80GP
CALL %~dp0SET_HXCFE
if /I "%1" == "hxc" goto :hxc
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk
set DISKS=-d L631NEW2.DSK -d %DISK1% -d2ds -d dmk-ds#77
set FREHD=-frehd-dir frehd
call :del trs80-disk*.dsk

start /wait %TRS80GP% -haste -batch -ee -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "%%m/%%d/%%y\r%%h:%%i:%%s\r" ^
 -iw "Ready" -i "import2 -n mkboot2d.jcl mkboot2d/jcl:1\r"^
 -iw "LS-DOS Ready" -i "do mkboot2d (A)\r"

if exist trs80-disk1-?.dsk move /y trs80-disk1-?.dsk m2-lsdos-util.dmk
if exist trs80-disk2-?.dsk move /y trs80-disk2-?.dsk l2-631n-ds.dmk
call :del trs80-disk?-?.dsk 2>nul

:hxc
%HXCFE% -finput:l2-631n-ds.DMK -conv:IMD_IMG -foutput:l2-631n-ds.IMD
%HXCFE% -finput:l2-631n-ds.IMD -conv:HXC_HFE -foutput:l2-631n-ds.HFE
goto :eof

:del
if exist %1 del /q %1
goto :eof
