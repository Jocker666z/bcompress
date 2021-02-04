#!/bin/bash
# bcompress - Simple bash tool for file compressing at the highest ratio
#
# Author : Romain Barbarot
# https://github.com/Jocker666z/bcompress/
#
# licence : GNU GPL-2.0

# General variables
bcompress_version="0.06"
nprocessor=$(nproc --all)																	# Set number of processor
find_depth="10"																				# Default find depth
CompressType="xz"

# Messages
message_separator=" --------------------------------------------------------------"

SetGlobalVariables() {			# Construct file array
if test -n "$ARGUMENT"; then			# if argument
	lst_compress=()
	lst_compress+=("$ARGUMENT")
else									# if no argument
	mapfile -t lst_compress < <(find . -maxdepth $find_depth -type f -regextype posix-egrep -iregex '.*\.('$FILE_EXT')$' 2>/dev/null | sort | sed 's/^..//')
fi
}
Usage() {
cat <<- EOF
bcompress $bcompress_version - GNU GPL-2.0 Copyright - <https://github.com/Jocker666z/bcompress>

Usage: 
   bcompress [options] <file> or <dir>
   or
   bcompress [options] -e <ext1.ext2...>
Options:
  -a|--all                      Compress all file in current directory.
  -i|--input <file> or <dir>    Compress one file or directory.
  -d|--depth <number>           Specify find depth level.
                                Default: $find_depth
  -e|--extension <ext1.ext2...> Compress all files in depth with specific extension.
  -h|--help                     Display this help.
  -j|--jobs <number>            Number of file compressed in same time.
                                Default: $nprocessor
  -t|--type <compression>       Compression type:
                                7zip (7z)
                                bzip2 (tar.bz2)
                                gzip (tar.gz)
                                lrzip (lzr)
                                lz4 (tar.lz4)
                                lzip (tar.lz)
                                xz (tar.xz) (default)
                                zip
                                zpaq
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
TarTest() {						# Test tar installed
hash tar 2>/dev/null || { echo >&2 "tar it's not installed. Aborting."; exit; }
}

CompressCmd7z() {				# 7zip cmd
if hash 7z 2>/dev/null; then
	CompressCMD="7z a -y -bsp0 -bso0 -t7z -mx=9 -mfb=273 -ms -md=31 -myx=9 -mtm=- -mmt -mmtf -md=1536m -mmf=bt3 -mmc=10000 -mpb=0 -mlc=0"
else
	echo "7z it's not installed. Aborting."
	exit
fi
}
CompressCmdbz2() {				# bz2 cmd
TAR="1"
if hash pbzip2 2>/dev/null; then
	CompressCMD="pbzip2 -9 -q"
elif hash bzip2 2>/dev/null; then
	CompressCMD="bzip2 -9 -q"
else
	echo "bzip2 it's not installed. Aborting."
	exit
fi
}
CompressCmdgzip() {				# gzip cmd
TAR="1"
if hash pbzip2 2>/dev/null; then
	CompressCMD="pigz -11 -q"
elif hash bzip2 2>/dev/null; then
	CompressCMD="gzip -9 -q"
else
	echo "gzip it's not installed. Aborting."
	exit
fi
}
CompressCmdlrzip() {			# lrzip cmd
if hash lrzip 2>/dev/null; then
	if [[ "$DIRECTORY" -eq 0 ]]; then			# If file
		CompressCMD="lrzip -f -q -z -L 9 -p 1"
	else
		EXT="tar.lrz"
		CompressCMD="lrztar -f -q -z -L 9 -p 1"
	fi
else
	echo "lrzip it's not installed. Aborting."
	exit
fi
}
CompressCmdlz4() {				# lz4 cmd
TAR="1"
if hash lz4 2>/dev/null; then
	CompressCMD="lz4 -c2 -q -q"
else
	echo "lz4 it's not installed. Aborting."
	exit
fi
}
CompressCmdlzip() {				# lzip cmd
TAR="1"
if hash plzip 2>/dev/null; then
	CompressCMD="plzip -9 -s512MiB -q"
elif hash lzip 2>/dev/null; then
	CompressCMD="lzip -9 -s512MiB -q"
else
	echo "lzip it's not installed. Aborting."
	exit
fi
}
CompressCmdXz() {				# xz cmd
TAR="1"
if hash xz 2>/dev/null; then
	CompressCMD="xz -q -9 -k -e --threads=0"
else
	echo "xz it's not installed. Aborting."
	exit
fi
}
CompressCmdZip() {				# zip cmd
if hash zip 2>/dev/null; then
	CompressCMD="zip -q"
else
	echo "zip it's not installed. Aborting."
	exit
fi
}
CompressCmdZpaq() {				# zpaq cmd
if hash zpaq 2>/dev/null; then
	CompressCMD="zpaq -m5 a"
else
	echo "zpaq it's not installed. Aborting."
	exit
fi
}
CompressCmdZstd() {				# lz4 cmd
TAR="1"
if hash zstd 2>/dev/null; then
	CompressCMD="zstd --ultra -22 -q"
else
	echo "zstd it's not installed. Aborting."
	exit
fi
}

CompressRoutine() {				# Master compress loop
# Start time counter
START=$(date +%s)

# Message
echo
echo " bsffc processing $EXT compression ($CompressCMD)"
echo "$message_separator"

# Compressing
stty igncr										# Disable the enter key
for files in "${lst_compress[@]}"; do
	StartLoading "" ""
	# Source size
	DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')
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
		if [[ "$TAR" -eq 1 ]]; then												# If tar.gz, bz2, lz4, xz
			tar -cf - "$files" | eval "$CompressCMD" > "$fileTarget"

		elif [[ "$EXT" = "7z" ]]; then											# If 7z
			eval "$CompressCMD" '"$fileTarget"' '"$files"'

		elif [[ "$EXT" == *"lrz" ]]; then										# If lrzip
			if [[ "$DIRECTORY" -eq 0 ]]; then			# If file
				eval "$CompressCMD" '"$files"' -o '"$fileTarget"'
			else										# If directory
				eval "$CompressCMD" '"$files"'
			fi

		elif [[ "$EXT" = "zpaq" ]]; then										# If zpaq
				eval "$CompressCMD" '"$fileTarget"' '"$files"' &>/dev/null

		elif [[ "$EXT" = "zip" ]]; then											# If zip
			if [[ "$DIRECTORY" -eq 0 ]]; then									# If file
				eval "$CompressCMD" '"$fileTarget"' '"$files"'
			else																# If directory
				eval "$CompressCMD" '"$fileTarget"' '"$files"'/*
			fi
		fi

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")
		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		StopLoading $?
		) &
		if [[ $(jobs -r -p | wc -l) -gt $nprocessor ]]; then
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
local NBSourceFiles="${#filesSourceInLoop[@]}"
local NBTargetFiles="${#filesTargetInLoop[@]}"
local SizeSourceFiles=$(du -chsb "${filesSourceInLoop[@]}" | tail -n1 | awk '{print $1;}')
local SizeTargetFiles=$(du -chsb "${filesTargetInLoop[@]}" | tail -n1 | awk '{print $1;}')
local SizePercentage=$(bc <<< "scale=2; ($SizeTargetFiles - $SizeSourceFiles)/$SizeSourceFiles * 100")

# Add + if no - or 0
if [[ "$SizePercentage" != -* ]] && [[ "$SizePercentage" != 0* ]]; then
	local SizePercentage="+$SizePercentage"
fi

# Make human readable size
if [ "$SizeTargetFiles" -ge 1 ] && [ "$SizeTargetFiles" -le 1024 ]; then				# Byte display 1b -> 1kb
	local size_unit="B"
elif [ "$SizeTargetFiles" -ge 1025 ] && [ "$SizeTargetFiles" -le 10485760 ]; then		# Kbyte display 1kb -> 10mb
	local size_unit="kB"
	local SizeSourceFiles=$(( SizeSourceFiles / 1024 ))
	local SizeTargetFiles=$(( SizeTargetFiles / 1024 ))
elif [ "$SizeTargetFiles" -ge 10485761 ]; then											# Mbyte display 10 mb ->
	local size_unit="MB"
	local SizeSourceFiles=$(( SizeSourceFiles / 1024 / 1024 ))
	local SizeTargetFiles=$(( SizeTargetFiles / 1024 / 1024 ))
fi

# Display report
echo "$message_separator"
echo " $NBTargetFiles/$NBSourceFiles file(s) have been processed."
echo " Created file(s) size: $SizeTargetFiles $size_unit, a difference of $SizePercentage% from the source(s) ($SizeSourceFiles $size_unit)."
echo " End of processing: $(date +%D\ at\ %Hh%Mm), duration: $((DIFFS/3600))h$((DIFFS%3600/60))m$((DIFFS%60))s."
echo "$message_separator"
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
			unset find_depth																# Unset default find_depth
			find_depth="1"
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
			if ! [[ "$1" =~ ^[0-9]+$ ]] ; then												# If not integer
				echo "   -/!\- Depth must be an integer."
				exit
			elif [[ "$1" -lt 1 ]] ; then													# If result inferior than 1
				echo "   -/!\- Depth must be greater than zero."
				exit
			else
				unset find_depth															# Unset default find_depth
				find_depth="$1"
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
			unset nprocessor																# Unset default nprocessor
			nprocessor=$(( $1 - 1 ))														# Substraction
			if [[ "$nprocessor" -lt 0 ]] ; then												# If result inferior than 0
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
TarTest

#
if (( "${#lst_compress[@]}" )); then		# Launch nothing if no selection with -i or -a
	case "$CompressType" in
		7zip)
			EXT=7z
			CompressCmd7z
		;;
		bzip2)
			EXT=tar.bz2
			CompressCmdbz2
		;;
		gzip)
			EXT=tar.gz
			CompressCmdgzip
		;;
		lrzip)
			EXT=lrz
			CompressCmdlrzip
		;;
		lz4)
			EXT=tar.lz4
			CompressCmdlz4
		;;
		lzip)
			EXT=tar.lz
			CompressCmdlzip
		;;
		xz)
			EXT=tar.xz
			CompressCmdXz
		;;
		zip)
			EXT=zip
			CompressCmdZip
		;;
		zpaq)
			EXT=zpaq
			CompressCmdZpaq
		;;
		zstd)
			EXT=tar.zst
			CompressCmdZstd
		;;
		*)
			Usage
			exit
		;;
	esac

	CompressRoutine
	Report
	RemoveSourceFiles
	RemoveTargetFiles

else
	Usage
fi

exit
