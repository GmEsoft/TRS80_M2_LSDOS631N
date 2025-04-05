@echo off
set FREHD=%~dp0frehd
set DOS2UNIX=%~dp0Tools\dos2unix
if not exist %FREHD% mkdir %FREHD%
cd lsdos631
for %%F in (*.ASM) DO (
  %DOS2UNIX% -n -k -f %%F %FREHD%\%%F
)
cd libcmds
for %%F in (*.ASM) DO (
  %DOS2UNIX% -n -k -f %%F %FREHD%\%%F
)
cd ..\utils
for %%F in (*.ASM) DO (
  %DOS2UNIX% -n -k -f %%F %FREHD%\%%F
)
cd ..\other
for %%F in (*.ASM *.CCC *.DAT *.FIX *.JCL *.TXT) DO (
  %DOS2UNIX% -n -k -f %%F %FREHD%\%%F
)
copy *.CMD %FREHD%
cd ..\tools
for %%F in (*.ASM *.CCC *.DAT *.FIX *.JCL *.TXT) DO (
  %DOS2UNIX% -n -k -f %%F %FREHD%\%%F
)
copy *.CMD %FREHD%
