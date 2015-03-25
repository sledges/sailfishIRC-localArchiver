#!/bin/bash

# Author	:	starkDbl07
# Date		:	2015-03-25
# Purpose	:	Download plaintext of not-yet-downloaded sailfish-irc logs 'http://www.merproject.org/logs/%23sailfishos-porters'

archive_dir="archive"
temp_dir="temp"
pastebin_dir="pastebin"

mkdir -p "$temp_dir"
mkdir -p "$archive_dir"
mkdir -p "$pastebin_dir"

function getArchiveForDate {
	date="$1"
	#curl -s "http://www.merproject.org/logs/%23sailfishos-porters/%23sailfishos-porters.$date.log.html" | grep 'class="nick"' | sed -e 's^<tr id="t\([^"]*\)"><[^>]*>\([^<]*\)</th><td[^>]*>\(.*\)^\1  \2    \3^; s^</td><[^<]*><[^<]*>[^>]*</a></td></tr>$^^' > $archive_dir/$date.txt
	curl -s "http://www.merproject.org/logs/%23sailfishos-porters/%23sailfishos-porters.$date.log" > $archive_dir/$date.txt
}

function getIndexes {
	curl -s "http://www.merproject.org/logs/%23sailfishos-porters/index.html" | grep '</li>' | sed -n '2,$p'| awk -F'>' '{print $3}' | awk '{print $1}' | sort -n
}


function genPastebinLinks {
	grep '<a href="http://pastebin' "$1" | sed 's~^\([^\ *]*\)\ .*<a href="\(http://pastebin.[^"]*\).*~\1 \2~g' | awk -F'/' '{print $1"//"$3"/raw.php?i="$4" "$4}'
}

function downloadPastebinLink {
	params=( `echo $1` )
	file="$pastebin_dir/${params[0]}_${params[2]}"
	link="${params[1]}"
	#echo "$file:$link"
	if [ ! -e "$file" ]
	then
		curl -s -o "$file" "$link"
		if [ -e "$file" ]
		then
			echo -e "- ${params[2]}"
		fi
	fi
}

function genAllPastebinsLinks {
	for archive in `ls $archive_dir/`
	do
		genPastebinLinks "$archive_dir/$archive"
	done 
}

function getAllPastebins {
	: > $temp_dir/pastebins
	echo "Extracting Pastebin Links from chat archive..."
	genAllPastebinsLinks | sort | uniq | grep -v '^$' > $temp_dir/pastebins
	echo "Fetching pastebins..."
	while read link
	do
		#echo "$link"
		downloadPastebinLink "$link"
	done < $temp_dir/pastebins
}

function updateIRC {
	echo "Getting Date Indexes..."
	getIndexes > $temp_dir/indexes

	echo "Fetching Archive as text..."
	count=0
	while read index
	do 
		if [ ! -e "$archive_dir/$index.txt" ]
		then
			let count=count+1
			echo -e "\t - $index"
			getArchiveForDate $index
		fi
	done < $temp_dir/indexes

	if [ $count -eq 0 ]
	then
		echo ""
		echo "No newer archive found."
		echo ""
	fi
}

function usage {
	echo "Usage: $0 irc/pastebin"
	echo ""
	echo "$0 irc"
	echo -e "\t - Update local IRC archive"
	echo "$0 pastebins"
	echo -e "\t - Update local pastebin archive"
	exit 0
}

if [ "$1" == "pastebins" ]
then
	getAllPastebins
elif [ "$1" == "irc" ]
then
	updateIRC
else
	usage	
fi
