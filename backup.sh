#!/bin/bash

set -e

DEBUG=false

WIKIDIR="."
CFGFILE="LocalSettings.php"

REQVARS=("wgDBserver" "wgDBname" "wgDBuser" "wgDBpassword")
wgDBserver=""
wgDBname=""
wgDBuser=""
wgDBpassword=""

BACKUPDIR="~/mediawiki-backup"
VERSION=""

BACKUPMSG="This wiki is currently being backed-up. Please try it later."

ROTATENUM=14

usage() {
	echo
	echo "Usage $0 [-p] [-h]"
	echo "  -p [path] mediawiki installed path"
	echo "  -o [path] mediawiki backup files output path"
	echo "  -r [number] mediawiki backup rotate number"
	echo "  -d debug"
	echo "  -h show this screen"
	echo
}

function stopWiki() {
	echo "\$wgReadOnly = '$BACKUPMSG';" >> $WIKIDIR/$CFGFILE
}

function restartWiki() {
	sed -i "/$BACKUPMSG/d" $WIKIDIR/$CFGFILE
}

function getConfigVariables() {
	local cfgvars=$(sed -n -e 's/"\|\;//g' -e 's/ //g' -e '/^\$/p' $WIKIDIR/$CFGFILE)

	for var in $cfgvars; do
		local name=$(echo $var | awk -F'[=$]' '{print $2}')
		local value=$(echo $var | awk -F'[=$]' '{print $3}')

		for req in ${REQVARS[@]}; do
			if [ "$req" == "$name" ]; then
				declare $req=$value
			fi
		done
	done

	# Debug script
	if $DEBUG; then
		for req in ${REQVARS[@]}; do
			echo $req = ${!req}
		done
	fi
}

function timestamp() {
	date +"%Y-%m-%d_%T"
}

function makeBackupDir() {
	VERSION=$(timestamp)
	
	BACKUPDIR=$BACKUPDIR/$VERSION
	mkdir -p $BACKUPDIR
}

function dumpMysql() {
	mysqldump -h$wgDBserver -u$wgDBuser -p$wgDBpassword $wgDBname | gzip > $BACKUPDIR/sql.gz
}

function archiveWiki() {
	cd $WIKIDIR
	tar czf $BACKUPDIR/mediawiki.tar.gz .
	cd -
}

function rotateBackup() {
	local backups=($(ls -1 $BACKUPDIR))
	local delta=$((${#backups[@]} - ROTATENUM))

	if [ $delta -lt 1 ]; then
		return
	fi

	for i in $(eval echo "{1..$delta}"); do
		echo remove old backup: $BACKUPDIR/${backups[$i]}
		rm -rf $BACKUPDIR/${backups[$i]}
	done
}

function main() {
	# Rotate backups
	rotateBackup

	# Make wiki readonly.
	stopWiki

	# Get required config variables from mediawiki installed directory.
	getConfigVariables

	# Make backup directory.
	makeBackupDir

	# Dump mysql.
	dumpMysql

	# Archive wiki.
	archiveWiki

	# Make wiki writable.
	restartWiki
}

while getopts p:o:r:dh o; do
	case $o in
	d)
		DEBUG=true
		;;
	p)
		WIKIDIR=$OPTARG
		;;
	o)
		BACKUPDIR=$OPTARG
		;;
	r)
		ROTATENUM=$OPTARG
		;;
	h)
		usage
		exit 0
		;;
	?)
		usage
		exit 1
		;;
	esac
done

main
