# bcompress

Simple bash tool for file compressing at the highest ratio, with statistic report at end of job.

--------------------------------------------------------------------------------------------------
## Dependencies
`tar lz4 p7zip-full xz-utils zip zstd`

## Install
`curl https://raw.githubusercontent.com/Jocker666z/bcompress/master/bcompress.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/bcompress`


## Use
Options:

Usage: bcompress [options]
* -a|--all                      Compress all file in current directory.
* -i|--input <file>             Compress one file.
* -i|--input <directory>        Compress one directory.
* -d|--depth <number>           Specify find depth level. Default: 10
* -e|--extension <ext1.ext2...> Compress all files with specific extension.
* -h|--help                     Display this help.
* -j|--jobs <number>            Number of file compressed in same time. Default: (Number of processor - 1)
* -t|--type <compression>       Compression type: 7z (7zip), lz4 (tar.lz4), xz (tar.xz), zip, zstd (tar.zst)

## Test
bcompress is tested, under Debian stable and unstable almost every day.
If you encounter problems or have proposals, I am open to discussion.

## Holy reading
* http://mattmahoney.net/dc/text.html#about
