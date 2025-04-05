@echo off
setlocal enabledelayedexpansion
:menu
echo.
echo *** M E N U ***
for /F "delims=" %%L in ( farmenu.ini ) do (
	set L=%%L
	if "!L:~0,3!" == "--:" (
		echo ===[ !L:~5! ]===
	) else if not "!L:~0,1!" == " " (
		echo !L!
	)
)
set C=
set /P C="Choice: "
if "%C%" == "" goto :eof
set OK=N
for /F "delims=" %%L in ( farmenu.ini ) do (
	set L=%%L
	if not "!L:~0,1!" == " " (
		if /I "!L:~0,2!" == "%C%:" (
			set OK=Y
		) else (
			set OK=N
		)
	) else (
		if "!OK!" == "Y" (
			echo !L!
			call !L!
			@echo off
		)
	)

)
goto :menu
