# bsffc - Bash Script For File Compressing

Simple bash tool for file compressing, with statistic report at end of job.

--------------------------------------------------------------------------------------------------
## Dependencies
`tar lz4 p7zip-full xz-utils zip zstd`

## Install
* `cd && wget https://github.com/Jocker666z/bsffc/archive/master.zip`
* `unzip master.zip && mv bsffc-master ffmes && rm master.zip`
* `cd bsffc && chmod a+x bsffc.sh`
* `echo "alias bsffc=\"bash ~/bsffc/bsffc.sh\"" >> ~/.bash_aliases && source ~/.bash_aliases` (alias optional but recommended & handy)


## Use
Options:

Usage: fcs [options]
* -a|--all                      Compress all file in current directory.
* -i|--input <file>             Compress one file.
* -i|--input <directory>        Compress one directory.
* -d|--depth <number>           Specify find depth level. Default: 10
* -e|--extension <ext1.ext2...> Compress all files with specific extension.
* -h|--help                     Display this help.
* -j|--jobs <number>            Number of file compressed in same time. Default: (Number of processor - 1)
* -t|--type <compression>       Compression type: 7z (7zip), lz4 (tar.lz4), xz (tar.xz), zip, zstd (tar.zst)

## Test
bsffc is tested, under Debian stable and unstable almost every day.
If you encounter problems or have proposals, I am open to discussion.
