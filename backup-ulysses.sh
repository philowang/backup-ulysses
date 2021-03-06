#!/bin/zsh -f
# Purpose: Make extra Ulysses backups because you're paranoid. No I'm not. Yes you are. Ok, yeah, that's fair.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-03-09


	# this is the directory where backup files will be moved _to_ after they are created
	# You will almost certainly want to change this 
ARCHIVE_DIR='/Volumes/Data/Backups/Ulysses/'

## If you want to just move the backup to your Dropbox folder,
## just uncomment the next line and set it to the proper path 

# ARCHIVE_DIR=/path/to/Dropbox/Backups/Ulysses/


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#  	if 'dropbox_uploader.sh' exists, use it to upload a copy to 
# 	a folder in Dropbox. In my case the folder name is
#
# 		~/Dropbox/NoSync/Ulysses-Backups/
#
# 	but for dropbox_uploader.sh we just need the '/NoSync/Ulysses-Backups/' part 

DROPBOX_DIR='/NoSync/Ulysses-Backups/'




####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		You should not need to change anything below this line, 
#		although you are welcome to if you know what you are doing.
#
####|####|####|####|####|####|####|####|####|####|####|####|####|####|####


# short name of this file without path or extension 
NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/datetime

TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

LOG="$HOME/Library/Logs/$NAME.log"

function msg {

	echo "$NAME: $@" | tee -a "$LOG"

	if (( $+commands[po.sh] ))
	then

		po.sh "$NAME: $@"

	fi
}


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
# make sure the folder that we want to backup actually exists 
#

cd "$HOME/Library/Containers"

if [ ! -d "com.soulmen.ulysses3" ]
then
		msg "No com.soulmen.ulysses3 found in $PWD"
		exit 0
fi



####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
# This is where we actually create the backup of the folder
# 
# The filename will be something like this:
#
# 	com.soulmen.ulysses3.2016-03-09--16.52.51.tar.xz
#
# for March 9th at 4:52pm 

if (( $+commands[xz] ))
then

	ARCHIVE="com.soulmen.ulysses3.`timestamp`.tar.xz"

	tar \
		--options='xz:compression-level=9' \
		--xz \
		--verbose \
		-c \
		-f "$ARCHIVE" \
		"com.soulmen.ulysses3"

else

	ARCHIVE="com.soulmen.ulysses3.`timestamp`.tar.bz2"
	
	tar \
		--verbose \
		-y \
		-c \
		-f "$ARCHIVE" \
		"com.soulmen.ulysses3"

fi


EXIT="$?"

if [ "$EXIT" != "0" ]
then
	msg "tar failed (\$EXIT = $EXIT)"

	exit 0
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#  	if 'dropbox_uploader.sh' exists, use it to upload a copy to 
# 	a folder in Dropbox. 

if (( $+commands[dropbox_uploader.sh] ))
then

	dropbox_uploader.sh -s -p upload "$ARCHIVE" "$DROPBOX_DIR" 2>&1 | tee -a "$LOG"

	EXIT="$?"

	if [ "$EXIT" != "0" ]
	then
		msg "Failed to upload $ARCHIVE to Dropbox dir: $DROPBOX_DIR (EXIT = $EXIT)"
	fi
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#	Move the .tar.xz file to the 'ARCHIVE_DIR' defined above 
#

mv "$ARCHIVE" "$ARCHIVE_DIR" 2>&1 | tee -a "$LOG"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	msg "Saved $ARCHIVE to $ARCHIVE_DIR"
else
	msg "Created $ARCHIVE but failed to move it to $ARCHIVE_DIR"
fi



exit 0
#EOF
