#!/bin/bash
# bsffc - Bash Script For File Compressing
#
# Author : Romain Barbarot
# https://github.com/Jocker666z/bsffc/
#
# licence : GNU GPL-2.0

# Version
VERSION=v0.02

# Paths
FCS_PATH="$( cd "$( dirname "$0" )" && pwd )"												# set fcs.sh path

# General variables
NPROC=$(nproc --all| awk '{ print $1 - 1 }')												# Set number of processor
TERM_WIDTH=$(stty size | awk '{print $2}' | awk '{ print $1 - 10 }')						# Get terminal width, and truncate
FINDDEPTH="10"

# Messages
MESS_SEPARATOR=" --------------------------------------------------------------"

SetGlobalVariables() {			# Construct file in loop
if test -n "$ARGUMENT"; then			# if argument
	LSTCOMPRESS=()
	LSTCOMPRESS+=("$ARGUMENT")
else									# if no argument
	mapfile -t LSTCOMPRESS < <(find . -maxdepth $FINDDEPTH -type f -regextype posix-egrep -iregex '.*\.('$FILE_EXT')$' 2>/dev/null | sort | sed 's/^..//')
fi

# Count file(s)
NBCOMPRESS="${#LSTCOMPRESS[@]}"
}
Usage() {
cat <<- EOF
fcs $VERSION - GNU GPL-2.0 Copyright - <https://github.com/Jocker666z/bsffc>

Usage: fcs [options]
  -a|--all                      Compress all file in current directory.
  -i|--input <file>             Compress one file.
  -i|--input <directory>        Compress one directory.
  -d|--depth <number>           Specify find depth level.
                                Default: $FINDDEPTH
  -e|--extension <ext1.ext2...> Compress all files with specific extension.
  -h|--help                     Display this help.
  -j|--jobs <number>            Number of file compressed in same time.
                                Default: $NPROC
  -t|--type <compression>       Compression type:
                                7z (7zip)
                                lz4 (tar.lz4)
                                xz (tar.xz)
                                zip
                                zstd (tar.zst)

EOF
}
Loading() {						# Loading animation
local CL="\e[2K"
local delay=0.10
local spinstr="▉▉░"
case $1 in
	start)
		while :
		do
			local temp=${spinstr#?}
			printf "${CL}$spinstr\r"
			local spinstr=$temp${spinstr%"$temp"}
			sleep $delay
			printf "\b\b\b\b\b\b"
		done
		printf "    \b\b\b\b"
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
		;;
	stop)
		kill $_sp_pid > /dev/null 2>&1
		#printf "${CL}✓ ${DisplayLoadingSourceSize}->${DisplayLoadingTargetSize} ${DisplayLoadingPercentage}%% ${msg}\n"
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
		;;
esac
}
StartLoading() {				# Start loading animation
tput civis		# hide cursor
Loading "start" &
# set global spinner pid
_sp_pid=$!
disown
}
StopLoading() {					# Stop loading animation
tput cnorm		# normal cursor
Loading "stop" $_sp_pid
unset _sp_pid
}
TrapStop() {					# Ctrl+z Trap for loop exit
stty -igncr						# Enable the enter key
kill -s SIGTERM $!
}
TrapExit() {					# Ctrl+c Trap for script exit
stty -igncr						# Enable the enter key
exit
}
RemoveSourceFiles() {			# Remove source files
read -p " Remove source files? [y/N]: " qrm
case "$qrm" in
	"Y"|"y")
		if [[ "$DIRECTORY" -eq 0 ]]; then		# If file
			for f in "${filesSourceInLoop[@]}"; do
				rm -f "$f" 2> /dev/null
			done
		else									# If directory
			for f in "${filesSourceInLoop[@]}"; do
				rm -R -f "$f" 2> /dev/null
			done
		fi
	;;
	*)
		SourceNotRemoved="1"
	;;
esac
}
RemoveTargetFiles() {			# Remove target files
if [ "$SourceNotRemoved" = "1" ] ; then
	read -p " Remove compressed files? [y/N]: " qrm
	case "$qrm" in
		"Y"|"y")
			for f in "${filesTargetInLoop[@]}"; do
				rm -f "$f" 2> /dev/null
			done
		;;
		*)
			exit
		;;
	esac
fi

}

CompressCmd7z() {				# 7zip cmd
SevenZip="1"
CompressCMD="7z a -y -bsp0 -bso0 -t7z -m0=lzma -mx=9 -mfb=258 -md=32m -ms=on -mmt=on"
}
CompressCmdlz4() {				# lz4 cmd
TAR="1"
CompressCMD="lz4 -9 -q -q"
}
CompressCmdXz() {				# xz cmd
TAR="1"
CompressCMD="xz -q -9 -k -e --threads=0"
}
CompressCmdZip() {				# zip cmd
ZIP="1"
CompressCMD="zip -q"
}
CompressCmdZstd() {				# lz4 cmd
TAR="1"
CompressCMD="zstd --ultra"
}
CompressRoutine() {			#
# Start time counter
START=$(date +%s)

# Message
echo
echo " bsffc processing $EXT compression ($CompressCMD)"
echo "$MESS_SEPARATOR"

# Compressing
stty igncr										# Disable the enter key
for files in "${LSTCOMPRESS[@]}"; do
	StartLoading "" ""
	# Source size
	DisplayLoadingSourceSize=$(du -cks "$files" | tail -n1 | awk '{print $1;}')
	# Target file name
	if [[ "$DIRECTORY" -eq 0 ]]; then			# If file
		fileTarget="${files%.*}.$EXT"
	else										# If directory
		fileTarget="${files%/}.$EXT"
	fi
	# Stock source/target file pass in loop
	filesSourceInLoop+=("$files")
	filesTargetInLoop+=("$fileTarget")
	(
		# Compression
		if [[ "$TAR" -eq 1 ]]; then				# If tar
			tar -cf - "$files" | eval "$CompressCMD" - > "$fileTarget"
		elif [[ "$SevenZip" -eq 1 ]]; then		# If 7z
			eval "$CompressCMD" '"$fileTarget"' '"$files"'
		elif [[ "$ZIP" -eq 1 ]]; then			# If zip
			if [[ "$DIRECTORY" -eq 0 ]]; then			# If file
				eval "$CompressCMD" '"$fileTarget"' '"$files"'
			else										# If directory
				eval "$CompressCMD" '"$fileTarget"' '"$files"'/*
			fi
		fi
		# Target size
		DisplayLoadingTargetSize=$(du -cks "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")
		StopLoading $?
		) &
		if [[ $(jobs -r -p | wc -l) -gt $NPROC ]]; then
			wait -n
		fi
done
wait
stty -igncr										# Enable the enter key

# End time counter
END=$(date +%s)
}

Report() {
# Make statistics of processed files
DIFFS=$(($END-$START))
NBSourceFiles="${#filesSourceInLoop[@]}"
NBTargetFiles="${#filesTargetInLoop[@]}"
SizeSourceFiles=$(du -chsm "${filesSourceInLoop[@]}" | tail -n1 | awk '{print $1;}')
SizeTargetFiles=$(du -chsm "${filesTargetInLoop[@]}" | tail -n1 | awk '{print $1;}')
SizePercentage=$(bc <<< "scale=2; ($SizeTargetFiles - $SizeSourceFiles)/$SizeSourceFiles * 100")

# Display report
echo "$MESS_SEPARATOR"
echo " $NBTargetFiles/$NBSourceFiles file(s) have been processed."
echo " Created file(s) size: $SizeTargetFiles MB, a difference of $SizePercentage% from the source(s) ($SizeSourceFiles MB)."
echo " End of processing: $(date +%D\ at\ %Hh%Mm), duration: $((DIFFS/3600))h$((DIFFS%3600/60))m$((DIFFS%60))s."
echo "$MESS_SEPARATOR"
echo
}

# Arguments variables
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
    -a|--all)																				# Compress all current files
		if [ -n "$InputFileDir" ] || [ -n "$FILE_EXT" ]; then
			echo
			echo "   -/!\- -a|--all option is not compatible with -i|--input & -e|--extension option."
			echo
			exit
		else
			unset FINDDEPTH																	# Unset default FINDDEPTH
			FINDDEPTH="1"
			FILE_EXT="*.*"
		fi
    ;;
    -i|--input)
		shift
		InputFileDir="$1"
		if [ -n "$FILE_EXT" ]; then															# If --extension no --input
			echo
			echo "   -/!\- Select -e|--extension or -i|--input option."
			echo
			exit
		elif [ -d "$InputFileDir" ]; then													# If target is directory
			DIRECTORY="1"
			ARGUMENT="$InputFileDir"
		elif [ -f "$InputFileDir" ]; then													# If target is file
			FILE="1"
			ARGUMENT="$InputFileDir"
		else
			echo
			echo "   -/!\- Missed, \"$1\" is not a file or directory."
			echo
			exit
		fi
    ;;
    -d|--depth)																				# File search depth
		shift
		if [ -n "$InputFileDir" ]; then
			echo
			echo "   -/!\- -d|--depth option is not compatible with -i|--input option."
			echo
			exit
		else
			if ! [[ "$1" =~ ^[0-9]+$ ]] ; then													# If not integer
				echo "   -/!\- Depth must be an integer."
				exit
			elif [[ "$1" -lt 1 ]] ; then														# If result inferior than 1
				echo "   -/!\- Depth must be greater than zero."
				exit
			else
				unset FINDDEPTH																	# Unset default FINDDEPTH
				FINDDEPTH="$1"
			fi
		fi
    ;;
    -e|--extension)																			# File extension 
		shift
		if [ -n "$InputFileDir" ]; then														# If --extension no --input
			echo
			echo "   -/!\- Select -e|--extension or -i|--input option."
			echo
			exit
		else
			FILE_EXT="${1//./|}"															# Subtitute . by |
		fi
    ;;
    -h|--help)																				# Help
		Usage
		exit
    ;;
    -j|--jobs)
		shift
		if ! [[ "$1" =~ ^[0-9]+$ ]] ; then													# If not integer
			echo "   -/!\- Number of job must be an integer."
			exit
		else
			unset NPROC																		# Unset default NPROC
			NPROC=$(( $1 - 1 ))																# Substraction
			if [[ "$NPROC" -lt 0 ]] ; then													# If result inferior than 0
				echo "   -/!\- Number of job must be greater than zero."
				exit
			fi
		fi
    ;;
    -t|--type)
		shift
		CompressType="$1"
    ;;
    *)
		Usage
		exit
    ;;
esac
shift
done

SetGlobalVariables
trap TrapExit 2 3							# Set Ctrl+c clean trap for exit all script
trap TrapStop 20							# Set Ctrl+z clean trap for exit current loop (for debug)

#
case "$CompressType" in
    7z)
		EXT=7z
		CompressCmd7z
		CompressRoutine
		Report
		RemoveSourceFiles
		RemoveTargetFiles
    ;;
    lz4)
		EXT=tar.lz4
		CompressCmdlz4
		CompressRoutine
		Report
		RemoveSourceFiles
		RemoveTargetFiles
    ;;
    xz)
		EXT=tar.xz
		CompressCmdXz
		CompressRoutine
		Report
		RemoveSourceFiles
		RemoveTargetFiles
    ;;
    zip)
		EXT=zip
		CompressCmdZip
		CompressRoutine
		Report
		RemoveSourceFiles
		RemoveTargetFiles
    ;;
    zstd)
		EXT=tar.zst
		CompressCmdZstd
		CompressRoutine
		Report
		RemoveSourceFiles
		RemoveTargetFiles
    ;;
    *)
		Usage
		exit
    ;;
esac

exit
