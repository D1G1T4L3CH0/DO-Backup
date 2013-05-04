@echo off
:: Set the title.
title DO Backup
SETLOCAL ENABLEDELAYEDEXPANSION

:: Load the config file.
set config_file=%~dp0config.ini
if not exist "%config_file%" goto no_config_found
for /f "usebackq tokens=1,2 delims==" %%x in ("%config_file%") do (
	set option=%%x
	set !option!=%%y
)

:: TODO:
:: - Need to do some checks here to make sure the config was edited properly.

:: KNOWN ISSUES
:: - c_level is not checked to see if it's within acceptable range for the specific archive
::   application being used. Maybe there needs to be separate variables for the different
::   applications.

:: Ask for mode if it was set to 0.
if %mode% EQU 0 (
	echo Mode was set to interactive. Please choose. 1=Normal, 2=Interval, 3=Auto
	set /p mode=Mode? ^(1, 2, 3^): 
)

call :get_mydocs
if %ERRORLEVEL% EQU 1 goto cant_find_docs
if %ERRORLEVEL% EQU 2 goto cant_find_darkout_saves

:: Lets make sure we are in the script's directory.
pushd "%~dp0"

:: Make the backups subdirectory if it doesn't already exist.
if not exist "%backups_path%" mkdir "%backups_path%"

:: set archive application to use
if %compression% EQU 1 (
	call :is_installed_sevenzip
	call :is_installed_winrar
	if exist "7za.exe" set archive_application=1
) else (
	set compression=0
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
	for %%x in ("%darkout_saves_path%\Worlds") do set hash_now=%%~tzx
	for %%x in ("%darkout_saves_path%\Players") do set hash_now=%%~tzx!hash_now!
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
	if not "%num_backups%" EQU "*" call :backup_limit_cleanup

	call :make_timestamp
	mkdir "%backups_path%\%timestamp%"
	set c_parms_front=a -mx%c_level% -t%c_archive_type% -y "%backups_path%\%timestamp%

	echo Backing up...
::	if not exist 7za.exe set compression=0
	if %compression% EQU 1 (
		:: Archive the backup if 7za.exe was found in the current directory.
		call :archive
	) else (
		:: Just copy the files.
		call :cp
	)
goto :EOF

:cp
	if not exist "%backups_path%\%timestamp%\Worlds" mkdir "%backups_path%\%timestamp%\Worlds"
	if not exist "%backups_path%\%timestamp%\Players" mkdir "%backups_path%\%timestamp%\Players"
	if %backup_world% EQU 1 copy /y "%darkout_saves_path%\Worlds\*" "%backups_path%\%timestamp%\Worlds\"
	if %backup_characters% EQU 1 copy /y "%darkout_saves_path%\Players\*" "%backups_path%\%timestamp%\Players\"
	if %backup_config% EQU 1 copy /y "%darkout_saves_path%\*.*" "%backups_path%\%timestamp%\"
goto :EOF

:archive
	if %archive_application% EQU 1 (
		if %backup_world% EQU 1 (
			7za %c_parms_front%\worlds.%c_archive_type%" "%darkout_saves_path%\Worlds\*" )
		if %backup_characters% EQU 1 (
			7za %c_parms_front%\players.%c_archive_type%" "%darkout_saves_path%\Players\*" )
		if %backup_config% EQU 1 (
			7za %c_parms_front%\config.%c_archive_type%" "%darkout_saves_path%\*.*" )
	)
	if %archive_application% EQU 2 (
		set "path=%path%;%sevenzip_install_path%"
		if %backup_world% EQU 1 (
			7z %c_parms_front%\worlds.%c_archive_type%" "%darkout_saves_path%\Worlds\*" )
		if %backup_characters% EQU 1 (
			7z %c_parms_front%\players.%c_archive_type%" "%darkout_saves_path%\Players\*" )
		if %backup_config% EQU 1 (
			7z %c_parms_front%\config.%c_archive_type%" "%darkout_saves_path%\*.*" )
	)
	if %archive_application% EQU 3 (
		set "path=%path%;%winrar_install_path%"
		if %backup_world% EQU 1 (
			rar a -m%c_level% -s -ep "%backups_path%\%timestamp%\worlds.rar" "%darkout_saves_path%\Worlds\*")
		if %backup_characters% EQU 1 (
			rar a -m%c_level% -s -ep "%backups_path%\%timestamp%\players.rar" "%darkout_saves_path%\Players\*")
		if %backup_config% EQU 1 (
			rar a -m%c_level% -s -ep "%backups_path%\%timestamp%\config.rar" "%darkout_saves_path%\*.*")
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

:get_mydocs
	:: Make sure the registry value exists.
	REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal > nul
	if "%ERRORLEVEL%" == "1" exit /b 1
	:: Get the registry value data. Put it into %documents_path%.
	for /f "tokens=2* skip=2" %%x in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal') do set documents_path=%%y
	:: For Windows prior to Vista.
	:: Yes this is ugly. It just replaces %USERPROFILE% in the documents_path variable with the expanded variable of the same name.
	set documents_path=!documents_path:%%USERPROFILE%%=%USERPROFILE%!
	:: see if it exists.
	if not exist "%documents_path%" exit /b 1
	set darkout_saves_path=%documents_path%\My Games\Darkout
	if not exist "%documents_path%\My Games\Darkout" exit /b 2
	set backups_path=%documents_path%\My Games\Darkout\backups
goto :EOF

:is_installed_sevenzip
	set sevenzip_install_path=
	for /f "tokens=1,2*" %%x in ('reg query HKLM\Software\7-Zip /v path 2^>nul') do (
		if /i "%%x" EQU "path" if exist "%%z\7z.exe" set sevenzip_install_path=%%z
	)
	if "%sevenzip_install_path%" EQU "" (
		for /f "tokens=1,2*" %%x in ('reg query HKCU\Software\7-Zip /v path 2^>nul') do (
			if /i "%%x" EQU "path" if exist "%%z\7z.exe" set sevenzip_install_path=%%z
		)
	)
	if "%sevenzip_install_path%" EQU "" goto :EOF
	set archive_application=2
goto :EOF

:is_installed_winrar
	set winrar_install_path=
	for /f "tokens=1,2*" %%x in ('reg query HKLM\Software\WinRAR /v exe32 2^>nul') do (
		if /i "%%x" EQU "exe32" if exist "%%~dpz\rar.exe" set winrar_install_path=%%~dpz
	)
	if "%winrar_install_path%" EQU "" goto :EOF
	set archive_application=3
goto :EOF

:no_config_found
	echo No configuration file was found. It should have come in the archive along with the script. The script needs this file to know all of the options. the filename is: config.ini
	echo Please move the file next to the script and run again.
	echo.
	echo Press any key to exit...
	pause>nul
goto :EOF

:mode_not_set
	cls
	echo You have not set the mode option correctly in the script. Please check.
	echo Press any key to close...
	pause>nul
goto :EOF

:cant_find_docs
	cls
	echo It appears the script is unable to locate your Documents directory. The script cannot run without it. A file names "error.log" has been created in the script directory located at:
	echo %~dp0
	echo.
	echo Please contact me (D1G1T4L3CH0) d1g1t4l@boun.cr with the error.log file. Thanks!
	ver> error.log
	echo documents_path=%documents_path%>> error.log
	echo CD=%cd%>> error.log
	echo script=%0>> error.log
	echo Press any key to close...
	pause>nul
goto :EOF

:cant_find_darkout_saves
	cls
	echo It appears the script is unable to locate your Darkout Saves directory. The script cannot run without it. This could be that you haven't run the game yet, or there is some other problem, not related to the script. A file names "error.log" has been created in the script directory located at:
	echo %~dp0
	echo.
	echo Please contact me (D1G1T4L3CH0) d1g1t4l@boun.cr with the error.log file. Thanks!
	ver> error.log
	echo documents_path=%documents_path%>> error.log
	echo CD=%cd%>> error.log
	echo script=%0>> error.log
	echo Press any key to close...
	pause>nul
goto :EOF