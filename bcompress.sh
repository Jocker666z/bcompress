#!/bin/bash
# shellcheck disable=SC2086
# bcompress - Simple bash tool for file compressing at the highest ratio
#
# Author : Romain Barbarot
# https://github.com/Jocker666z/bcompress/
#
# licence : GNU GPL-2.0

# General variables
nproc=$(nproc --all)											# Set number of processor
find_depth="10"													# Default find depth
CompressType="7zip"

# Messages
message_separator=" --------------------------------------------------------------"

SetGlobalVariables() {					# Construct file array
if test -n "$ARGUMENT"; then			# if argument
	lst_compress=()
	lst_compress+=("$ARGUMENT")
elif [[ "$find_dir" = "1" ]]; then
	mapfile -t lst_compress < <(find . -maxdepth $find_depth \
								-type d 2>/dev/null \
								| sort | sed 's/^..//' | tail -n +2)
else
	mapfile -t lst_compress < <(find . -maxdepth $find_depth \
								-type f -regextype posix-egrep -iregex '.*\.('$FILE_EXT')$' 2>/dev/null \
								| sort | sed 's/^..//')
fi
}
Usage() {
cat <<- EOF
bcompress - GNU GPL-2.0 Copyright - <https://github.com/Jocker666z/bcompress>

Usage: 
   bcompress [options] <file> or <dir>
   or
   bcompress [options] -e <ext1.ext2...>
Options:
  -a|--all                      Compress all files in current.
  -ad|--all                     Compress all directory in current.
  -i|--input <file> or <dir>    Compress one file or directory.
  -d|--depth <number>           Specify find depth level.
                                Default: $find_depth
  -e|--extension <ext1.ext2...> Compress all files in depth with specific extension.
  -h|--help                     Display this help.
  -j|--jobs <number>            Number of file compressed in same time.
                                Default: $nproc
  -t|--type <compression>       Compression type:
                                7zip (7z) (default)
                                bzip2 (tar.bz2)
                                gzip (tar.gz)
                                lz4 (tar.lz4)
                                lzip (tar.lz)
                                xz (tar.xz)
                                zip
                                zpaq
                                zstd (tar.zst)

EOF
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
read -r -p " Remove source files? [y/N]: " qrm
case "$qrm" in
	"Y"|"y")
		for f in "${filesSourceInLoop[@]}"; do
			if [ -d "$f" ]; then
				rm -R -f "$f" 2> /dev/null
			else
				rm -f "$f" 2> /dev/null
			fi
		done
	;;
	*)
		SourceNotRemoved="1"
	;;
esac
}
RemoveTargetFiles() {			# Remove target files
if [ "$SourceNotRemoved" = "1" ] ; then
	read -r -p " Remove compressed files? [y/N]: " qrm
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
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		7z a -y -bsp0 -bso0 -t7z -mx=9 -mfb=273 -ms -md=31 -myx=9 -mtm=- -mmt -mmtf -md=1536m -mmf=bt3 -mmc=10000 -mpb=0 -mlc=0 \
			"$fileTarget" "$files"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "7z it's not installed. Aborting."
	exit
fi
}
CompressCmdbz2() {				# bz2 cmd
if hash bzip2 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | bzip2 -9 -q > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "bzip2 it's not installed. Aborting."
	exit
fi
}
CompressCmdgzip() {				# gzip cmd
if hash gzip 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | gzip -9 -q > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "gzip it's not installed. Aborting."
	exit
fi
}
CompressCmdlz4() {				# lz4 cmd
if hash lz4 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | lz4 -c2 -q -q > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "lz4 it's not installed. Aborting."
	exit
fi
}
CompressCmdlzip() {				# lzip cmd
if hash lzip 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | lzip -9 -s512MiB -q > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "lzip it's not installed. Aborting."
	exit
fi
}
CompressCmdXz() {				# xz cmd
if hash xz 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | xz -q -9 -k -e --threads=0 > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "xz it's not installed. Aborting."
	exit
fi
}
CompressCmdZip() {				# zip cmd
if hash zip 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		if [[ -d "$files" ]]; then
			zip -q "$fileTarget" "$files"/*
		else
			zip -q "$fileTarget" "$files"
		fi

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "zip it's not installed. Aborting."
	exit
fi

			#if [[ "$DIRECTORY" -eq 0 ]]; then									# If file
				#eval "$CompressCMD" '"$fileTarget"' '"$files"'
			#else																# If directory
				#eval "$CompressCMD" '"$fileTarget"' '"$files"'/*
			#fi

}
CompressCmdZpaq() {				# zpaq cmd
if hash zpaq 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		zpaq -m4 a "$fileTarget" "$files" &>/dev/null

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
else
	echo "zpaq it's not installed. Aborting."
	exit
fi
}
CompressCmdZstd() {				# lz4 cmd
if hash zstd 2>/dev/null; then
	if [[ -s "$files" ]] || [[ -d "$files" ]]; then
		# Source size
		DisplayLoadingSourceSize=$(du -cbs "$files" | tail -n1 | awk '{print $1;}')

		# Compress
		tar -cf - "$files" | zstd --ultra -22 -q > "$fileTarget"

		# Target size
		DisplayLoadingTargetSize=$(du -cbs "$fileTarget" | tail -n1 | awk '{print $1;}')
		DisplayLoadingPercentage=$(bc <<< "scale=2; ($DisplayLoadingTargetSize - $DisplayLoadingSourceSize)/$DisplayLoadingSourceSize * 100")

		# Add + if no - or 0
		if [[ "$DisplayLoadingPercentage" != -* ]] && [[ "$DisplayLoadingPercentage" != 0* ]]; then
			DisplayLoadingPercentage="+$DisplayLoadingPercentage"
		fi
		printf '%-2s %-7s %-80.80s\n' "✓" "$DisplayLoadingPercentage"% "$fileTarget"
	fi
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
echo " bcompress processing $EXT compression"
echo "$message_separator"

# Disable the enter key
stty igncr

# Compressing
for files in "${lst_compress[@]}"; do
	# Target file name
	# If file
	if ! [[ -d "$files" ]]; then
		fileTarget="${files%.*}.$EXT"
	# If directory
	else
		fileTarget="${files%/}.$EXT"
	fi
	# Stock target file pass in loop
	filesTargetInLoop+=("$fileTarget")
	# Stock source file pass in loop
	filesSourceInLoop+=("$files")

	# Compression
	if ! [[ -s "$fileTarget" ]]; then
		(
		# 7zip
		if [[ "$EXT" = "7z" ]]; then
			CompressCmd7z
		# bzip2
		elif [[ "$EXT" = "tar.bz2" ]]; then
			CompressCmdbz2
		# gzip
		elif [[ "$EXT" = "tar.gz" ]]; then
			CompressCmdgzip
		# lz4
		elif [[ "$EXT" = "tar.lz4" ]]; then
			CompressCmdlz4
		# lzip
		elif [[ "$EXT" = "tar.lz" ]]; then
			CompressCmdlzip
		# xz
		elif [[ "$EXT" = "tar.xz" ]]; then
			CompressCmdXz
		# zip
		elif [[ "$EXT" = "zip" ]]; then
			CompressCmdZip
		# zpaq
		elif [[ "$EXT" = "zpaq" ]]; then
			CompressCmdZpaq
		# zstd
		elif [[ "$EXT" = "tar.zst" ]]; then
			CompressCmdZstd
		fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nproc ]]; then
			wait -n
		fi
	fi

done
wait

# Enable the enter key
stty -igncr

# End time counter
END=$(date +%s)
}
Report() {
if (( "${#filesSourceInLoop[@]}" )); then
	# Local variables
	local DIFFS
	local NBSourceFiles
	local NBTargetFiles
	local SizeSourceFiles
	local SizeTargetFiles
	local SizePercentage
	local size_unit
	
	# Make statistics of processed files
	DIFFS=$(( END-START ))
	NBSourceFiles="${#filesSourceInLoop[@]}"
	NBTargetFiles="${#filesTargetInLoop[@]}"
	SizeSourceFiles=$(du -chsb "${filesSourceInLoop[@]}" | tail -n1 | awk '{print $1;}')
	SizeTargetFiles=$(du -chsb "${filesTargetInLoop[@]}" | tail -n1 | awk '{print $1;}')
	SizePercentage=$(bc <<< "scale=2; ($SizeTargetFiles - $SizeSourceFiles)/$SizeSourceFiles * 100")

	# Add + if no - or 0
	if [[ "$SizePercentage" != -* ]] && [[ "$SizePercentage" != 0* ]]; then
		SizePercentage="+$SizePercentage"
	fi

	# Make human readable size
	# Byte display 1b -> 1kb
	if [ "$SizeTargetFiles" -ge 1 ] && [ "$SizeTargetFiles" -le 1024 ]; then
		size_unit="B"
	# Kbyte display 1kb -> 10mb
	elif [ "$SizeTargetFiles" -ge 1025 ] && [ "$SizeTargetFiles" -le 10485760 ]; then
		size_unit="kB"
		SizeSourceFiles=$(( SizeSourceFiles / 1024 ))
		SizeTargetFiles=$(( SizeTargetFiles / 1024 ))
	# Mbyte display 10 mb ->
	elif [ "$SizeTargetFiles" -ge 10485761 ]; then
		size_unit="MB"
		SizeSourceFiles=$(( SizeSourceFiles / 1024 / 1024 ))
		SizeTargetFiles=$(( SizeTargetFiles / 1024 / 1024 ))
	fi

	# Display report
	echo "$message_separator"
	echo " $NBTargetFiles/$NBSourceFiles file(s) have been processed."
	echo " Created file(s) size: $SizeTargetFiles $size_unit, a difference of $SizePercentage% from the source(s) ($SizeSourceFiles $size_unit)."
	echo " End of processing: $(date +%D\ at\ %Hh%Mm), duration: $((DIFFS/3600))h$((DIFFS%3600/60))m$((DIFFS%60))s."
	echo "$message_separator"
	echo
else
	# Display report
	echo " No file to be processed"
	echo "$message_separator"
	echo
	exit
fi
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
			find_depth="1"
			FILE_EXT="*.*"
		fi
    ;;
    -ad|--all_dir)																				# Compress all dir
		if [ -n "$InputFileDir" ] || [ -n "$FILE_EXT" ]; then
			echo
			echo "   -/!\- -a|--all option is not compatible with -i|--input & -e|--extension option."
			echo
			exit
		else
			find_depth="1"
			find_dir="1"
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
			#DIRECTORY="1"
			ARGUMENT="$InputFileDir"
		elif [ -f "$InputFileDir" ]; then													# If target is file
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
			unset nproc																# Unset default nproc
			nproc=$(( $1 - 1 ))														# Substraction
			if [[ "$nproc" -lt 0 ]] ; then												# If result inferior than 0
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

# Populate Array with sources
SetGlobalVariables
# Trap = Ctrl+c clean trap for exit all script
trap TrapExit SIGINT SIGQUIT
# Trap = Ctrl+z clean trap for exit current loop (for debug)
trap TrapStop SIGTSTP
# Tar bin test
TarTest

# Launch nothing if no selection with -i, -a or -ad
if (( "${#lst_compress[@]}" )); then
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
