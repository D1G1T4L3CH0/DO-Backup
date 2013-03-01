@echo off

:: ** START USER EDIT ** ::

:: What to backup. Choose here what you would like to backup.
:: [False: 0 | True: 1] Defaults are world=1, characters=1, config=0
set backup_world=1
set backup_characters=1
set backup_config=0

:: Mode
:: Set the operating mode of the script here.
:: 1: Normal, 2: Interval, 3: Auto
:: Normal: In this mode the script will only backup one time and then quit.
:: Interval: This mode will backup at a set interval.
:: Auto: This mode will automatically backup the saves when it detects a change in the save files. Example; when you save your game, the save files will have changed and therefore also initiate a backup.
set mode=3

:: Compression level. Settings are 1 through 9. 9 being the highest. Keep in mind, while it's compressing, CPU usage goes up and could cause your game to slow down.
:: This has no effect if 7za.exe is not found in the same directory as this script. Compression will not be used, the script will simply copy the files.
set compression_level=9

:: Set the backup interval in seconds. Default is 0 (disabled).
:: This will not save your game for you. You will still need to save your game while playing, at least as often as the interval is set for.
set backup_interval=300

:: Auto Backups
:: Automatic backups happen when the script detects some files (players or worlds) have changed. This means that when you choose "save your game" in game, you will also be initializing a backup at the same time. Of course the script will wait a set time before it backs up the files to give the game enough time to fully finish writing the save files. 
:: "backup_interval" above must be set to zero.
:: Auto Backup Check Interval
:: Set this to the time in seconds you want the script to check for changed files.
set ab_check_interval=10
:: Auto Backup Wait Time
:: Set this to the time in seconds you want to wait for the game to save the files before continuing with the backup. This should be set to longer than it takes the game to complete a save operation.
:: Do not save your game more often than this. If you do, the script may try to backup your saves while the game is writing data to them.
set ab_wait_time=60

:: Backup Limits (not implemented yet)
:: 1 = Don't save multiple copies. | 2 = Save multiple copies. backups will contain the time and date in the name.
set overwrite_backups=
:: If overwrite_backups is set to 1, this option is ignored. Limit the number of backups the script will keep. If the number of backups is more than this number, the oldest ones will be deleted first.
set num_backups=

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

if %mode% LEQ 0 call :mode_not_set
if %mode% EQU 1 call :backup
if %mode% EQU 2 goto interval_backup
if %mode% EQU 3 goto autobackup
if %mode% GEQ 4 call :mode_not_set

:: Go back to the previous directory.
popd
goto :EOF

:interval_backup
	title DO Backup - Interval Mode
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
goto :interval_backup

:autobackup
	title DO Backup - Auto Mode
	call :makehash
	set hash=%hash_now%
	:check_modified
		call :wait %ab_check_interval% "to check files for a change"
		call :makehash
		if  not "%hash%" EQU "%hash_now%" (
			echo Files changed.
			:: wait for game saving operation to complete.
			call :wait %ab_wait_time% "for game to finish saving"
			call :backup
			set hash=%hash_now%
		)
	goto check_modified

:makehash
	:: Make a sloppy hash of the file information for all the files in Players and Worlds. This probably isn't the best way, but it doesn't require any third party application.
	set hash_now=
	for %%X in ("%documents_path%\My Games\Darkout\Worlds\*") do set hash_now=%%~tzX!hash_now!
	for %%X in ("%documents_path%\My Games\Darkout\Players\*") do set hash_now=%%~tzX!hash_now!
goto :EOF

:wait
:: Wait for the check interval.
for /l %%x in (%1,-1,1) do (
	cls
	echo Waiting %%x seconds %~2...
	ping -n 1 -w 1000 1.1.1.1>nul
)
goto :EOF

:backup
	echo Backing up...
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

:mode_not_set
	cls
	echo You have not set the mode option correctly in the script. Please check.
	echo Press any key to close...
	pause>nul
goto :EOF

:cant_find_docs
	cls
	echo It appears the script is unable to locate your Documents directory. The script cannot run without it. Please contact me (D1G1T4L3CH0) d1g1t4l@boun.cr with the following information. Thanks!
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