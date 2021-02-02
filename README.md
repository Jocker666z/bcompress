# bcompress - Bash Script For File Compressing

Simple bash tool for file compressing at the highest ratio, with statistic report at end of job.

--------------------------------------------------------------------------------------------------
## Dependencies
`bzip2 gzip lrzip lz4 lzip p7zip-full tar xz-utils zpaq zip zstd`

if available use the binaries allowing parallelisation: `pbzip2 pigz plzip pxz`

## Install
`curl https://raw.githubusercontent.com/Jocker666z/bcompress/master/bcompress.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/bcompress`


## Use
```
Usage: bcompress options
  -a|--all                      Compress all file in current directory.
  -i|--input <file>             Compress one file.
  -i|--input <directory>        Compress one directory.
  -d|--depth <number>           Specify find depth level.
                                Default: $find_depth
  -e|--extension <ext1.ext2...> Compress all files with specific extension.
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
```

## Test
bcompress is tested, under Debian stable and unstable almost every day.
If you encounter problems or have proposals, I am open to discussion.

## Holy reading
* http://mattmahoney.net/dc/text.html#about
