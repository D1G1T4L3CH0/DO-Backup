@echo off

:: ** START USER EDIT ** ::

:: What to backup. Choose here what you would like to backup.
:: [False: 0 | True: 1] Defaults are world=1, characters=1, config=0
set backup_world=1
set backup_characters=1
set backup_config=1

:: Compression level. Settings are 1 through 9. 9 being the highest. Keep in mind, while it's compressing, CPU usage goes up and could cause your game to slow down.
:: This has no effect if 7za.exe is not found in the same directory as this script. Compression will not be used, the script will simply copy the files.
set compression_level=9

:: Set the backup interval in seconds. Default is 0 (disabled).
:: If set to 0 (zero seconds), backup will run only once when the script is run and then the script will exit. It will not backup again until the script is run again.
:: This will not save your game for you. You will still need to save your game while playing, at least as often as the interval is set for.
set backup_interval=0

:: ** END USER EDIT ** ::
:: ! DO NOT EDIT BELOW THIS LINE ! ::


:: Set the title.
title DO Backup
SETLOCAL ENABLEDELAYEDEXPANSION

:: Make sure the registry value exists.
REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal > nul
if "%ERRORLEVEL%" == "1" goto cant_find_docs
:: Get the registry value data. Put it into %documents_path%.
for /f "tokens=2* skip=2" %%x in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal') do set documents_path=%%y
:: For Windows prior to Vista.
:: Yes this is ugly. It just replaces %USERPROFILE% in the documents_path variable with the expanded variable of the same name.
set documents_path=!documents_path:%%USERPROFILE%%=%USERPROFILE%!
:: see if it exists.
if not exist "%documents_path%" goto cant_find_docs

:: Lets make sure we are in the script's directory.
pushd "%~dp0"
:: Make the backups subdirectory if it doesn't already exist.
if not exist backups mkdir backups
if not exist 7za.exe (
	:: Only create these directories if compression is not used.
	if not exist backups\characters mkdir backups\Worlds
	if not exist backups\config mkdir backups\Players
	:: Create text files to remind where to restore the files.
REM 	echo The .wrld files here should be restored to the root of the Darkout installation directory. Example: C:\Program files\Darkout > "backups\HOW TO RESTORE.TXT"
REM 	echo The files in the "characters" directory should be restored to the directory: %APPDATA%\ALLGRAF\DARKOUT\journalData >> "backups\HOW TO RESTORE.TXT"
REM 	echo The files in th "config" directory should be restored to the directory: %APPDATA%\ALLGRAF\DARKOUT\common >> "backups\HOW TO RESTORE.TXT"
) else (
	:: Create text files to remind where to restore the files.
REM 	echo The file "worlds.7z" should be extracted to the root of the Darkout installation directory. Example: C:\Program files\Darkout > "backups\HOW TO RESTORE.TXT"
REM 	echo The files "characters.7z" and "config.7z" should be extracted to the directory: %APPDATA%\ALLGRAF\DARKOUT >> "backups\HOW TO RESTORE.TXT"
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
if exist 7za.exe (
	:: Compress the backup if 7za.exe was found in the current directory.
	if %backup_world% EQU 1 7za a -mx%compression_level% -t7z -y backups\worlds.7z "%documents_path%\My Games\Darkout\Worlds\*"
	if %backup_characters% EQU 1 7za a -mx%compression_level% -t7z -y backups\players.7z "%documents_path%\My Games\Darkout\Players\*"
	if %backup_config% EQU 1 7za a -mx%compression_level% -t7z -y backups\config.7z "%documents_path%\My Games\Darkout\*.*"
) else (
	:: Just copy the files if compression is not wanted.
	if %backup_world% EQU 1 copy /y "%documents_path%\My Games\Darkout\Worlds\*" backups\Worlds
	if %backup_characters% EQU 1 copy /y "%documents_path%\My Games\Darkout\Players\*" backups\Players\
	if %backup_config% EQU 1 copy /y "%documents_path%\My Games\Darkout\*.*" backups\
)
goto :EOF

:cant_find_docs
cls
echo It appears the script is unable to locate your Documents directory. The script cannot run without it. Please contact d1g1t4l@boun.cr with the following information. Thanks!
echo.
echo Please send the information below to: d1g1t4l@boun.cr
ver
echo documents_path=%documents_path%
echo CD=%cd%
echo script=%0
echo.
echo Press any key to close...
pause>nul
goto :EOF