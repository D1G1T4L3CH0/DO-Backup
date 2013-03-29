DO Backup
Description: Creates backups of Darkout save data. It can be set to create backups at an interval. If set to do that, just leave the script running while you play the game.
This should work on Windows XP and above.

In the following, references to the "script" are relating to "dobackup.cmd".
In the following, references to the "config file" are relating to "config.ini".

- Setup
	In order to use this there are a few things you will need to do first.
	To edit the config file, open the file with any text editor. Just read the information in comments (commands are preceded by ::) about each option, and then you can change the settings by editing the content after the equals sign.

- Compression
	Compression will help reduce the size of the backups. It's a good option to save space, but it can slow your game down if compression is set too high.
	If you would like your backups to be compressed, download the command line version of 7-Zip and place the file, "7za.exe" in the directory along with this file and the config file "dobackup.cmd". The script will automatically find the file there and use it. If it's not found, the script will only copy the files.
	You can set the compression level of the backups in the config file. More help on this is provided in the config file.

	7-Zip Command Line Version
	http://www.7-zip.org/download.html

- Backup Intervals
	You may set a backup interval in the config file in order to tell the script you want it to backup every x seconds. If you set it to 0 (zero seconds) the script will only run a backup once, and then quit. Using intervals doesn't save your game for you though. You will still need to save your game while playing, at least as often as the interval is set for. More help on this is provided in the config file.

- Low Priority Mode
	Running in low priority gives the game and other software that's running, more priority for system usage. Use it if the backups slow the game down. If you would prefer to run backups in low priority mode, run "low-priority.cmd" instead of "dobackup.cmd".

- What to backup
	You can set in the config file, what you would like to backup. It can be one of or any combination of the following; Worlds, Characters, Config. More help on this is provided in the config file.

- Where Do The Backups Get Saved?
	They are saved in a sub-directory named "backups" in the darkout saves directory.
