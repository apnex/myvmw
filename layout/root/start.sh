#!/bin/bash

asyncRun() {
    "$@" &
    pid="$!"
    trap "echo 'Stopping PID $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

    # A signal emitted while waiting will make the wait command return code > 128
    # Let's wrap it in a loop that doesn't end before the process is indeed stopped
    while kill -0 $pid > /dev/null 2>&1; do
        wait
    done
}

ITEM1=$1
ITEM2=$2
function none {
	asyncRun /root/main.pl
	#/root/main.pl
}

function get_product {
	asyncRun /root/main.pl "$ITEM1"
}

function get_file {
	if [ ! -z "$ITEM2" ]; then
		asyncRun /root/vmwFile.pm "$ITEM2"
	fi
}

function get_install {
	cat /root/install.sh
}

function get_help {
	/root/main.pl help
}

if [ -z "$1" ]
then
	none
else
	case $1 in
		install)
			get_install
		;;
		help)
			get_help
		;;
		get)
			get_file
		;;
		*)
			get_product
		;;
	esac
fi

