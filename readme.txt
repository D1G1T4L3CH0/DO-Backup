DO Backup
Description: Creates backups of Darkout save data. It can be set to create backups at an interval. If set to do that, just leave the script running while you play the game.
This should work on Windows XP and above.

In the following, references to the "script file" or just the "script" are relating to "dobackup.cmd".

- Setup
	In order to use this there are a few things you will need to do first.
	The most important thing to do is set the darkout path. If you do not, the script will not run a backup. You set it inside the script file. More help on this is provided in the script file.
	
	To edit the script file, open the file with any text editor and the settings you can change are below where it says BEGIN USER EDIT and above where it says END USER EDIT. Just read the information in comments (commands are preceded by ::) about each option, and then you can change the settings by editing the content after the equals sign.

- Compression
	Compression will help reduce the size of the backups. It's a good option to save space, but it can slow your game down if compression is set too high.
	If you would like your backups to be compressed, download the command line version of 7-Zip and place the file, "7za.exe" in the directory along with this file and the script file "dobackup.cmd". The script will automatically find the file there and use it. If it's not found, the script will only copy the files.
	You can set the compression level of the backups in the script file. More help on this is provided in the script file.

	7-Zip Command Line Version
	http://www.7-zip.org/download.html

- Backup Intervals
	You may set a backup interval in the script in order to tell the script you want it to backup every x seconds. If you set it to 0 (zero seconds) the script will only run a backup once, and then quit. More help on this is provided in the script file.

- Low Priority Mode
	Running in low priority gives the game and other software that's running, more priority for system usage. Use it if the backups slow the game down. If you would prefer to run backups in low priority mode, run "low-priority.cmd" instead of "dobackup.cmd".

- What to backup
	You can set in the script, what you would like to backup. It can be one of or any combination of the following; Worlds, Characters, Config. More help on this is provided in the script file.

- Where Do The Backups Get Saved?
	They are saved in a sub-directory named "backups" in the directory this file is in.

- KNOWN ISSUES
	* The script does not clean out old files from the backups. If you have removed some worlds/characters, or if you have change from using compression or not, some old backups may continue to exists. You can easily just delete the backups directory any time you wish to clean it out. Then just run the script again to create a new set of backups.
