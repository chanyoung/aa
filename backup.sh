#!/bin/bash

set -e

DEBUG=false

WIKIDIR="."
CFGFILE="LocalSettings.php"

REQVARS=("wgDBname" "wgDBuser" "wgDBpassword")
wgDBname=""
wgDBuser=""
wgDBpassword=""

usage() {
	echo
	echo "Usage $0 [-p] [-h]"
	echo "  -p [path] mediawiki installed path"
	echo "  -d debug"
	echo "  -h show this screen"
	echo
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

function main() {
	getConfigVariables
}

while getopts p:dh o; do
	case $o in
	d)
		DEBUG=true
		;;
	p)
		WIKIDIR=$OPTARG
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
