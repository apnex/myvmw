#!/bin/bash

SESSIONFILE='cookies.txt'
printf "Validating existing session...\n" 1>&2
if [ -f $SESSIONFILE ]; then
	MYDATE=$(stat -c %y cookies.txt)
	LAPSE="$(($(date '+%s') - $(date -d "$MYDATE" '+%s')))"
	printf "File [$SESSIONFILE] exists - age [$LAPSE]\n" 1>&2
	if [ "$LAPSE" -ge 600 ]; then
		printf "Session older than [600] seconds, reauthenticating...\n" 1>&2
		./drv.login.sh
	fi
else
	printf "File [$SESSIONFILE] does not exist - authenticating...\n" 1>&2
	./drv.login.sh
fi
