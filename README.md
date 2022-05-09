# bcompress

Simple bash tool for file compressing at the highest ratio, with statistic report at end of job.

--------------------------------------------------------------------------------------------------
## Dependencies
`bzip2 gzip lrzip lz4 lzip p7zip-full tar xz-utils zpaq zip zstd`

## Install
`curl https://raw.githubusercontent.com/Jocker666z/bcompress/master/bcompress.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/bcompress`


## Use
```
Usage: 
   bcompress options <file> or <dir>
   or
   bcompress options -e <ext1.ext2...>
Options:
  -a|--all                      Compress all files in current.
  -ad|--all                     Compress all directory in current.
  -i|--input <file> or <dir>    Compress one file or directory.
  -d|--depth <number>           Specify find depth level.
                                Default: 10
  -e|--extension <ext1.ext2...> Compress all files in depth with specific extension.
  -h|--help                     Display this help.
  -j|--jobs <number>            Number of file compressed in same time.
                                Default: processor number
  -t|--type <compression>       Compression type:
                                7zip (7z)
                                bzip2 (tar.bz2)
                                gzip (tar.gz)
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
* http://mattmahoney.net/dc/text.html
