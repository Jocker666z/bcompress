# Changelog
v0.04:
* add support of lzip
* add support of lrzip
* improve compression of zstd with -22 option
* improve compression of lz4, replace -9 by -c2
* replace pgz by pigz and improve compression with -11 option

v0.04:
* clean code & syntax
* add support of bzip2
* add support of zpaq
* add more precise/human readable report for smaller files, with byte, kbyte, mbyte calcul
* add default compression type, if no selection xz used
* now launch nothing if no selection with -i or -a

v0.03a:
* fix - readme

v0.03:
* add - support zstd compression
* fix - multi extention selection, replace option selection "|" by "."

v0.02:
* fix - --all option, remove shift
* fix - RemoveTargetFiles(), replace break by exit
* add - support 7zip, lz4, zip compression

v0.01:
* add - support one file, directory, all files in current directory, specific extension in directory tree, depth level choice 
* add - support tar.zx compression
