@echo off

:: ** START USER EDIT ** ::

:: Set the Darkout path here. Type the full path to where darkout.exe is located. Do not type the a filename at the end. Also do not leave a \ at the end.
:: Example: set darkout_path=C:\Program Files\Darkout
set darkout_path=D:\Capsule\CapsuleGames\Darkout - PC

:: Compression level. Settings are 1 through 9. 9 being the highest. Keep in mind, while it's compressing, CPU usage goes up and could cause your game to slow down.
:: This has no effect if 7za.exe is not found in the same directory as this script. Compression will not be used, the script will simply copy the files.
set compression_level=9

:: Set the backup interval in seconds. Default is 0 (disabled).
:: If set to 0 (zero seconds), backup will run only once when the script is run and then the script will exit. It will not backup again until the script is run again.
set backup_interval=0

:: ** END USER EDIT ** ::
:: ! DO NOT EDIT BELOW THIS LINE ! ::


:: Set the title.
title DO Backup

:: Check the darkout path variable.
if "%darkout_path%" == "" (
	:: Variable not set.
	echo Please set the darkout path in this script first.
	echo.
	echo Press any key to cancel...
	pause>nul
	goto :EOF
) else (
	if not exist "%darkout_path%\darkout.exe" (
		:: darkout.exe not found.
		echo The script cannot locate darkout.exe at the specified location:
		echo "%darkout_path%"
		echo.
		echo Press any key to cancel...
		pause>nul
		goto :EOF
	)
)

:: Lets make sure we are in the script's directory.
pushd "%~dp0"
:: Make the backups subdirectory if it doesn't already exist.
if not exist backups mkdir backups

if %backup_interval% GTR 0 (
	:loop
	cls
	echo Backing up now... Do not stop this during the backup!
	title DO Backup ^(DO NOT CLOSE RIGHT NOW!^)
	call :backup
	echo Backup complete.
	echo Waiting for interval of %backup_interval% seconds...
	echo You may stop this now by closing this window.
	title DO Backup ^(Waiting. Interval: %backup_interval% seconds^)
	ping 1.1.1.1 -n 1 -w %backup_interval%000 > nul
	goto :loop
) else (
	call :backup
)

:: Go back to the previous directory.
popd
pause
goto :EOF

:backup
if exist 7za.exe (
	:: Compress the backup if 7za.exe was found in the current directory.
	7za a -mx%compression_level% -t7z -y backups\worlds.7z "%darkout_path%\*.wrld"
) else (
	:: Just copy the files if compression is not wanted.
	copy /y "%darkout_path%\*.wrld" backups
)
