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
set mode=1

:: Compression. Keep in mind, while it's compressing, CPU usage goes up and could cause your game to slow down. A lower compression level can help this.
:: This has no effect if 7za.exe is not found in the same directory as this script. Compression will not be used, the script will simply copy the files.
:: Set to 1 to enable compression or 0 to disable it.
set compression=1
:: Compression Level. Valid values: 0, 1, 3, 5, 7, 9
:: A value of 0 is copy mode and does not compress at all. 9 is the highest compression level. Looks at http://www.dotnetperls.com/7-zip-examples for more information.
set c_level=1
:: Archive Type. Valid values: 7z, gzip, zip, bzip2, tar, iso, udf
set c_archive_type=7z

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
set ab_wait_time=30

:: Backup Limits
:: Limit the number of backups the script will keep. If the number of backups is more than or equal to this number, the oldest ones will be deleted first.
:: Set to 1 if you don't want multiple backups.
set num_backups=5

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
set darkout_saves_path=%documents_path%\My Games\Darkout
if not exist "%documents_path%\My Games\Darkout" goto cant_find_darkout_saves
set backups_path=%documents_path%\My Games\Darkout\backups

:: Lets make sure we are in the script's directory.
pushd "%~dp0"

:: Make the backups subdirectory if it doesn't already exist.
if not exist "%backups_path%" mkdir "%backups_path%"

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
	for %%X in ("%darkout_saves_path%\Worlds\*") do set hash_now=%%~tzX!hash_now!
	for %%X in ("%darkout_saves_path%\Players\*") do set hash_now=%%~tzX!hash_now!
goto :EOF

:make_timestamp
	for /f "tokens=1-3 delims=:." %%a in ("%time%") do set t=%%a.%%b.%%c
	for /f "tokens=2-4 delims=/ " %%a in ("%date%") do set d=%%c-%%a-%%b
	if "%t:~0,1%" EQU " " set t=%t: =0%
	set timestamp=%d%_%t%
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
	call :backup_limit_cleanup
	call :make_timestamp
	mkdir "%backups_path%\%timestamp%"
	set c_parms_front=a -mx%c_level% -t%c_archive_type% -y "%backups_path%\%timestamp%
	echo Backing up...
	if not exist 7za.exe set compression=0
	if %compression% EQU 1 (
		:: Compress the backup if 7za.exe was found in the current directory.
		if %backup_world% EQU 1 (
			7za %c_parms_front%\worlds.%c_archive_type%" "%darkout_saves_path%\Worlds\*" )
		if %backup_characters% EQU 1 (
			7za %c_parms_front%\players.%c_archive_type%" "%darkout_saves_path%\Players\*" )
		if %backup_config% EQU 1 (
			7za %c_parms_front%\config.%c_archive_type%" "%darkout_saves_path%\*.*" )
	) else (
		if not exist "%backups_path%\%timestamp%\Worlds" mkdir "%backups_path%\%timestamp%\Worlds"
		if not exist "%backups_path%\%timestamp%\Players" mkdir "%backups_path%\%timestamp%\Players"
		:: Just copy the files.
		if %backup_world% EQU 1 copy /y "%darkout_saves_path%\Worlds\*" "%backups_path%\%timestamp%\Worlds\"
		if %backup_characters% EQU 1 copy /y "%darkout_saves_path%\Players\*" "%backups_path%\%timestamp%\Players\"
		if %backup_config% EQU 1 copy /y "%darkout_saves_path%\*.*" "%backups_path%\%timestamp%\"
	)
goto :EOF

:backup_limit_cleanup
	set cur_num_backups=0
	:: Count the number of directories (backups).
	for /d %%x in ("%backups_path%\*") do set /a cur_num_backups+=1
	
	if %cur_num_backups% GEQ %num_backups% (
		:: Set the number of backups to be deleted.
		set /a del_num=cur_num_backups-num_backups+1
		:: Delete the backups, oldest first.
		for /d %%x in ("%backups_path%\*") do (
			set /a del_num-=1
			rmdir /q /s "%%x">nul
			if !del_num! EQU 0 goto :EOF
		)
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

:cant_find_darkout_saves
	cls
	echo It appears the script is unable to locate your Darkout Saves directory. The script cannot run without it. This could be that you haven't run the game yet, or there is some other problem, not related to the script. However there is a small chance it's related to the script and if you believe that's the case, please contact me (D1G1T4L3CH0) d1g1t4l@boun.cr with the following information. Thanks!
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