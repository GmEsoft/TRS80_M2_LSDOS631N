@echo off
echo Running emulator
CALL %~dp0SET_TRS80GP
set SOUND=
set DISK1=:lu2
if exist m2-lsdos-util.dmk set DISK1=m2-lsdos-util.dmk
set DISKS=-d0ds -d l2-631a-ds.dmk -d %DISK1%
set FREHD=-frehd-dir frehd
start %TRS80GP% -m2 -50 -vs -win full %SOUND% %DISKS% %FREHD% %GRAF%^
 -iw "Date" -iy "11/11/11\r%%h:%%i:%%s\r"
echo Job done.
