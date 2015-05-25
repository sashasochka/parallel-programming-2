gnatmake -d -PE:\Dropbox\pp\lab6\lab6.gpr lab6.adb
gnatbind -x E:\Dropbox\pp\lab6\lab6.ali
gnatlink E:\Dropbox\pp\lab6\lab6.ali -Xlinker --stack=0x10000000 -o E:\Dropbox\pp\lab6\lab6.exe