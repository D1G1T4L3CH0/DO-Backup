@echo off

:: ** START USER EDIT ** ::

:: Set the Darkout path here. Type the full path to where darkout.exe is located. Do not type the a filename at the end. Also do not leave a \ at the end.
:: Example: set darkout_path=C:\Program Files\Darkout
set darkout_path=D:\Capsule\CapsuleGames\Darkout - PC

:: What to backup. Choose here what you would like to backup.
:: [False: 0 | True: 1] Defaults are world=1, characters=1, config=0
set backup_world=1
set backup_characters=1
set backup_config=0

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
if not exist 7za.exe (
	:: Only create these directories if compression is not used.
	if not exist backups\characters mkdir backups\characters
	if not exist backups\config mkdir backups\config
	:: Create text files to remind where to restore the files.
	echo The .wrld files here should be restored to the root of the Darkout installation directory. Example: C:\Program files\Darkout > "backups\HOW TO RESTORE.TXT"
	echo The files in the "characters" directory should be restored to the directory: %APPDATA%\ALLGRAF\DARKOUT\journalData >> "backups\HOW TO RESTORE.TXT"
	echo The files in th "config" directory should be restored to the directory: %APPDATA%\ALLGRAF\DARKOUT\common >> "backups\HOW TO RESTORE.TXT"
) else (
	:: If compression is to be used, we do not need those directories.
	:: Create text files to remind where to restore the files.
	echo The file "worlds.7z" should be extracted to the root of the Darkout installation directory. Example: C:\Program files\Darkout > "backups\HOW TO RESTORE.TXT"
	echo The files "characters.7z" and "config.7z" should be extracted to the directory: %APPDATA%\ALLGRAF\DARKOUT >> "backups\HOW TO RESTORE.TXT"
)

:: If there is an interval specified, do a backup and then sleep for the interval. If not, just do one backup then quit.
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
	:: This is the sleep command. It's using PING for compatibility with Windows XP/2000 as they don't have the TIMEWAIT command.
	ping 1.1.1.1 -n 1 -w %backup_interval%000 > nul
	goto :loop
) else (
	call :backup
)

:: Go back to the previous directory.
popd
goto :EOF

:backup
:: Config
::%APPDATA%\ALLGRAF\DARKOUT\common
:: Character Data
::%APPDATA%\ALLGRAF\DARKOUT\journalData
if exist 7za.exe (
	:: Compress the backup if 7za.exe was found in the current directory.
	if %backup_world% EQU 1 7za a -mx%compression_level% -t7z -y backups\worlds.7z "%darkout_path%\*.wrld"
	if %backup_characters% EQU 1 7za a -mx%compression_level% -t7z -y backups\characters.7z "%APPDATA%\ALLGRAF\DARKOUT\journalData"
	if %backup_config% EQU 1 7za a -mx%compression_level% -t7z -y backups\config.7z "%APPDATA%\ALLGRAF\DARKOUT\common"
) else (
	:: Just copy the files if compression is not wanted.
	if %backup_world% EQU 1 copy /y "%darkout_path%\*.wrld" backups
	if %backup_characters% EQU 1 copy /y "%APPDATA%\ALLGRAF\DARKOUT\journalData" backups\characters\
	if %backup_config% EQU 1 copy /y "%APPDATA%\ALLGRAF\DARKOUT\common" backups\config\
)
